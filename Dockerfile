FROM nginxinc/nginx-unprivileged:1.31-alpine@sha256:a6c3ec0c0d249d68b0682df854d4a9e222b90fb607dc3fcf2f1d2fcbc85d347e

LABEL org.opencontainers.image.source="https://github.com/mac-lucky/UX-UI-site"
LABEL org.opencontainers.image.description="Static portfolio site for wsawicka.com, served by nginx"

COPY ./dist /usr/share/nginx/html
EXPOSE 8080
