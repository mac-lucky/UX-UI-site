FROM nginxinc/nginx-unprivileged:1.31-alpine@sha256:b5047b9b76845eac124358373c6852377c52e4b05834a47647e955dd91cb8f1e

LABEL org.opencontainers.image.source="https://github.com/mac-lucky/UX-UI-site"
LABEL org.opencontainers.image.description="Static portfolio site for wsawicka.com, served by nginx"

COPY ./dist /usr/share/nginx/html
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
# Outside conf.d on purpose: nginx.conf includes conf.d/*.conf at http level,
# and these headers belong only where default.conf includes them.
COPY nginx/security-headers.conf /etc/nginx/security-headers.conf

# The base image ships a stock 50x.html, which the COPY above does not overwrite.
# Nothing references it, and the .html redirect would make it reachable at /50x.
# The base image runs as uid 101, so this and apk need a root window.
USER root
RUN rm -f /usr/share/nginx/html/50x.html

# apk upgrade first: the digest-pinned base can lag Alpine package fixes, and
# upgrading at build picks them up without waiting for a base-image rebuild.
# PKG_REFRESH is new on every CI build, so this RUN never comes from the layer cache.
ARG PKG_REFRESH
RUN apk upgrade --no-cache

# Parse the config here so a bad regex or a misplaced directive fails the build
# instead of the container start. nginx -t leaves a root-owned /tmp/nginx.pid
# behind, which uid 101 cannot overwrite at start, so remove it.
RUN nginx -t && rm -f /tmp/nginx.pid

# Numeric, not `nginx`: a pod with runAsNonRoot and no runAsUser has to prove
# non-root from the image metadata alone, and a named user fails that check.
USER 101
# Runs as the final USER, so a USER root left above, or a pid file the check
# left behind, fails the build rather than the deploy.
RUN [ "$(id -u)" = "101" ] && [ ! -e /tmp/nginx.pid ]

EXPOSE 8080
