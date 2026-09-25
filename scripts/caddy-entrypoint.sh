#!/bin/sh
set -eu

if [ -z "${DOMAIN_NAME:-}" ]; then
  printf '%s\n' 'DOMAIN_NAME es obligatorio para activar el perfil HTTPS' >&2
  exit 1
fi

if [ "${JELLYFIN_HTTP_BIND_ADDRESS:-127.0.0.1}" != "127.0.0.1" ]; then
  printf '%s\n' 'JELLYFIN_HTTP_BIND_ADDRESS debe ser 127.0.0.1 cuando Caddy está activo' >&2
  exit 1
fi

if [ -z "${JELLYFIN_PUBLISHED_SERVER_URL:-}" ]; then
  printf '%s\n' 'JELLYFIN_PUBLISHED_SERVER_URL es obligatorio para activar HTTPS' >&2
  exit 1
fi

case "${JELLYFIN_PUBLISHED_SERVER_URL}" in
  https://*) ;;
  *)
    printf '%s\n' 'JELLYFIN_PUBLISHED_SERVER_URL debe comenzar con https://' >&2
    exit 1
    ;;
esac

exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
