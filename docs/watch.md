# `synapse-cc watch`

Builds, then rebuilds what changed each time the service's schema changes.
It runs until it is interrupted.

```
Usage: synapse-cc watch BACKEND [PLUGIN...] [-t|--target NAME] 
                        [-i|--interval MS] [--cache-dir DIR] [--debug] 
                        [--synapse PATH] [--service-codegen PATH] 
                        [-t|--token JWT] [--token-file PATH]
```

`BACKEND` is the service's name.

| argument or option | |
| -- | -- |
| `PLUGIN...` | Rebuild only these namespaces. `echo` matches `echo` and everything under `echo.`. |
| `--target NAME` | Follow one target of the config file. |
| `-i`, `--interval MS` | Milliseconds between two polls. It overrides `watch.pollInterval`. |
| `--cache-dir DIR` | Default `~/.cache/plexus-codegen`. |
| `--debug` | Print each step's detail. |
| `--synapse PATH` | The `synapse` program to use. |
| `--service-codegen PATH` | The generator to use. |
| `--token JWT`, `--token-file PATH` | As in [`build`](build.md#the-token). |

## What it does

1. Reads [`synapse.config.json`](config.md). Without one it follows a single
   target, `client`, written to `src/lib/plexus`, for `BACKEND` at
   `ws://127.0.0.1:4444`.
2. Builds every target whose `generate` has `"plugins"` or `"all"`, or the
   one named by `--target`. It generates the files and does not install,
   compile or test.
3. Calls `<BACKEND>.hash` at the config file's `url` every interval.
4. When the hash changes, reads the schema and compares each namespace's
   hash with the cache. A changed namespace is generated again for each
   target. A namespace that is gone rebuilds each target whole.

With `watch.hotReload` set, the config file is read again at every poll.
A config file that does not parse leaves the last one in use.

A poll that fails prints a line and the next poll goes ahead.
