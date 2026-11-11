# `synapse-cc init`

Writes [`synapse.config.json`](config.md) in the current directory.

```
synapse-cc init [BACKEND]
```

`BACKEND` is the service's name.

```console
$ synapse-cc init myservice
[+] Created synapse.config.json (backend: myservice)
Edit it to configure your targets, then run:
  synapse-cc build
```

The file it writes is shown in [`synapse.config.json`](config.md).

## Without a name

`init` works the name out, and prints how:

1. From a `Cargo.toml` in the current directory or its parent, when the
   crate depends on `plexus-rpc`, `plexus-core` or `plexus-transport`: the
   crate's name.
2. From the registry at `127.0.0.1:4444`, when it lists exactly one service.

When neither gives a name, `init` writes nothing and exits 1. When the
registry lists several, it prints them.

## The transport

The target's `transport` follows the project in the current directory:

| found | `transport` |
| -- | -- |
| `src-tauri/` or a `tauri.conf.json` | `browser` |
| `vite.config.ts`, `.js`, `.mts` or `.mjs` | `browser` |
| `next.config.js`, `.ts` or `.mjs` | `browser` |
| `package.json` | `ws` |
| none of these | `ws` |

## An existing file

`init` does not overwrite. It prints `[!] synapse.config.json already exists`
and exits 1.
