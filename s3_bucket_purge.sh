#!/usr/bin/env bash
set -euo pipefail

BUCKET="${1:-}"
REGION="${AWS_REGION:-us-east-1}"

if [[ -z "${BUCKET}" ]]; then
  echo "Usage: $0 <bucket-name>" >&2
  exit 1
fi

echo "Target bucket: s3://${BUCKET} (region: ${REGION})"
echo "Verifying bucket exists..."
if ! aws s3api head-bucket --bucket "${BUCKET}" >/dev/null 2>&1; then
  echo "Bucket not found or inaccessible: ${BUCKET}" >&2
  exit 1
fi

echo
echo "Listing current objects (first 50):"
aws s3 ls "s3://${BUCKET}" --recursive | head -n 50 || true
echo
echo "Object summary:"
aws s3 ls "s3://${BUCKET}" --recursive --human-readable --summarize | tail -n 3 || true

echo
echo "Counting versions and delete markers (if versioning enabled)..."
VERSIONS_COUNT=$(aws s3api list-object-versions --bucket "${BUCKET}" --output text --query 'length(Versions)' 2>/dev/null || echo 0)
DELETEM_COUNT=$(aws s3api list-object-versions --bucket "${BUCKET}" --output text --query 'length(DeleteMarkers)' 2>/dev/null || echo 0)
echo "Versions: ${VERSIONS_COUNT}"
echo "Delete markers: ${DELETEM_COUNT}"

echo
read -r -p "Purge ALL objects, versions, and delete markers? Type 'delete' to confirm: " CONFIRM
if [[ "${CONFIRM}" != "delete" ]]; then
  echo "Aborted."
  exit 1
fi

echo
echo "Deleting all object versions (if any)..."
aws s3api list-object-versions --bucket "${BUCKET}" --output text --query 'Versions[].[Key,VersionId]' \
| while read -r KEY VERSION_ID; do
    [[ -z "${KEY:-}" || -z "${VERSION_ID:-}" ]] && continue
    aws s3api delete-object --bucket "${BUCKET}" --key "${KEY}" --version-id "${VERSION_ID}" >/dev/null || true
  done

echo "Deleting all delete markers (if any)..."
aws s3api list-object-versions --bucket "${BUCKET}" --output text --query 'DeleteMarkers[].[Key,VersionId]' \
| while read -r KEY VERSION_ID; do
    [[ -z "${KEY:-}" || -z "${VERSION_ID:-}" ]] && continue
    aws s3api delete-object --bucket "${BUCKET}" --key "${KEY}" --version-id "${VERSION_ID}" >/dev/null || true
  done

echo "Deleting any remaining (unversioned/current) objects..."
aws s3 rm "s3://${BUCKET}" --recursive >/dev/null || true

echo
read -r -p "Remove the S3 bucket itself? Type 'remove' to confirm: " CONFIRM_BUCKET
if [[ "${CONFIRM_BUCKET}" != "remove" ]]; then
  echo "Bucket deletion skipped."
  exit 0
fi

echo "Deleting bucket..."
aws s3api delete-bucket --bucket "${BUCKET}" --region "${REGION}"
echo "Bucket deleted: ${BUCKET}"

