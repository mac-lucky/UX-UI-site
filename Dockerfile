FROM nginxinc/nginx-unprivileged:1.31-alpine@sha256:334d92979f15aaecd5dd50af5105e1230e2bb70765d45b1e2f964e7c5eda81c3

LABEL org.opencontainers.image.source="https://github.com/mac-lucky/UX-UI-site"
LABEL org.opencontainers.image.description="Static portfolio site for wsawicka.com, served by nginx"

COPY ./dist /usr/share/nginx/html
EXPOSE 8080
