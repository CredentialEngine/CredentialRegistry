#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC_URL="${ARGO_WORKFLOWS_SWAGGER_URL:-https://raw.githubusercontent.com/argoproj/argo-workflows/main/api/openapi-spec/swagger.json}"
IMAGE="${SWAGGER_CODEGEN_IMAGE:-swaggerapi/swagger-codegen-cli-v3}"
MODULE_NAME="ArgoWorkflowsApiClient"
GEM_NAME="argo_workflows_api_client"

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

require_cmd curl
require_cmd docker

echo "Fetching Argo Workflows Swagger spec from $SPEC_URL"
curl -fsSL "$SPEC_URL" -o "$TMP_DIR/swagger.json"

echo "Generating Ruby client with $IMAGE"
docker run --rm \
  -v "$TMP_DIR:/local" \
  "$IMAGE" generate \
  -i /local/swagger.json \
  -l ruby \
  -o /local/out \
  -D "moduleName=$MODULE_NAME,gemName=$GEM_NAME" >/dev/null

DEST_DIR="$ROOT_DIR/lib/argo_workflows_api_client"
API_DIR="$DEST_DIR/api"

mkdir -p "$API_DIR"

cp "$TMP_DIR/out/lib/$GEM_NAME/api_client.rb" "$DEST_DIR/api_client.rb"
cp "$TMP_DIR/out/lib/$GEM_NAME/api_error.rb" "$DEST_DIR/api_error.rb"
cp "$TMP_DIR/out/lib/$GEM_NAME/configuration.rb" "$DEST_DIR/configuration.rb"
cp "$TMP_DIR/out/lib/$GEM_NAME/version.rb" "$DEST_DIR/version.rb"
cp "$TMP_DIR/out/lib/$GEM_NAME/api/workflow_service_api.rb" "$API_DIR/workflow_service_api.rb"

cat > "$ROOT_DIR/lib/argo_workflows_api_client.rb" <<'RUBY'
require 'argo_workflows_api_client/api_client'
require 'argo_workflows_api_client/api_error'
require 'argo_workflows_api_client/version'
require 'argo_workflows_api_client/configuration'
require 'argo_workflows_api_client/api/workflow_service_api'
RUBY

echo "Updated vendored Argo Workflows client in $DEST_DIR"
