# syntax=docker/dockerfile:1.7

FROM node:24.19.0-alpine AS base
ARG PNPM_VERSION=11.22.0
ENV PNPM_HOME=/pnpm
ENV PNPM_STORE_DIR=/pnpm/store
ENV PATH=${PNPM_HOME}:${PATH}
ENV HUSKY=0
ENV NPM_CONFIG_FUND=false
ENV NPM_CONFIG_UPDATE_NOTIFIER=false
RUN apk add --no-cache bash \
    && npm install --global pnpm@${PNPM_VERSION} \
    && pnpm config set store-dir ${PNPM_STORE_DIR}

FROM base AS fetched-deps
WORKDIR /app
COPY pnpm-workspace.yaml pnpm-lock.yaml ./
RUN pnpm fetch --frozen-lockfile

FROM node:24.19.0-alpine AS package-manifests
WORKDIR /app
COPY package.json ./package.source.json
COPY scripts/ci/docker-package-manifests.mjs ./scripts/ci/docker-package-manifests.mjs
RUN node ./scripts/ci/docker-package-manifests.mjs \
    ./package.source.json ./package.dependencies.json ./package.build.json

FROM base AS deps
WORKDIR /app
COPY --from=fetched-deps /pnpm/store /pnpm/store
COPY --from=package-manifests /app/package.dependencies.json ./package.json
COPY pnpm-workspace.yaml pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --offline --trust-lockfile

FROM deps AS prod-deps
RUN pnpm prune --prod

FROM deps AS builder
WORKDIR /app
COPY --from=package-manifests /app/package.build.json ./package.json
COPY tsconfig.json tsup.config.mjs ./
COPY src ./src
RUN pnpm typecheck
RUN pnpm build

FROM node:24.19.0-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN apk add --no-cache font-noto-arabic font-noto-thai
COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/dist ./dist
COPY --chown=node:node assets/fonts/ ./assets/fonts/
COPY --chown=node:node package.json ./
COPY --chown=node:node LICENSE.md ./
COPY --chown=node:node THIRD_PARTY_NOTICES.md ./
COPY --chown=node:node THIRD_PARTY_LICENSES/ ./THIRD_PARTY_LICENSES/
USER node
EXPOSE 3010
CMD ["node", "dist/index.js"]
