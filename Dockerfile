FROM nginxinc/nginx-unprivileged:1.31-alpine@sha256:901e944d1f4fc2bd077e8f5568b98c1f6f8cdacf6b97a87747c43134a339b9a7

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
