#!/usr/bin/env bash
set -euo pipefail

# Simple HTTP stress script for GET /
# - Sends N total requests with C concurrent workers to the provided base URL
# - Prints HTTP status code distribution and average latency

usage() {
  cat <<USAGE
Usage: $(basename "$0") [-u BASE_URL] [-n REQUESTS] [-c CONCURRENCY]

Options:
  -u BASE_URL   Base URL of the registry app (default: http://localhost:9292)
  -n REQUESTS   Total number of requests to send (default: 200)
  -c CONCURRENCY  Number of concurrent workers (default: 20)

Example:
  $(basename "$0") -u http://localhost:9292 -n 1000 -c 50
USAGE
}

BASE_URL="http://localhost:9292"
TOTAL=200
CONCURRENCY=20

while getopts ":u:n:c:h" opt; do
  case "$opt" in
    u) BASE_URL="$OPTARG" ;;
    n) TOTAL="$OPTARG" ;;
    c) CONCURRENCY="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument" >&2; usage; exit 1 ;;
    \?) echo "Unknown option -$OPTARG" >&2; usage; exit 1 ;;
  esac
done

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
  exit 1
fi

TMP_OUT=$(mktemp)
trap 'rm -f "$TMP_OUT"' EXIT

echo "Hitting: ${BASE_URL}/  Total: ${TOTAL}  Concurrency: ${CONCURRENCY}" >&2

# Fire requests in parallel; record http_code and total_time per request
seq 1 "$TOTAL" | \
  xargs -P "$CONCURRENCY" -n 1 -I {} \
    curl -sS -o /dev/null -w "%{http_code} %{time_total}\n" "${BASE_URL}/" \
  | tee "$TMP_OUT" >/dev/null

# Summarize results
TOTAL_DONE=$(wc -l < "$TMP_OUT" | awk '{print $1}')
SUCCESS=$(awk '$1 ~ /^2/ {count++} END {print count+0}' "$TMP_OUT")
REDIRECT=$(awk '$1 ~ /^3/ {count++} END {print count+0}' "$TMP_OUT")
CLIENT_ERR=$(awk '$1 ~ /^4/ {count++} END {print count+0}' "$TMP_OUT")
SERVER_ERR=$(awk '$1 ~ /^5/ {count++} END {print count+0}' "$TMP_OUT")
AVG_LAT=$(awk '{sum+=$2} END { if (NR>0) printf "%.3f", sum/NR; else print "0" }' "$TMP_OUT")

echo "--- Summary ---"
echo "Total:     $TOTAL_DONE"
echo "2xx:       $SUCCESS"
echo "3xx:       $REDIRECT"
echo "4xx:       $CLIENT_ERR"
echo "5xx:       $SERVER_ERR"
echo "Avg (s):   $AVG_LAT"

exit 0

