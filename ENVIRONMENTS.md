## Credential Registry Environments

The Credential Registry runs on a single AWS Elastic Kubernetes Service (EKS) cluster named **`ce-registry-eks`** in **us-east-1**. Within that cluster we keep three isolated namespaces, one for each environment you can interact with:

- `credreg-staging`
- `credreg-sandbox`
- `credreg-prod`

All Kubernetes manifests and supporting infrastructure files live under `terraform/environments/eks` in this repository. Each environment has its own directory inside `terraform/environments/eks/k8s-manifests-*` to keep configuration changes organized.

### Directory map

| Environment | Namespace | Manifest folder |
|-------------|-----------|-----------------|
| Staging     | `credreg-staging` | `terraform/environments/eks/k8s-manifests-staging` |
| Sandbox     | `credreg-sandbox` | `terraform/environments/eks/k8s-manifests-sandbox` |
| Production  | `credreg-prod`    | `terraform/environments/eks/k8s-manifests-prod` |

Each folder contains a consistent set of YAML files:

- `app-configmap.yaml`, `app-secrets.yaml` – application settings per environment.
- `app-deployment.yaml`, `worker-deployment.yaml` – web/worker pods.
- `db-migrate-job.yaml` – one-off Kubernetes Job to run database migrations.
- Supporting resources (ingress, service accounts, Redis, Elasticsearch/OpenSearch, etc.) tailored to that environment’s needs.

### Environment snapshots

Every environment also connects to its own dedicated Amazon RDS PostgreSQL instance in **us-east-1** so that databases, credentials, and data remain isolated per namespace.

#### Staging (`credreg-staging`)
- Purpose: preview upcoming releases before production.
- Config files: `terraform/environments/eks/k8s-manifests-staging/*`.
- S3 bucket name: `cer-envelope-graphs-staging` (see `ENVELOPE_GRAPHS_BUCKET`).
- Ingress / domain: `staging.credentialengineregistry.org`.
- Shares most settings with production but points to staging-specific buckets, IAM clients, and endpoints.
- GitHub workflows such as `deploy.yaml` or `deploy-branch-to-env.yaml` can target this namespace.

#### Sandbox (`credreg-sandbox`)
- Purpose: experimentation, QA, and partner testing without affecting staging/production data.
- Config files: `terraform/environments/eks/k8s-manifests-sandbox/*`.
- S3 bucket name: `cer-envelope-graphs-sandbox`.
- Ingress / domain: `sandbox.credentialengineregistry.org`.
- Uses sandbox-specific databases, buckets, and IAM settings; safe place to trial new configuration.

#### Production (`credreg-prod`)
- Purpose: live traffic for the public Credential Registry.
- Config files: `terraform/environments/eks/k8s-manifests-prod/*`.
- S3 bucket name: `cer-envelope-graphs-prod`.
- Ingress / domain: `registry.credentialengineregistry.org`.
- Mirrors staging structure but points to production databases, buckets, and domains.
- Only trusted workflows (e.g., `deploy.yaml`) should target this namespace.

### Working with the cluster

- AWS authentication is handled through GitHub Actions using OIDC and the role `arn:aws:iam::<account>:role/github-oidc-widget`.
- Local operators can reuse the Terraform directory structure to locate any manifest they need, apply changes, and run jobs (e.g., database migrations) using the provided workflows.
- For status checks, `cluster-status.yaml` prints summaries for all three namespaces and posts them to Slack.

If you need to update settings for an environment, edit the files in its `k8s-manifests-*` directory, run the appropriate workflow (apply/update, deploy, restart), and monitor the namespace via the provided GitHub workflows or `kubectl` commands. The consistent directory layout ensures you always know where to look, even if you are not a Kubernetes expert.
