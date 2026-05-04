# Registry Changeset Sync

The sync pipeline converts published registry changes into compressed S3
changesets, submits Argo Workflows to apply those changesets, and blocks new
publishes while Argo is applying a changeset.

## Overview

At a high level, syncing starts when a publish or delete changes an envelope.
The publish path saves the envelope normally, initiating the debounce window,
then queues resource extraction.

Resource extraction breaks the envelope graph into individual
`EnvelopeResource` rows, records resource upsert/delete events, and advances the
community's `RegistryChangesetSync` activity cursors.

The sync row acts as both a cursor and a scheduler. It stores the latest
observed envelope version and resource event, the latest synced positions, and
the next scheduled sync time. New activity does not immediately call S3 or Argo.
Instead, it schedules `SyncRegistryChangesetsJob` after the debounce window so a
burst of publishes can be folded into one changeset.

When the debounce window expires, the sync job locks the
community by setting `syncing=true`, snapshots the latest activity cursors, and
builds pending changesets up to those cutoffs. There are three changeset streams:
graphs, metadata, and extracted resources. Each stream collapses repeated
changes to the same CTID or resource ID down to the latest relevant event in the
changeset.

For each non-empty stream, the app uploads a compressed tar archive to S3 with
the JSON documents to upsert, plus a gzipped manifest that lists both upserts
and deletes. The manifest is the handoff file for Argo. After uploading, the app
submits the `apply-changeset` WorkflowTemplate once per non-empty stream and
stores the submitted workflow names on the sync row.

While those workflows are running, publishes for that community are rejected:
the server responds with a 503 Service Unavailable status code.
The lock check also polls Argo workflow status. When all tracked workflows have
succeeded, the sync row advances its synced cursors through the changeset, clears
the workflow list, and unlocks publishing (by setting `syncing=false`).
If a workflow fails, the sync row records the error and unlocks so the failure
can be inspected and retried through the normal job/sync flow.

## Publish Entry Points

Both publish APIs call `assert_publish_unlocked!` before accepting a publish:

- `API::V1::Publish`
- `API::V2::Publish`

That helper calls `RegistryChangesetSync.syncing?(current_community)`. If the
community is locked, the API returns HTTP `503` with:

```text
Publishing is temporarily locked while registry changeset sync is in progress
```

`RegistryChangesetSync.syncing?` also reconciles any tracked Argo workflows
before returning the lock state. If Argo has completed successfully, the lock can
be cleared during the publish request that checked it.

## Publish And Resource Extraction Jobs

`PublishEnvelopeJob` is used by the async v2 publish path. Its only sync-related
role is indirect: it runs `PublishInteractor`, which saves the envelope through
the normal publishing path.

When an envelope is saved by `EnvelopeBuilder`, the app enqueues:

```ruby
ExtractEnvelopeResourcesJob.perform_later(envelope.id)
```

`ContainerRepository` does the same when a container update changes an envelope.

`ExtractEnvelopeResourcesJob` performs three steps:

1. Load the envelope.
2. Call `ExtractEnvelopeResources`.
3. Record registry changeset sync activity.

It also enqueues `IndexEnvelopeJob.perform_later(envelope_id)` for the existing
search indexing flow. That job is separate from the S3/Argo changeset sync.

`ExtractEnvelopeResources` expands the envelope JSON into `EnvelopeResource`
rows. For each current resource it records an upsert event. For resource IDs
that used to be attached to the envelope but are no longer present, it records
delete events.

After extraction, `ExtractEnvelopeResourcesJob` calls:

```ruby
RegistryChangesetSync.record_activity!(
  envelope.envelope_community,
  version_id: version_id_for_s3_sync(envelope),
  resource_event_id: latest_resource_event_id(envelope)
)
```

For envelope deletes, the model path is different:

- `Envelope#record_resource_sync_delete_events` runs before destroy and inserts
  delete events for the envelope's resources.
