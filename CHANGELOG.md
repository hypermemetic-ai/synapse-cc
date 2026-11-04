# Changelog for synapse-cc

## 0.4.0

### Breaking

- Built on `plexus-synapse >= 4.0 && < 5` and `plexus-protocol >= 0.6 && < 0.7`
  (was `plexus-synapse >= 3.14.3 && < 3.18`). The IR synapse-cc builds and
  hands to the generator is synapse 4.0's IR 3.0 (a method's `returns`,
  `error`, `progress` and `cardinality` read from the plexus 0.7 schema),
  so the generator must read IR 3.0. Backends must serve plexus 0.7 or the
  published 0.7.0 line.
- `watch`: a failed hash call reports the server's typed error, rendered as
  plexus-protocol 0.6's `renderRemoteError` line.

### Changed

- `synapse-cc-test`, which needs a live substrate on `127.0.0.1:4444`, is
  now opt-in: `cabal test -f live-tests`. The hermetic suites
  (`safe6-authcheck`, `naming`) run by default.
- `cabal.project` lists only `.`; the plexus packages come from Hackage.

## Since 0.3.3 (unpublished 0.3.4 - 0.3.6)

- The generator is `service-codegen`, found by that name first;
  `--service-codegen` replaces the generator's old flag (hidden, still
  read). `synapse.lock` writes `serviceCodegen` and reads either key.
- Warns when the generator found is older than 0.5.0, which does not leave
  server-injected parameters out of generated methods.
- `synapse-cc init` takes or infers the backend; a `cargo build` step for
  generated Rust clients; the registry endpoint is read from
  `PLEXUS_REGISTRY_URL`.
- Auth: `--cookie` and `--header`, credentials scanned from the
  environment, token resolution through synapse's `_self` credential
  store, and a warning when cookie auth does not match the backend.
