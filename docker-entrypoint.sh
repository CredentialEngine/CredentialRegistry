#!/bin/bash
set -e

# Generate secret if not set
export SECRET_KEY_BASE=${SECRET_KEY_BASE:-$(openssl rand -hex 32)}

exec "$@"
