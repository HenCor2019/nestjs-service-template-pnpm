FROM node:20-alpine3.18 AS base

ENV DIR /app
WORKDIR $DIR

FROM base AS dev

ENV NODE_ENV=development
RUN corepack enable

COPY package*.json pnpm-lock.yaml ./
RUN pnpm fetch --frozen-lockfile
RUN pnpm install --frozen-lockfile

COPY tsconfig*.json ./
COPY .swcrc ./
COPY nest-cli.json ./
COPY src src/

EXPOSE $PORT
CMD ["pnpm", "run", "dev"]

FROM base AS build

RUN corepack enable
RUN apk update && apk add --no-cache dumb-init=1.2.5-r2

COPY package*.json pnpm-lock.yaml ./
# Bellow npm install is a workaround for https://github.com/swc-project/swc/issues/5616#issuecomment-1651214641
RUN pnpm install --save-optional \
        "@swc/core-linux-x64-gnu@1" \
        "@swc/core-linux-x64-musl@1"

COPY tsconfig*.json ./
COPY .swcrc ./
COPY nest-cli.json ./
COPY src src/

RUN pnpm run build && \
    pnpm prune --production

FROM base AS production

ENV NODE_ENV=production
ENV USER=node

COPY --from=build /usr/bin/dumb-init /usr/bin/dumb-init
COPY --from=build $DIR/node_modules node_modules
COPY --from=build $DIR/dist dist

USER $USER
EXPOSE $PORT
CMD ["dumb-init", "node", "dist/main.js"]
