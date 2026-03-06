# s3-graphs-zip

Streams CE graph `.json` objects from one S3 bucket into ZIP batches and uploads
the resulting archives to another bucket.

## What it does

- lists JSON files from source bucket/prefix
- groups them into batches based on target ZIP size
- processes batches in parallel
- streams each object directly into a ZIP archive
- streams the ZIP output directly back to S3
- uses multipart upload automatically for larger archives

## Requirements

- Python 3.13+

## Local install

For local testing:

```bash
uv sync --dev
```

## Run locally

Make sure AWS credentials are available in the environment or via your usual AWS
configuration files. For LocalStack or other S3-compatible endpoints, any dummy
credentials accepted by that service are sufficient.

```bash
python main.py \
  --source-bucket source-bucket \
  --source-prefix graphs/ \
  --destination-bucket destination-bucket \
  --destination-prefix zipped/ \
  --max-uncompressed-zip-size-bytes 209715200 \
  --max-workers 4 \
  --max-input-files 500
```

## Parameters

Required parameters:

- `--source-bucket`
  Source S3 bucket that contains the input graph objects.
- `--destination-bucket`
  Destination S3 bucket where the generated ZIP archives will be uploaded.

Optional parameters:

- `--source-prefix`
  Prefix inside the source bucket to scan for input files. Only keys ending in
  `.json` under this prefix are included. Default: empty prefix.
- `--destination-prefix`
  Prefix inside the destination bucket where ZIP files are written. The task
  writes `batch-00001.zip`, `batch-00002.zip`, and so on under this prefix.
  Default: empty prefix.
- `--max-uncompressed-zip-size-bytes`
  Target maximum total input size per ZIP batch, measured using the source
  object sizes reported by S3. This is the primary batching control and is an
  estimate of final ZIP size, not an exact compressed-size guarantee. A value of
  `209715200` targets about 200 MiB of uncompressed input per ZIP. Default:
  `209715200`.
- `--batch-size`
  Optional maximum number of input `.json` files allowed in a single ZIP batch.
  This acts as a safety cap on top of `--max-uncompressed-zip-size-bytes` for
  cases where many tiny files would otherwise end up in one archive. Default:
  `1000`.
- `--max-workers`
  Number of batches to process concurrently. Each worker streams one ZIP archive
  to S3 at a time. Default: `4`.
- `--max-input-files`
  Optional cap on how many input `.json` files are processed in a run. Useful
  for test runs, incremental validation, or limiting blast radius while tuning.
  Default: no limit.
- `--region`
  AWS region for the S3 client. If omitted, boto3 falls back to standard AWS
  region resolution from the environment or AWS config files.
- `--endpoint-url`
  Custom S3 endpoint URL for LocalStack or another S3-compatible service.
- `--read-chunk-size`
  Number of bytes to read from each source object per streaming read. Increase
  it to reduce request overhead; decrease it to lower per-stream memory usage.
  Default: `1048576` (1 MiB).
- `--part-size`
  Multipart upload part size in bytes for streaming ZIP uploads to S3. Must be
  at least `5242880` (5 MiB), which is the S3 multipart minimum. Default:
  `8388608` (8 MiB).
- `--manifest-path`
  Optional filesystem path where the task writes a JSON manifest describing the
  run output. This is used by Argo to capture the produced ZIP file list as a
  workflow output parameter. Default: no manifest file is written.

## Completion webhook

If `WEBHOOK_URL` is set, the CLI sends a `POST` request to that URL when processing
finishes. This happens for both successful and failed runs. `ENVIRONMENT` controls
the label in the message and defaults to `staging`.

Example:

```bash
export WEBHOOK_URL="https://example.com/webhooks/s3-graphs-zip"
export ENVIRONMENT="staging"

python main.py \
  --source-bucket source-bucket \
  --source-prefix graphs/ \
  --destination-bucket destination-bucket \
  --destination-prefix zipped/run-123
```

The request body is JSON:

```json
{"text": "..."}
```

## Output manifest

If `--manifest-path` is provided, the task writes a JSON document containing the
uploaded ZIP keys and summary metadata.

Example:

```json
{
  "batch_count": 2,
  "destination_bucket": "destination-bucket",
  "destination_prefix": "zipped/run-123",
  "total_files": 12,
  "total_input_bytes": 73400320,
  "zip_files": [
    "zipped/run-123/batch-00001.zip",
    "zipped/run-123/batch-00002.zip"
  ],
  "zip_size_bytes": 18350080
}
```

The task also prints this same manifest to stdout when processing completes.

## Destination prefix strategy

The destination bucket is expected to already exist.

Use `--destination-prefix` as a run-specific output directory so each execution writes
into its own prefix instead of reusing previous batch keys.

Example:

```bash
python main.py \
  --source-bucket source-bucket \
  --source-prefix graphs/ \
  --destination-bucket destination-bucket \
  --destination-prefix "zipped/2026-03-06T14-22-10Z" \
  --max-uncompressed-zip-size-bytes 209715200 \
  --max-workers 4
```

This produces objects like:

- `zipped/2026-03-06T14-22-10Z/batch-00001.zip`
- `zipped/2026-03-06T14-22-10Z/batch-00002.zip`

If you reuse the same destination prefix, objects with the same batch key will be overwritten.

## Test

Unit tests:

```bash
uv run pytest -q
```

Integration tests against LocalStack:

```bash
docker compose up --build tests
```

The Compose setup starts LocalStack and configures the test container with the
required endpoint and dummy AWS credentials automatically.

## Docker

Build:

```bash
docker build -t s3-graphs-zip .
```

Run:

```bash
docker run --rm s3-graphs-zip --help
```

Example:

```bash
docker run --rm \
  -e AWS_ACCESS_KEY_ID=test \
  -e AWS_SECRET_ACCESS_KEY=test \
  -e AWS_DEFAULT_REGION=us-east-1 \
  s3-graphs-zip \
  --source-bucket source-bucket \
  --source-prefix graphs/ \
  --destination-bucket destination-bucket \
  --destination-prefix zipped/
```

For LocalStack or another S3-compatible endpoint, also pass `--endpoint-url`.

## Notes

- Only keys ending in `.json` are included.
- Files inside each ZIP are stored relative to `--source-prefix`.
- Output archives are named `batch-00001.zip`, `batch-00002.zip`, etc.
