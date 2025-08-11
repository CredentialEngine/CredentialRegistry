#!/bin/bash
set -e

if [ -z "${SECRET_KEY_BASE}" ] || [ "${SECRET_KEY_BASE}" = "dummy-value" ]; then
  export SECRET_KEY_BASE="$(openssl rand -hex 32)"
  echo "[entrypoint] Generated new SECRET_KEY_BASE" >&2
fi

exec "$@"