- `Envelope#schedule_s3_delete` runs after commit and records sync activity with
  the latest envelope version and latest resource event ID.

## Debouncing

Debouncing is owned by `RegistryChangesetSync.record_activity!` and
`SyncRegistryChangesetsJob`.

When activity is recorded:

1. The app finds or creates the community's `RegistryChangesetSync` row.
2. For a new row, the synced cursors are initialized to the previous version or
   resource event. This makes the current activity pending without backfilling
   older history.
3. Inside a row lock, the app updates `last_activity_at`.
4. `last_activity_version_id` and `last_activity_resource_event_id` are advanced
   monotonically with `max`.
5. If no future job is scheduled, or the scheduled time has already elapsed, the
   app sets `scheduled_for_at` to now plus the debounce window and enqueues
   `SyncRegistryChangesetsJob`.

The default debounce window is 60 seconds. It can be configured with:

```text
REGISTRY_CHANGESET_SYNC_DEBOUNCE_SECONDS
```

`SyncRegistryChangesetsJob` receives only `sync.id`. It does not receive a
cutoff version or cutoff resource event as job arguments. This is deliberate:
Sidekiq retries always re-read the latest sync row before doing work, so an old
retry does not carry an old changeset cutoff.

When the job runs, it locks the sync row and checks whether either cursor has
pending work:

- graph/metadata work is pending when `last_activity_version_id` is greater than
  `last_synced_version_id`;
- resource work is pending when `last_activity_resource_event_id` is greater
  than `last_synced_resource_event_id`.

If `scheduled_for_at` is still present, the job computes:

```ruby
last_activity_at + RegistryChangesetSync.debounce_window
```

If that time is still in the future, the job updates `scheduled_for_at`,
re-enqueues itself for that later time, and exits. This keeps pushing the sync
back while publishes keep arriving inside the debounce window.

If the debounce window has elapsed, the job clears `scheduled_for_at` and moves
on to syncing.

## Sync Locking

`SyncRegistryChangesetsJob` calls `sync.mark_syncing!` before building
changesets. `mark_syncing!` uses a row lock and returns `false` if another sync
is already active. This prevents two jobs for the same community from starting
the same sync concurrently.

While `syncing` is true, publishes for that community are rejected by
`assert_publish_unlocked!`.

There is stale lock recovery. If `syncing_started_at` is older than the lock
timeout, `RegistryChangesetSync#syncing?` and `mark_syncing!` clear the lock and
record:

```text
Stale sync lock cleared after timeout
```

The default timeout is 600 seconds. It can be configured with:

```text
REGISTRY_CHANGESET_SYNC_LOCK_TIMEOUT_SECONDS
```

## Changeset Selection

`SyncRegistryChangesetsJob` passes the latest observed cursors into
`SyncPendingRegistryChangesets`:

```ruby
SyncPendingRegistryChangesets.new(
  envelope_community: sync.envelope_community,
  cutoff_version_id: last_activity_version_id,
  cutoff_resource_event_id: last_activity_resource_event_id,
  sync: sync
).call
```

`SyncPendingRegistryChangesets` builds three logical changesets:

- `graphs`
- `metadata`
- `resources`

For graphs and metadata, it looks at `EnvelopeVersion` rows for the community
where:

- `item_type` is `Envelope`;
- `envelope_ceterms_ctid` is present;
- `id <= cutoff_version_id`;
- `id > last_synced_version_id`, when a synced cursor exists.

It groups by `envelope_ceterms_ctid` and selects the latest version per CTID.
That means multiple updates to the same CTID inside a changeset collapse to the
final state needed for that CTID.

For resources, it looks at `EnvelopeResourceSyncEvent` rows where:

- `envelope_community_id` matches;
- `id <= cutoff_resource_event_id`;
- `id > last_synced_resource_event_id`, when a synced cursor exists.

