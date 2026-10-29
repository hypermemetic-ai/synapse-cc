{-# LANGUAGE OverloadedStrings #-}

-- | synapse.lock — project-level lockfile for reproducible builds.
-- Committed to git; makes backend changes visible as a diff.
module SynapseCC.Lock
  ( SynapseLock(..), LockTarget(..)
  , readSynapseLock, writeSynapseLock
  , lookupLockTarget, synapseLockPath
  , emptySynapseLock
  ) where

import Control.Applicative ((<|>))
import Data.Aeson (FromJSON, ToJSON, eitherDecodeFileStrict)
import qualified Data.Aeson as Aeson
import qualified Data.Aeson.Encode.Pretty as Pretty
import qualified Data.ByteString.Lazy as BL
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Text (Text)
import qualified Data.Text as T
import System.Directory (doesFileExist)

import SynapseCC.Types (synapseCCVersion)

-- | Standard lock file name (lives next to synapse.config.json in CWD)
synapseLockPath :: FilePath
synapseLockPath = "synapse.lock"

-- ============================================================================
-- Types
-- ============================================================================

-- | Per-target entry in synapse.lock, keyed by outputDir
data LockTarget = LockTarget
  { ltBackend         :: !Text
  , ltIrHash          :: !Text
  , ltTransport       :: !Text
  , ltFiles           :: !(Map Text Text)  -- ^ relPath → content hash
  , ltSharedTransport :: !(Maybe Text)     -- ^ Name of provider target (if transport is shared)
  } deriving (Show, Eq)

instance FromJSON LockTarget where
  parseJSON = Aeson.withObject "LockTarget" $ \o -> LockTarget
    <$> o Aeson..: "backend"
    <*> o Aeson..: "irHash"
    <*> o Aeson..: "transport"
    <*> o Aeson..: "files"
    <*> o Aeson..:? "sharedTransport"

instance ToJSON LockTarget where
  toJSON lt = Aeson.object $
    [ "backend"   Aeson..= ltBackend lt
    , "irHash"    Aeson..= ltIrHash lt
    , "transport" Aeson..= ltTransport lt
    , "files"     Aeson..= ltFiles lt
    ] ++ case ltSharedTransport lt of
           Nothing -> []
           Just st -> ["sharedTransport" Aeson..= st]

-- | Top-level synapse.lock structure
data SynapseLock = SynapseLock
  { slVersion    :: !Text
  , slSynapseCC  :: !Text
  , slServiceCodegen :: !Text
  , slUpdatedAt  :: !Text
  , slTargets    :: !(Map Text LockTarget)  -- ^ outputDir → LockTarget
  } deriving (Show, Eq)

instance FromJSON SynapseLock where
  parseJSON = Aeson.withObject "SynapseLock" $ \o -> SynapseLock
    <$> o Aeson..: "version"
    <*> o Aeson..: "synapseCC"
    <*> (o Aeson..: "serviceCodegen" <|> o Aeson..: "hubCodegen") -- naming-alias: a lock written before NAMING-10 reads
    <*> o Aeson..: "updatedAt"
    <*> o Aeson..: "targets"

instance ToJSON SynapseLock where
  toJSON sl = Aeson.object
    [ "version"    Aeson..= slVersion sl
    , "synapseCC"  Aeson..= slSynapseCC sl
    , "serviceCodegen" Aeson..= slServiceCodegen sl
    , "updatedAt"  Aeson..= slUpdatedAt sl
    , "targets"    Aeson..= slTargets sl
    ]

-- | Empty lock, used as a base when creating a fresh synapse.lock
emptySynapseLock :: SynapseLock
emptySynapseLock = SynapseLock
  { slVersion    = "1"
  , slSynapseCC  = synapseCCVersion
  , slServiceCodegen = ""
  , slUpdatedAt  = ""
  , slTargets    = Map.empty
  }

-- ============================================================================
-- Pretty-print config
-- ============================================================================

lockPrettyConfig :: Pretty.Config
lockPrettyConfig = Pretty.defConfig
  { Pretty.confCompare = Pretty.keyOrder
      [ "version", "synapseCC", "serviceCodegen", "updatedAt", "targets"
      , "backend", "irHash", "transport", "files", "sharedTransport"
      ]
  }

-- ============================================================================
-- Read / Write
-- ============================================================================

-- | Read synapse.lock from CWD. Returns Nothing on missing or parse error.
readSynapseLock :: IO (Maybe SynapseLock)
readSynapseLock = do
  exists <- doesFileExist synapseLockPath
  if not exists
    then pure Nothing
    else do
      result <- eitherDecodeFileStrict synapseLockPath
      case result of
        Left  _ -> pure Nothing
        Right sl -> pure (Just sl)

-- | Write synapse.lock to CWD (pretty-printed JSON).
writeSynapseLock :: SynapseLock -> IO ()
writeSynapseLock sl =
  BL.writeFile synapseLockPath (Pretty.encodePretty' lockPrettyConfig sl)

-- | Look up the LockTarget for a given outputDir.
lookupLockTarget :: FilePath -> SynapseLock -> Maybe LockTarget
lookupLockTarget outputDir sl =
  Map.lookup (T.pack outputDir) (slTargets sl)
