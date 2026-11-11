# `synapse.config.json`

`synapse-cc build`, `watch` and `wait` read `synapse.config.json` from the
current directory. [`synapse-cc init`](init.md) writes this one:

```json
{
    "schema": "1.0",
    "language": "typescript",
    "backend": "myservice",
    "url": "ws://127.0.0.1:4444",
    "packageManager": "bun",
    "watch": {
        "pollInterval": 1000,
        "hotReload": false
    },
    "targets": {
        "client": {
            "generate": [
                "transport",
                "rpc",
                "plugins"
            ],
            "transport": "ws",
            "outputDir": "src/lib/plexus"
        }
    }
}
```

## Top level

| field | required | |
| -- | -- | -- |
| `schema` | yes | The config format's version: `"1.0"`. |
| `language` | yes | `"typescript"` or `"rust"`. |
| `backend` | see below | The service's name. |
| `url` | no | The WebSocket URL, `ws://host:port`. Default `ws://127.0.0.1:4444`; the port is 4444 when the URL has none. |
| `packageManager` | no | Default `"bun"`. A build does not read it: it [picks the package manager itself](build.md#the-tools). |
| `watch.pollInterval` | no | Milliseconds between two polls of [`watch`](watch.md). Default 1000. |
| `watch.hotReload` | no | `true`: `watch` reads the config file again at every poll. Default `false`. |
| `targets` | yes | One entry or more, by name. Each is a client to build. |

`backend` is required unless every target names its own or generates only
the transport.

The host and port of `url` are used the way
[`build`](build.md#finding-the-service) uses `--host` and `--port`.

## A target

| field | required | |
| -- | -- | -- |
| `generate` | yes | What to generate. `["transport"]` generates the transport alone, with no service running. Any other list generates the whole client. [`watch`](watch.md) follows the targets whose list has `"plugins"` or `"all"`. |
| `transport` | yes | `"ws"` or `"browser"`. |
| `outputDir` | yes | Where the client is written. |
| `backend` | no | The service's name, for this target. |
| `url` | no | The URL, for this target. |
| `plugins` | no | A list of namespaces. The client is generated for these alone. |
| `sharedTransport` | no | The name of another target whose transport this one uses. |

## `sharedTransport`

A target with `sharedTransport` is built after the others. Its
`transport.ts`, `rpc.ts` and `types.ts` re-export the named target's files.
The config is refused unless:

- the named target exists and has no `sharedTransport` of its own;
- the named target's `generate` has `"transport"`, or is `["all"]`;
- both targets have the same `transport`;
- this target's `generate` has neither `"transport"` nor `"rpc"`.
