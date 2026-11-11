# `synapse-cc build`

Reads a running service's schema, runs the generator, installs the client's
dependencies, compiles it and runs its tests.

```
Usage: synapse-cc build [TARGET] [BACKEND] [-H|--host HOST] [-P|--port PORT] 
                        [-o|--output DIR] [--transport ws|browser] 
                        [--no-install] [--no-build] [--no-tests] 
                        [--cache-dir DIR] [--force] [--debug] [--synapse PATH] 
                        [--service-codegen PATH] [-t|--token JWT] 
                        [--token-file PATH]
```

`BACKEND` is the service's name.

## Two forms

`synapse-cc build TARGET BACKEND` builds one client and reads no config file.

`synapse-cc build`, without both arguments, builds every target of the
[`synapse.config.json`](config.md) in the current directory.

## `TARGET`

| value | client |
| -- | -- |
| `typescript`, `ts` | A TypeScript package. It is compiled with `tsc --noEmit`. |
| `rust`, `rs` | A Rust crate. It is compiled with `cargo build`, and has no install step. |

## Options

| option | default | |
| -- | -- | -- |
| `-o`, `--output DIR` | `./generated` | Where the client is written. |
| `--transport ws\|browser` | `ws` | `ws` is for Node.js. `browser` uses the native WebSocket, for a browser or a WebView. |
| `--no-install` | | Skip installing dependencies. |
| `--no-build` | | Skip compiling. |
| `--no-tests` | | Skip running the client's tests. |
| `--cache-dir DIR` | `~/.cache/plexus-codegen` | Where the schema and the record of generated files are kept. |
| `--force` | | Generate and write every file, whatever the cache holds. |
| `--debug` | | Print the version, the tools found and each step's detail. |
| `--synapse PATH` | | The `synapse` program to use. |
| `--service-codegen PATH` | | The generator to use. |
| `-t`, `--token JWT` | | A JWT to reach the service with. |
| `--token-file PATH` | | A file holding the JWT. |
| `-H`, `--host HOST` | `127.0.0.1` | The registry's host. |
| `-P`, `--port PORT` | `4444` | The registry's port. |

With a config file, each target sets its own output directory and
transport, and the host and port come from its `url`. Every other option
applies to every target.

## Finding the service

The service is looked up by name in the registry at `--host` and `--port`.
When both are left at their defaults, the environment variable
`PLEXUS_REGISTRY_URL` (`ws://host:port`) names the registry.

- The registry knows the name: the build connects to the host and port it gives.
- No registry answers there: the build connects to that host and port as the service.
- The registry answers and does not know the name: the build stops and lists the names it knows.

## The token

The first of these that is set is used:

1. `--token`
2. the environment variable `SYNAPSE_TOKEN`
3. `--token-file`
4. the cookie `access_token` kept for the service by [`_self`](self.md)

## The tools

`synapse` and `service-codegen` are looked for on `PATH`, then here:

| tool | places |
| -- | -- |
| `synapse` | a build under `../synapse` or `../../synapse`, `~/.plexus/bin`, `~/.local/bin`, `~/.cabal/bin` |
| `service-codegen` | `target/release` and `target/debug` under `../service-codegen` or `../../service-codegen`, `~/.plexus/bin`, `~/.cargo/bin` |

`--synapse` and `--service-codegen` name a file and skip the search.

A TypeScript client's dependencies are installed, and its compiler and
tests run, by one package manager. It is the one whose lockfile is in the
directory (`bun.lock`, `bun.lockb`, `pnpm-lock.yaml`, `yarn.lock`,
`package-lock.json`), or else the first of `bun`, `pnpm`, `yarn` and `npm`
found on `PATH`.

## What a build writes

- The client's files, in the output directory.
- `ir.json` in the output directory: the service's description, as the generator read it.
- `tsconfig.json` in the output directory, for a TypeScript client.
- `synapse.lock` in the current directory: for each output directory, the
  service's name, the hash of its schema, the transport and a hash of every
  generated file.
- Under the cache directory: `synapse/ir/<backend>/` and
  `synapse-cc/code/<target>/<backend>/`.

A file that is as the last build wrote it is overwritten. A file edited by
hand after that is not: the lines the generator adds are inserted into it, and
the build reports `file(s) smart-merged (new content added, user
modifications preserved)`. When fewer than half of the generated lines are
in the edited file it is left as it is, and the build reports `file(s)
skipped (user modifications preserved)`. A file of the last build that the
generator does not produce in this one is deleted if it is unedited.

When the tool versions match the cache, the schema's hash matches
`synapse.lock` and the output directory holds files, the build generates
nothing and prints the client's path.

## Inside a project

A TypeScript client is built as part of a project around it in two cases:

- the output directory has a `package.json` without a `_generatedBy` field;
- the output directory has no `package.json`, and the current directory has
  one that synapse-cc did not write.

The build prints `Integration mode — build and test steps skipped`. The
client's dependencies are added to the `package.json` of the current
directory, the generated `package.json` and `test/` files are not written,
and the project compiles the client itself.

## Exit status

0 when every client is built, 1 otherwise.
