FROM nginxinc/nginx-unprivileged:1.31-alpine@sha256:19c132c9ab02d3b783f478743dafc7a7f42e27aa7d2bdcbec1bb1128ca8f2a07

LABEL org.opencontainers.image.source="https://github.com/mac-lucky/UX-UI-site"
LABEL org.opencontainers.image.description="Static portfolio site for wsawicka.com, served by nginx"

# apk upgrade first: the digest-pinned base can lag Alpine package fixes, and
# upgrading at build picks them up without waiting for a base-image rebuild.
# The base image runs as uid 101, so apk needs a root window.
USER root
RUN apk upgrade --no-cache
USER 101

COPY ./dist /usr/share/nginx/html
EXPOSE 8080