It groups by `resource_id` and selects the latest event per resource. Resource
sync only includes resource IDs that look like CTIDs: they must start with
`ce-`, and the remaining value must be a valid UUID.

The service also checks for newer activity after the cutoff. If a CTID or
resource ID has been superseded by a later version/event outside the cutoff, it
is skipped for this changeset. The later activity remains pending for a later sync.

## Graph, Metadata, And Resource Payloads

For graph uploads, the payload is `envelope.processed_resource`. The archive key
inside the tar is:

```text
<community>/graphs/<ctid>.json
```

For metadata uploads, the payload comes from:

```ruby
EnvelopeMetadata.from_envelope(envelope).as_json
```

The metadata document includes envelope identifiers, CTDL type, envelope type,
publisher information, ownership/publishing organization CTIDs, node header
metadata, revision history, and verification timestamps. The archive key is:

```text
<community>/metadata/<ctid>.json
```

For resource uploads, the payload is the extracted `EnvelopeResource`
`processed_resource` merged with the parent envelope `@context`. The archive key
is:

```text
<community>/resources/<resource_id>.json
```

Resource IDs are lowercased in the S3 key.

Deletes are represented in the manifest only. Delete actions do not add files to
the tar archive.

## S3 Uploads

If a source bucket is not configured, `SyncPendingRegistryChangesets`
does not upload anything. It immediately marks the sync cursors as synced
through the cutoff.

When S3 is configured, each non-empty entity changeset produces two S3 objects:

1. A compressed tar archive containing upload documents.
2. A gzipped JSON manifest describing upserts and deletes.

Archive keys are:

```text
<community>/changesets/<entity_type>/<timestamp>.tar.gz
```

Manifest keys are:

```text
<community>/changesets/manifests/<entity_type>-<timestamp>.gz
```

The timestamp is generated in UTC with microsecond precision and colons replaced
with hyphens.

Archive uploads use:

```text
content_encoding: gzip
content_type: application/x-tar
```

Manifest uploads use:

```text
content_encoding: gzip
content_type: application/json
```

Each manifest has this shape:

```json
{
  "bucket": "bucket-name",
  "entity_type": "graphs",
  "changeset_key": "community/changesets/graphs/2026-04-30T13-00-00.000000Z.tar.gz",
  "upserts": [
    {
      "envelope_ceterms_ctid": "ce-...",
      "updated_at": "2026-04-30T13:00:00Z",
      "key": "community/graphs/ce-....json"
    }
  ],
  "deletes": [
    {
      "envelope_ceterms_ctid": "ce-...",
      "updated_at": "2026-04-30T13:00:00Z",
      "key": "community/graphs/ce-....json"
    }
  ]
}
```

For resource manifests, items use `resource_id` instead of
`envelope_ceterms_ctid`.

## Argo Workflow Submission

For every non-empty manifest, `SyncPendingRegistryChangesets` calls
`SubmitChangesetWorkflow`.

`SubmitChangesetWorkflow` submits the Argo WorkflowTemplate:

```text
apply-changeset
```

The generated workflow name prefix is:

```text
<community-with-underscores-replaced>-apply-changeset-<entity-type>-
```

The workflow receives these required parameters:

- `task-image`: `ARGO_WORKFLOWS_TASK_IMAGE`
- `entity-type`: `graphs`, `metadata`, or `resources`
- `input-bucket`: `REGISTRY_CHANGESET_SYNC_SOURCE_BUCKET` (fallback to `ENVELOPE_GRAPHS_BUCKET`)
- `input-file-key`: the manifest key
- `source-bucket`: `REGISTRY_CHANGESET_SYNC_SOURCE_BUCKET` (fallback to `ENVELOPE_GRAPHS_BUCKET`)
- `target-bucket`: `REGISTRY_CHANGESET_SYNC_TARGET_BUCKET` (fallback to `ENVELOPE_GRAPHS_BUCKET`)
- `aws-region`: `AWS_REGION`

