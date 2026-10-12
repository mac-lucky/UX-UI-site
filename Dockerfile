FROM nginxinc/nginx-unprivileged:1.31-alpine@sha256:884e0b7f42f303641b0f4e78755aea647521dca0b89ca3be7992ad78b5c07434

LABEL org.opencontainers.image.source="https://github.com/mac-lucky/UX-UI-site"
LABEL org.opencontainers.image.description="Static portfolio site for wsawicka.com, served by nginx"

# apk upgrade first: the digest-pinned base can lag Alpine package fixes, and
# upgrading at build picks them up without waiting for a base-image rebuild.
# The base image runs as uid 101, so apk needs a root window.
USER root
# PKG_REFRESH is new on every CI build, so this RUN never comes from the layer cache.
ARG PKG_REFRESH
RUN apk upgrade --no-cache
USER 101

COPY ./dist /usr/share/nginx/html
EXPOSE 8080
