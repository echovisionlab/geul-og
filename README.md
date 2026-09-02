# Geul OG

Geul OG is the background worker that renders immutable WebP Open Graph
images from generation jobs. It claims work from PGMQ, obtains the immutable
render target from the Backend, writes the preallocated object to S3, and
reports the result through the internal API.

## Requirements

- Node.js `24.19.0`
- pnpm `11.22.0`

## Development

```bash
pnpm install --frozen-lockfile
pnpm lint
pnpm typecheck
pnpm test
pnpm build
pnpm start
```

The runtime requires `DATABASE_DSN`, `S3_ENDPOINT`, `S3_MEDIA_BUCKET`,
`S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `BACKEND_URL`, and
`TOKEN_SIGNING_SECRET`. `PORT`, `S3_REGION`, `OG_GENERATE_WORKERS`, and
`OG_SHUTDOWN_TIMEOUT_MS` have safe defaults. See `.env.example` for a local
configuration shape. Compose uses `GEUL_*` wrapper variables and passes the
runtime contract through unchanged.

## Compatibility contracts

The worker preserves the existing `InternalOgService` RPCs,
`OgGenerationJob` protobuf type, `og.generate` queue, and S3 object-key and
database storage layout. These names and values are protocol or storage
contracts, not branding choices. `GET /health` is ready only after a live
PostgreSQL query succeeds.

## Docker

```bash
docker build --platform linux/amd64 -t geul-og:local .
docker run --rm geul-og:local
```

The image runs as the non-root `node` user, listens on port `3010`, and
contains only production dependencies plus the rendering fonts.

## Releases

Release Please creates `vX.Y.Z` tags from `main`. The release workflow checks
out that exact commit and publishes both the version tag and an immutable
commit tag for:

`registry.dsub.io/echovisionlab/geul-og`

The deployment system should consume the resulting digest. Manual tags,
ad-hoc releases, and direct production control-plane changes are not part of
this repository.

## License

The source is released under the [PolyForm Noncommercial License 1.0.0](LICENSE.md).
Bundled fonts are covered by the [third-party notices](THIRD_PARTY_NOTICES.md)
and the included [Noto Sans OFL 1.1 text](THIRD_PARTY_LICENSES/OFL-1.1-NotoSans.txt)
and [Source OFL 1.1 text](THIRD_PARTY_LICENSES/OFL-1.1-Source.txt).
