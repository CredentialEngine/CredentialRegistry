# Running DB Migration Job Manually (staging)

This guide shows how to run and observe the one‑shot database migration Job in the `credreg-staging` namespace using `kubectl`.

Prerequisites
- `kubectl` configured to point at the EKS cluster (e.g., `aws eks update-kubeconfig --name ce-registry-eks --region us-east-1`)
- Permissions to create Jobs and read logs in `credreg-staging`

Paths
- Job manifest: `terraform/environments/eks/k8s-manifests-staging/db-migrate-job.yaml`
  - Uses image: `996810415034.dkr.ecr.us-east-1.amazonaws.com/registry:staging`
  - Runs: `bundle exec rake db:migrate RACK_ENV=production`

## 1) Create a Job
The manifest uses `generateName`, so Kubernetes assigns a unique name per run. Capture it into a shell variable:

```bash
NAMESPACE=credreg-staging
MANIFEST=terraform/environments/eks/k8s-manifests-staging/db-migrate-job.yaml
JOB_NAME=$(kubectl -n "$NAMESPACE" create -f "$MANIFEST" -o name | sed 's|job.batch/||')
echo "Created job: $JOB_NAME"
```

## 2) Wait for completion
```bash
kubectl -n "$NAMESPACE" wait --for=condition=complete "job/$JOB_NAME" --timeout=10m
```

## 3) View logs
```bash
kubectl -n "$NAMESPACE" logs "job/$JOB_NAME" --all-containers=true
```
If there are multiple pods (retries), view the most recent pod:
```bash
POD=$(kubectl -n "$NAMESPACE" get pods -l job-name="$JOB_NAME" -o jsonpath='{.items[-1:].0.metadata.name}')
kubectl -n "$NAMESPACE" logs "$POD" --all-containers=true
```

## 4) Troubleshooting
- Describe the Job and Pod for events:
```bash
kubectl -n "$NAMESPACE" describe job "$JOB_NAME"
kubectl -n "$NAMESPACE" get pods -l job-name="$JOB_NAME"
POD=$(kubectl -n "$NAMESPACE" get pods -l job-name="$JOB_NAME" -o jsonpath='{.items[-1:].0.metadata.name}')
kubectl -n "$NAMESPACE" describe pod "$POD"
```
- If the Job failed and you want to retry, delete it and re‑create:
```bash
kubectl -n "$NAMESPACE" delete job "$JOB_NAME"
# Then go back to step 1 to create a fresh job
```

## 5) Use a specific image tag (optional)
By default the manifest uses the `staging` tag. To run with a specific tag produced by CI (e.g., `2025.09.25.7391`), create from a modified manifest on the fly:
```bash
TAG=2025.09.25.7391
NAMESPACE=credreg-staging
MANIFEST=terraform/environments/eks/k8s-manifests-staging/db-migrate-job.yaml
JOB_NAME=$(sed "s#:staging#:$TAG#g" "$MANIFEST" \
  | kubectl -n "$NAMESPACE" create -f - -o name | sed 's|job.batch/||')
echo "Created job: $JOB_NAME (image tag: $TAG)"
```
Note: The Job template includes `imagePullPolicy: Always`, so the node pulls the exact tag specified.

## 6) Cleanup
The Job has `ttlSecondsAfterFinished: 600`, so Kubernetes will garbage‑collect it ~10 minutes after completion. To delete immediately:
```bash
kubectl -n "$NAMESPACE" delete job "$JOB_NAME"
```

## 7) Common errors
- `CrashLoopBackOff` or `ImagePullBackOff`: Verify the image and tag exist in ECR and the node can pull (IRSA/ECR auth).
- `rake`/migration errors: Check DB connectivity env (from `app-secrets` and `main-app-config`), and inspect logs.
- `pg_dump` version mismatch (SQL schema dumps): Ensure the image contains the correct PostgreSQL client version.