It may also receive optional parameters when configured:

- `elasticsearch-url`
- `elasticsearch-username`
- `elasticsearch-password`
- `aws-s3-service-url`

The submitted workflow metadata is stored in
`registry_changeset_syncs.argo_workflows`, including the entity type, manifest
key, workflow name, and namespace.

`ArgoWorkflowsClient` uses:

- `ARGO_WORKFLOWS_BASE_URL`
- `ARGO_WORKFLOWS_NAMESPACE`
- `ARGO_WORKFLOWS_TIMEOUT_SECONDS`, defaulting to `30`

Authentication preference is:

1. Basic auth when `ARGO_WORKFLOWS_USERNAME` and `ARGO_WORKFLOWS_PASSWORD` are
   present.
2. Bearer auth from `ARGO_WORKFLOWS_TOKEN`.

SSL verification is disabled in the client because the app runs inside a trusted
environment.

## Workflow Status And Completion

If Argo workflows were submitted, `SyncRegistryChangesetsJob` leaves
`syncing=true`. The `ensure` block only clears the sync lock when there are no
tracked Argo workflows.

Tracked workflow state is reconciled by `SyncRegistryChangesetWorkflowStatus`.
That service is called from `RegistryChangesetSync.syncing?`, which is called by
the publish lock check.

For each tracked workflow, the service calls Argo `get_workflow` and checks the
workflow phase:

- `Succeeded`: the workflow is complete.
- `Error` or `Failed`: the sync is failed.
- `Pending`, `Running`, blank, or unknown phases: the workflow is still treated
  as running.

When every tracked workflow succeeds, the service:

1. Marks synced through `last_activity_version_id` and
   `last_activity_resource_event_id`.
2. Clears `argo_workflows`.
3. Clears the sync lock.

When any workflow fails, or when a tracked workflow is missing in Argo with a
404, the service:

1. Writes `last_sync_error`.
2. Clears `argo_workflows`.
3. Clears the sync lock.

Transient Argo API errors are logged and treated as still running.

`mark_synced_through!` advances synced cursors with `max`, so synced positions
move monotonically forward.

## Retry Behavior

The Sidekiq/ActiveJob payload for `SyncRegistryChangesetsJob` is only:

```ruby
sync.id
```

The job reads `last_activity_version_id` and
`last_activity_resource_event_id` from the database each time it runs. If a job
fails because Argo or S3 is unavailable and Sidekiq retries it later, the retry
will use the current sync row state, not stale cutoff arguments from the
original attempt.

This is important for this sequence:

1. A sync starts.
2. Argo is down and the job fails.
3. More activity is recorded.
4. A later job succeeds.
5. The older failed job retries.

Because the retried job only has `sync.id`, it rechecks the current cursors and
the current lock state before syncing. It does not replay an old explicit
changeset cutoff from its original enqueue time.

## Baseline Rake Task

A maintenance task is available:

```sh
bin/rake app:mark_changeset_baseline
```

It marks the current registry state as already synced. This is intended for the
production rollout where the full database is copied to S3/Argo by a separate,
more efficient process before ongoing incremental sync starts.

For each envelope community, the task finds:

- the latest `EnvelopeVersion` for an envelope with a non-blank
  `envelope_ceterms_ctid`;
- the latest `EnvelopeResourceSyncEvent`.

If either exists, it creates or updates that community's
`RegistryChangesetSync` row so:

- `last_activity_version_id` equals `last_synced_version_id`;
- `last_activity_resource_event_id` equals `last_synced_resource_event_id`;
- `scheduled_for_at` is cleared;
- `syncing` is false;
- `syncing_started_at` is cleared;
- `last_sync_finished_at` is set to the current time;
- `last_sync_error` is cleared;
- `argo_workflows` is cleared.

After this baseline is set, the next publish records new activity after the
baseline cursors and schedules the normal debounced incremental sync.

