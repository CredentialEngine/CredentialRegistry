# Registry changeset sync

Registry changes are collected per envelope community and flushed after a trailing
60-second quiet period. Every new publish or delete moves the end of the quiet
period forward. The debounce duration can be changed with
`REGISTRY_CHANGESET_SYNC_DEBOUNCE_SECONDS`.

A completed window produces one ZIP archive and uploads only that archive to S3.
No individual graph, resource, metadata document, manifest, or delete marker is
copied separately to S3.

The ZIP layout is:

```text
upserts/
  graphs/<ctid>.json
  resources/<ctid>.json
  metadata/<ctid>.json
deletes/
  graphs/<ctid>.json
  resources/<ctid>.json
  metadata/<ctid>.json
```

Upsert files contain the complete JSON document. Delete files contain an
`identifier` and `deleted_at` timestamp. Empty directories are omitted.

The archive object key is:

```text
<community>/changesets/<UTC timestamp>.zip
```

The preferred bucket variable is `REGISTRY_CHANGESET_SYNC_BUCKET`. For backward
compatibility, `REGISTRY_CHANGESET_SYNC_SOURCE_BUCKET` and
`ENVELOPE_GRAPHS_BUCKET` are accepted as fallbacks. `AWS_REGION` configures the
S3 client.

The full envelope-community export remains separate. `DownloadEnvelopesJob`
runs `DownloadEnvelopes`, which incrementally updates the existing ZIP and
uploads it to `ENVELOPE_DOWNLOADS_BUCKET` without an external workflow engine.

Publishing is locked only while the local changeset ZIP is being assembled and
uploaded. The lock is cleared immediately on success or failure; Sidekiq retries
failed jobs using the existing pending cutoffs.

## Changeset endpoint delivery

Set `REGISTRY_CHANGESET_SYNC_ENDPOINT` to POST each completed changeset ZIP to an HTTP or HTTPS endpoint after it is uploaded to S3. The request body is the same ZIP byte stream stored in S3 and uses `Content-Type: application/zip`.

The request includes these headers:

- `Content-Disposition`: attachment filename for the ZIP.
- `X-Registry-Community`: envelope community name.
- `X-Registry-Changeset-Key`: S3 object key for the ZIP.

`REGISTRY_CHANGESET_SYNC_ENDPOINT_TIMEOUT_SECONDS` controls both the connection and response timeout and defaults to 30 seconds. A non-2xx response or network error fails the changeset run and does not advance the synced cutoffs, allowing the job to retry.
