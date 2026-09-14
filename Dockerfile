# syntax=docker/dockerfile:1.7

FROM node:24-trixie-slim AS base

# TechDocs runs inside the container without a Docker socket.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git python3 python3-venv \
    && python3 -m venv /opt/techdocs \
    && /opt/techdocs/bin/pip install --no-cache-dir mkdocs-techdocs-core==1.5.3 \
    && rm -rf /var/lib/apt/lists/*
ENV PATH="/opt/techdocs/bin:${PATH}" \
    NODE_OPTIONS="--no-node-snapshot"
WORKDIR /app
RUN chown node:node /app

FROM base AS dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends g++ make \
    && rm -rf /var/lib/apt/lists/*
USER node
COPY --chown=node:node . .
RUN node .yarn/releases/yarn-4.13.0.cjs install --immutable
# Ensure new development volumes inherit writable directories.
RUN mkdir -p packages/app/node_modules packages/backend/node_modules techdocs

FROM dependencies AS development
ENV NODE_ENV=development
EXPOSE 3000 7007
CMD ["sh", "-c", "node .yarn/releases/yarn-4.13.0.cjs install --immutable && node .yarn/releases/yarn-4.13.0.cjs start --config /app/app-config.yaml --config /app/app-config.local.yaml"]

FROM dependencies AS build
RUN node .yarn/releases/yarn-4.13.0.cjs tsc \
    && node .yarn/releases/yarn-4.13.0.cjs build:backend --config ../../app-config.yaml

FROM dependencies AS production-dependencies
# Install only the workspace manifests included in the backend skeleton.
USER root
RUN mkdir -p /runtime/.yarn && chown -R node:node /runtime
USER node
WORKDIR /runtime
COPY --chown=node:node .yarn/releases/ .yarn/releases/
COPY --chown=node:node .yarnrc.yml package.json yarn.lock backstage.json ./
COPY --from=build --chown=node:node /app/packages/backend/dist/skeleton.tar.gz ./
RUN tar xzf skeleton.tar.gz && rm skeleton.tar.gz \
    && YARN_ENABLE_IMMUTABLE_INSTALLS=true node .yarn/releases/yarn-4.13.0.cjs workspaces focus --all --production

FROM base AS production
ENV NODE_ENV=production
USER node
COPY --from=production-dependencies --chown=node:node /runtime/ ./
COPY --from=build --chown=node:node /app/packages/backend/dist/bundle.tar.gz ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz
COPY --chown=node:node app-config.yaml app-config.production.yaml catalog-info.yaml ./
COPY --chown=node:node catalog/ ./catalog/
EXPOSE 7007
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
    CMD node -e "fetch('http://127.0.0.1:7007/.backstage/health/v1/readiness').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "packages/backend", "--config", "app-config.yaml", "--config", "app-config.production.yaml"]
