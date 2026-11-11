# `synapse-cc wait`

Blocks until services are reachable.

```
Usage: synapse-cc wait [BACKEND] [-u|--url URL] [-t|--timeout SECONDS] 
                       [-i|--interval MS] [--debug]
```

`BACKEND` is a service's name.

| form | waits for |
| -- | -- |
| `synapse-cc wait` | every service of [`synapse.config.json`](config.md) |
| `synapse-cc wait BACKEND` | that service, at its URL in the config file |
| `synapse-cc wait BACKEND --url URL` | that service at `URL`; no config file is read |

| option | default | |
| -- | -- | -- |
| `-u`, `--url URL` | | The WebSocket URL, such as `ws://127.0.0.1:4448`. It needs `BACKEND`. |
| `-t`, `--timeout SECONDS` | 30 | How long to wait. |
| `-i`, `--interval MS` | 500 | Milliseconds between two tries. |
| `--debug` | | Print each try that fails. |

A service is reachable when it answers a call to `<backend>.hash`. `wait`
prints `<backend> reachable` for each one.

It exits 0 when every service is reachable. At the timeout it prints
`Timed out after <n>s waiting for:` with the names left, and exits 1.
