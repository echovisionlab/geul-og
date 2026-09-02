# Docker build notes

The Dockerfile keeps dependency fetching, installation, compilation, and the
runtime image in separate stages:

- `pnpm-lock.yaml` and `pnpm-workspace.yaml` are fetched before application
  source is copied.
- `scripts/ci/docker-package-manifests.mjs` separates dependency metadata from
  release-only package metadata.
- Development dependencies are pruned before the final image is assembled.
- The final image contains the compiled worker, production dependencies, and
  the Noto fonts required by Satori, and runs as the non-root `node` user.

The build has no private-source credential or registry-secret requirement:

```bash
docker build --platform linux/amd64 -t geul-og:local .
docker run --rm --entrypoint sh geul-og:local -lc '
  set -eu
  test -s /app/dist/index.js
  test -s /app/assets/fonts/NotoSans-Regular.ttf
  test -d /app/node_modules/sharp
  test ! -e /app/node_modules/.bin/tsup
  node --version
'
```

The worker needs PostgreSQL, S3, and the Backend at runtime. A local startup
check without those services is expected to stop at the PostgreSQL connection
boundary; it does not prove readiness. The release workflow separately
smoke-tests the exact immutable image digest after publication.
