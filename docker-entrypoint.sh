#!/bin/bash
set -e

# Ensure app log directory and files exist (avoid EACCES/ENOENT)
mkdir -p /app/log || true
touch /app/log/production.log /app/log/newrelic_agent.log || true

if [ -z "${SECRET_KEY_BASE}" ] || [ "${SECRET_KEY_BASE}" = "dummy-value" ]; then
  export SECRET_KEY_BASE="$(openssl rand -hex 32)"
  echo "[entrypoint] Generated new SECRET_KEY_BASE" >&2
fi

exec "$@"
