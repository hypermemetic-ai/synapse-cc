-- | NAMING-10: a Plexus backend is a service (owner, 2026-10-29), and the code
-- generator is service-codegen. The gate fails on any remnant of the old word;
-- the rest holds the old spellings to "read, never written" for one release:
-- the lock key, the generator's output key, the cache's toolchain key, the
-- binary's name in discovery and the CLI flag. Hermetic: no backend, no
-- network; a fixture PATH, HOME and working directory.
module Main (main) where

import Control.Exception (bracket)
import qualified Data.Aeson as Aeson
import qualified Data.ByteString.Lazy.Char8 as LBS8
import Data.List (isInfixOf)
import Data.Maybe (isJust)
import qualified Data.Text as T
import Options.Applicative (defaultPrefs, execParserPure, getParseResult)
import System.Directory
import System.Environment (lookupEnv, setEnv, unsetEnv)
import System.Exit (ExitCode (..))
import System.FilePath ((</>))
import System.IO.Temp (withSystemTempDirectory)
import System.Process (readProcessWithExitCode)
import Test.Hspec

import SynapseCC.CLI (deprecatedFlagNotes, synapseCCParserInfo)
import SynapseCC.Discover (findServiceCodegen, oldCodegenName, serviceCodegenName, toolPathToFilePath)
import SynapseCC.Lock (SynapseLock (..), readSynapseLock, synapseLockPath, writeSynapseLock)
import SynapseCC.Types

oldLockKey, oldOutputKey, oldToolchainKey :: String
oldLockKey = "hubCodegen" -- naming-alias: synapse.lock's key before NAMING-10
oldOutputKey = "hubCodegenVersion" -- naming-alias: the generator's output key before NAMING-10
oldToolchainKey = "tvHubCodegen" -- naming-alias: the cache manifest's key before NAMING-10

main :: IO ()
main = hspec $ do
  describe "the naming gate" $
    it "scripts/naming-gate.sh finds no remnant of the old word" $ do
      (code, out, err) <- readProcessWithExitCode "bash" ["scripts/naming-gate.sh"] ""
      (code, out <> err) `shouldBe` (ExitSuccess, "")

  describe "synapse.lock" $ do
    let lockWith key = "{\"version\":\"1\",\"synapseCC\":\"0.3.5\",\"" <> key
          <> "\":\"0.5.0\",\"updatedAt\":\"2026-10-29T00:00:00Z\",\"targets\":{}}"
    it "a lock written with the old key reads, and is written back with the new key only" $
      inTempDir $ do
        writeFile synapseLockPath (lockWith oldLockKey)
        Just lock <- readSynapseLock
        slServiceCodegen lock `shouldBe` "0.5.0"
        writeSynapseLock lock
        written <- readFile synapseLockPath
        written `shouldSatisfy` ("\"serviceCodegen\"" `isInfixOf`)
        written `shouldNotSatisfy` (oldLockKey `isInfixOf`)
    it "a lock with the new key reads" $
      inTempDir $ do
        writeFile synapseLockPath (lockWith "serviceCodegen")
        fmap slServiceCodegen <$> readSynapseLock `shouldReturn` Just "0.5.0"

  describe "the generator's JSON" $ do
    let output key = LBS8.pack $ "{\"files\":{},\"fileHashes\":{},\"warnings\":[],\"" <> key
          <> "\":\"0.5.1\",\"dependencies\":{},\"devDependencies\":{}}"
    it "reads serviceCodegenVersion" $
      fmap coServiceCodegenVersion (Aeson.decode (output "serviceCodegenVersion")) `shouldBe` Just "0.5.1"
    it "reads the old output key from a generator before 0.5.1" $
      fmap coServiceCodegenVersion (Aeson.decode (output oldOutputKey)) `shouldBe` Just "0.5.1"
    it "a cache manifest's toolchain under the old key reads, and is written under the new" $ do
      let old = LBS8.pack $ "{\"tvSynapseCC\":\"0.3.5\",\"tvSynapse\":\"3.16.0\",\"" <> oldToolchainKey
            <> "\":\"0.5.0\",\"tvPlexusCore\":null}"
      Just tv <- pure (Aeson.decode old)
      tvServiceCodegen tv `shouldBe` Just "0.5.0"
      let back = LBS8.unpack (Aeson.encode tv)
      back `shouldSatisfy` ("\"tvServiceCodegen\":\"0.5.0\"" `isInfixOf`)
      back `shouldNotSatisfy` (oldToolchainKey `isInfixOf`)

  describe "discovery" $ do
    it "with both names on PATH, finds service-codegen" $
      withFixturePath [serviceCodegenName, oldCodegenName] $ \bin -> do
        Just (path, note) <- findServiceCodegen False
        toolPathToFilePath path `shouldBe` bin </> serviceCodegenName
        note `shouldBe` Nothing
    it "with only the old name on PATH, finds it and says the name is deprecated" $
      withFixturePath [oldCodegenName] $ \bin -> do
        Just (path, note) <- findServiceCodegen False
        toolPathToFilePath path `shouldBe` bin </> oldCodegenName
        note `shouldSatisfy` maybe False (T.isInfixOf "deprecated")
    it "with neither, finds nothing" $
      withFixturePath [] $ \_ -> findServiceCodegen False >>= (`shouldSatisfy` not . isJust)

  describe "the CLI" $ do
    let parse = getParseResult . execParserPure defaultPrefs synapseCCParserInfo
    it "--service-codegen PATH sets the generator's path" $
      fmap (optServiceCodegenPath . cfgOptions) (parse ["typescript", "menger", "--service-codegen", "/x/sc"])
        `shouldBe` Just (Just "/x/sc")
    it "the old flag still works, and is noted as deprecated" $ do
      let args = ["typescript", "menger", "--" <> oldCodegenName, "/x/old"]
      fmap (optServiceCodegenPath . cfgOptions) (parse args) `shouldBe` Just (Just "/x/old")
      deprecatedFlagNotes args `shouldSatisfy` any (T.isInfixOf "deprecated")
      deprecatedFlagNotes ["typescript", "menger", "--service-codegen", "/x"] `shouldBe` []

-- | Run in a fresh temporary working directory.
inTempDir :: IO a -> IO a
inTempDir act = withSystemTempDirectory "naming10" $ \d -> withCurrentDirectory d act

-- | Run with PATH holding only fake executables of these names (each prints a
-- version), HOME and the working directory empty, so no fallback path is found.
withFixturePath :: [String] -> (FilePath -> IO a) -> IO a
withFixturePath names act = withSystemTempDirectory "naming10" $ \d -> do
  let bin = d </> "bin"; home = d </> "home"; cwd = d </> "a" </> "b"
  mapM_ (createDirectoryIfMissing True) [bin, home, cwd]
  mapM_ (\n -> do
           let f = bin </> n
           writeFile f "#!/bin/sh\necho 0.5.1\n"
           p <- getPermissions f
           setPermissions f (setOwnerExecutable True p)) names
  withEnv "PATH" bin $ withEnv "HOME" home $ withCurrentDirectory cwd (act bin)

withEnv :: String -> String -> IO a -> IO a
withEnv k v act = bracket (lookupEnv k <* setEnv k v) (maybe (unsetEnv k) (setEnv k)) (const act)
