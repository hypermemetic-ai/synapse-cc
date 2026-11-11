# `synapse-cc _self`

Manages the cookies and headers kept for a service. They are in
`~/.plexus/<backend>/defaults.json`, the file `synapse _self` manages too.

```
Usage: synapse-cc _self BACKEND COMMAND
```

`BACKEND` is the service's name.

| command | |
| -- | -- |
| `show [--json]` | Show what is kept, with resolved values. |
| `set KIND NAME VALUE-OR-URI` | Set a cookie or header to a value or URI. |
| `set-from-stdin KIND NAME` | Set a cookie or header from stdin, as a `literal:` value. |
| `set-secret KIND NAME` | Push stdin to the keychain and keep a `keychain://` reference. |
| `unset KIND NAME [-y\|--yes] [--no-delete-from-keychain]` | Remove a cookie or header. |
| `resolve KIND NAME` | Resolve and print a cookie or header value. |
| `upgrade-to-keychain [KIND] [NAME]` | Move `literal:` values into the keychain. |
| `clear [-y\|--yes]` | Delete this service's `defaults.json`. |
| `import-token PATH-OR-- [--to-keychain]` | Import a JWT from a file, or from stdin with `-`, as the cookie `access_token`. |

`KIND` is `cookie` or `header`.

`VALUE-OR-URI` is a raw value, or a URI with one of the schemes `literal:`,
`env://`, `file://`, `keychain://`, `vault://`.

A service that has nothing kept shows this:

```console
$ synapse-cc _self nosuchservice-xyz show
Backend: nosuchservice-xyz
Path:    ~/.plexus/nosuchservice-xyz/defaults.json

(no defaults configured for this backend)
```

[`build`](build.md#the-token) and [`watch`](watch.md) use the cookie
`access_token` as the service's token when no other is given.