## Main Components

- `RegistryChangesetSync` tracks one sync cursor per envelope community.
- `EnvelopeResourceSyncEvent` tracks upsert and delete events for extracted
  envelope resources.
- `ExtractEnvelopeResourcesJob` extracts resources from an envelope after a
  publish and records sync activity.
- `SyncRegistryChangesetsJob` debounces sync activity and starts the S3/Argo
  sync.
- `SyncPendingRegistryChangesets` builds graph, metadata, and resource
  changesets and uploads them to S3.
- `SubmitChangesetWorkflow` submits the Argo `apply-changeset` workflow.
- `SyncRegistryChangesetWorkflowStatus` checks Argo workflow state and unlocks
  publishing when all workflows have finished.
- `app:mark_changeset_baseline` initializes sync cursors during deployment.

## Data Model

`registry_changeset_syncs` is the per-community state table. It has a unique
`envelope_community_id` and stores:

- `last_activity_at`: when the latest publish/delete activity was recorded.
- `scheduled_for_at`: when the debounced sync job is currently expected to run.
- `syncing`: whether a changeset is currently being applied.
- `syncing_started_at`: when the lock started, used for stale lock recovery.
- `last_sync_finished_at`: when the last sync lock was cleared.
- `last_activity_version_id`: the latest envelope version observed for the
  community.
- `last_synced_version_id`: the latest envelope version confirmed synced.
- `last_activity_resource_event_id`: the latest resource event observed for the
  community.
- `last_synced_resource_event_id`: the latest resource event confirmed synced.
- `last_sync_error`: the last sync or Argo error message.
- `argo_workflows`: JSON array of submitted Argo workflows still being tracked.

`envelope_resource_sync_events` records resource-level changes. Each row has an
`envelope_community_id`, `resource_id`, and `action`; `action` is `0` for
upsert and `1` for delete.

The graph and metadata cursors are based on PaperTrail `EnvelopeVersion` rows.
The resource cursor is based on `EnvelopeResourceSyncEvent` rows.

## Operational Notes

Required environment for S3/Argo sync:

- `REGISTRY_CHANGESET_SYNC_SOURCE_BUCKET` (or `ENVELOPE_GRAPHS_BUCKET`)
- `REGISTRY_CHANGESET_SYNC_TARGET_BUCKET` (or `ENVELOPE_GRAPHS_BUCKET`)
- `AWS_REGION`
- `ARGO_WORKFLOWS_BASE_URL`
- `ARGO_WORKFLOWS_NAMESPACE`
- `ARGO_WORKFLOWS_TASK_IMAGE`
- either `ARGO_WORKFLOWS_USERNAME` and `ARGO_WORKFLOWS_PASSWORD`, or
  `ARGO_WORKFLOWS_TOKEN`

Useful optional environment:

- `REGISTRY_CHANGESET_SYNC_DEBOUNCE_SECONDS`
- `REGISTRY_CHANGESET_SYNC_LOCK_TIMEOUT_SECONDS`
- `ARGO_WORKFLOWS_TIMEOUT_SECONDS`
- `ELASTICSEARCH_URL`
- `ELASTICSEARCH_USERNAME`
- `ELASTICSEARCH_PASSWORD`
- `AWS_S3_SERVICE_URL`

To inspect the current sync state:

```ruby
RegistryChangesetSync.includes(:envelope_community).map do |sync|
  {
    community: sync.envelope_community.name,
    scheduled_for_at: sync.scheduled_for_at,
    syncing: sync.syncing,
    last_activity_version_id: sync.last_activity_version_id,
    last_synced_version_id: sync.last_synced_version_id,
    last_activity_resource_event_id: sync.last_activity_resource_event_id,
    last_synced_resource_event_id: sync.last_synced_resource_event_id,
    argo_workflows: sync.argo_workflows,
    last_sync_error: sync.last_sync_error
  }
end
```
