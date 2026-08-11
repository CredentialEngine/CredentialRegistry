# Prod Changeset Sync — Stage 2 Cutover Runbook

Deploys the registry changeset-sync feature (image `2026.07.30.0154`) to `credreg-prod`.
**Stage 1 (infra: `cer-registry-changesets-prod` bucket + dedicated prod IRSA role) is already applied.**

Deploy with `REGISTRY_CHANGESET_SYNC_ENDPOINT` **unset**: changesets are generated + stored in S3
but not delivered, so the Publisher blob can be backfilled first, then the endpoint is set.

## Preconditions
- [ ] Stage-1 infra live: bucket `cer-registry-changesets-prod` + role `ce-registry-eks-prod-application-irsa-role` (verified).
- [ ] PR #1061 (Stage 1) merged so `master` matches applied infra.
- [ ] This branch (`feat/prod-changeset-cutover`) reviewed: configmap vars (endpoint omitted), SA repoint, image pins.
- [ ] Cary aware of the target time and the endpoint-set-after-backfill sequence.

## Cutover sequence

### 1. Reset the `ce_registry` marker (image-independent — run first)
Safe to run **before** the image deploy: the current prod image is pre-feature and never runs the
sync job, so nothing acts on the marker until the new image is up. This pre-empts the ~89K-version
backlog (which would otherwise be one ~180 MB ZIP under the publish-lock). Only `ce_registry` has a
stale row; other communities self-initialize on first publish.

Run over the bastion tunnel as the app user (`credential_registry_production` has UPDATE):
```sql
UPDATE registry_changeset_syncs rcs
SET last_synced_version_id          = mx.max_v,
    last_activity_version_id        = GREATEST(COALESCE(rcs.last_activity_version_id,0), mx.max_v),
    last_synced_resource_event_id   = COALESCE(mx.max_e, rcs.last_synced_resource_event_id),
    last_activity_resource_event_id = GREATEST(COALESCE(rcs.last_activity_resource_event_id,0), COALESCE(mx.max_e,0)),
    last_activity_at = now(), updated_at = now()
FROM envelope_communities ec
JOIN LATERAL (
  SELECT (SELECT max(v.id) FROM versions v
            WHERE v.item_type='Envelope' AND v.envelope_community_id = ec.id) AS max_v,
         (SELECT max(e.id) FROM envelope_resource_sync_events e
            WHERE e.envelope_community_id = ec.id) AS max_e
) mx ON true
WHERE ec.id = rcs.envelope_community_id AND ec.name = 'ce_registry';
```
Verify: `last_synced_version_id` now equals `max(versions.id)` for `ce_registry`.

### 2. Apply SA repoint + configmap (no restart yet)
```bash
kubectl --context ce-registry-eks apply -f k8s-manifests-prod/app-service-account.yaml
kubectl --context ce-registry-eks apply -f k8s-manifests-prod/app-configmap.yaml
```

### 3. Deploy the image (runs the migration)
Dispatch the **"Deploy image"** workflow: `image_label=2026.07.30.0154`, `environment=production`.
It `set image`s main-app + worker-app, rolls + restarts (pods pick up new SA role + configmap),
then runs the `db-migrate` job (`RemoveArgoFields`). Migration runs **after** rollout, so the new
pods (which don't use the Argo columns) are up before the columns are dropped.

### 4. Verify
- [ ] Pods `2026.07.30.0154`, Running; no `CreateContainerConfigError`/OOM.
- [ ] `AWS_REGION` + `REGISTRY_CHANGESET_SYNC_*` present in pods; endpoint **absent**.
- [ ] IRSA: pod can write to `s3://cer-registry-changesets-prod` (assumed role = `…-prod-application-irsa-role`).
- [ ] Trigger one small publish → a changeset ZIP lands in S3, marker advances, `last_sync_error` nil, publish-lock < a few seconds.
- [ ] Watch worker memory / in-process indexing lag under real load.

### 5. (After Cary's backfill) set the endpoint
Once Cary has seeded the blob and applied the accumulated S3 changesets, add to the configmap and
restart:
```
REGISTRY_CHANGESET_SYNC_ENDPOINT: https://api.publisher.credentialengine.org/changeset/upload
```
via the **"Apply configmap and restart"** workflow (`environment=production`).
**Gap note:** changesets generated between Cary's last "apply" pass and the endpoint going live are
in S3 but not delivered (delivery is not retroactive). Coordinate so Cary does a final apply pass
right at endpoint-set, ideally in the low-traffic window (Sun ~05:00 UTC), to minimize the gap.

## Rollback
- Pre-migration: redeploy the previous image (`2026.04.24.0146`) via the Deploy workflow; revert SA
  annotation to `ce-registry-eks-application-irsa-role`; remove changeset vars from the configmap.
- Post-migration: `RemoveArgoFields` is destructive (drops Argo columns). Rolling back to the
  Argo-based image after the migration requires restoring those columns — treat the migration as the
  point of no easy return; take an RDS snapshot immediately before Step 3.
