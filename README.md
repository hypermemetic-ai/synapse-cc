# synapse-cc

Builds a typed TypeScript client from a running Plexus RPC service, in one command.

## Most people want plexus-rpc

[plexus-rpc](https://github.com/hypermemetic-ai/plexus-rpc) is the front
door to Plexus RPC: how a service is written, run and called, and a map of
every repository. The service in the example below is the one its README
builds: `myservice`, on port 4444, with one activation, `echo`.

## Install

synapse-cc is the package
[`synapse-cc`](https://hackage.haskell.org/package/synapse-cc) on Hackage.
It builds with GHC 9.8.4.

```console
$ cabal update
$ cabal install synapse-cc
```

A build needs three more things on `PATH`:

- `synapse`, from [synapse](https://github.com/hypermemetic-ai/synapse).
- `service-codegen`, the generator, at a version that reads IR 3.0. It is
  built from its repository, which is in
  [plexus-rpc's map](https://github.com/hypermemetic-ai/plexus-rpc#the-map):
  `cargo install --path .`
- Node.js with npm, which installs the client's dependencies and compiles
  it. bun, pnpm or yarn is used in npm's place when it is found.

## An example

With `myservice` running:

```console
$ synapse-cc build typescript myservice --port 4444 --output client --no-tests

==> Discovering tools...
[+] Found all required tools

==> Resolving myservice via registry at ws://127.0.0.1:4444...

==> Reading schema...
[+] Schema ready (2 plugins)

==> Generating code...
[+] Code generated (13 files)

==> Installing dependencies...
[+] Dependencies installed

==> Building...
[+] Build passed

[+] Client → client/
```

`client/echo/client.ts` holds the client of the `echo` activation:

```ts
export interface EchoClient<A = undefined> {
  /**
   * Ticks from 1 up to `to`.
   * @requires `echo.count` anywhere it is held
   */
  count(to: number): MethodStream<'echo.count', CountEvent, Up<A, EchoEvent>>;
  /**
   * Get plugin or method schema. Pass {"method": "name"} for a specific method.
   * @requires `echo.schema` anywhere it is held
   */
  schema(method?: string | null): Promise<SchemaResult>;
}
```

Both blocks are copies of files a script regenerates in
[plexus-rpc's examples](https://github.com/hypermemetic-ai/plexus-rpc/tree/main/examples).

A program connects, makes the `echo` client and reads the stream:

```ts
import { createClient, Echo } from './client';

const rpc = createClient({ backend: 'myservice', url: 'ws://127.0.0.1:4444' });
await rpc.connect();

const echo = Echo.createEchoClient(rpc);
for await (const tick of echo.count(3)) {
  console.log(tick);
}

rpc.disconnect();
```

## More

- [`build`](docs/build.md): one client from the command line, or every target of a config file.
- [`watch`](docs/watch.md): rebuild when the service's schema changes.
- [`wait`](docs/wait.md): block until services are reachable.
- [`init`](docs/init.md): write a `synapse.config.json`.
- [`_self`](docs/self.md): the cookies and headers kept for a service.
- [`synapse.config.json`](docs/config.md): every field of the config file.
- [Changelog](CHANGELOG.md)

MIT.
