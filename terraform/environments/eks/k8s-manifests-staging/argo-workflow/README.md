# Argo Workflows

These manifests install a minimal Argo Workflows control plane into the shared `credreg-staging` namespace. The controller and server components rely on a shared PostgreSQL database (for example, the RDS modules under `terraform/environments/eks`) for workflow persistence.

## Components
- `externalsecret.yaml` – syncs the AWS Secrets Manager entry `credreg-argo-workflows` into a Kubernetes Secret named `argo-postgres`.
- `configmap.yaml` – controller configuration that enables Postgres-based persistence; set the host/database here, while credentials come from the synced secret.
- `rbac.yaml` – service accounts plus the RBAC needed by the workflow controller and Argo server.
- `workflow-controller-deployment.yaml` – runs `workflow-controller` with the standard `argoexec` image.
- `argo-server.yaml` – exposes the Argo UI/API inside the cluster on port `2746`.
- `argo-basic-auth-externalsecret.yaml` – syncs the AWS Secrets Manager entry `credreg-argo-basic-auth` (or similar) to supply the base64-encoded `user:password` string for ingress auth.
- `argo-server-ingress.yaml` – optional HTTPS ingress + certificate (via cert-manager + Let's Encrypt) and basic auth for external access to the Argo UI.

## Before applying
1. **Provision or reference a PostgreSQL instance.** Ensure the desired environment has a reachable database endpoint.
2. **Create the Secrets Manager entry.** Create `credreg-argo-workflows` (or adjust the `remoteRef.key` value) with JSON keys `host`, `port`, `database`, `username`, `password`, `sslmode`. The External Secrets Operator will sync it into the cluster and the controller/server pick them up via env vars.
3. **Update `configmap.yaml`.** Set `persistence.postgresql.host` (and database/table names if they differ) for the target environment. Even though credentials are secret-backed, Argo still requires the host in this config.
4. **Install Argo CRDs.** Apply the upstream CRDs from https://github.com/argoproj/argo-workflows/releases (required only once per cluster) before rolling out these manifests.
5. **Configure DNS if using the ingress.** Update `argo-server-ingress.yaml` with the desired hostname(s) and point the DNS record at the ingress controller's load balancer.

## Apply order
```bash
kubectl apply -f terraform/environments/eks/k8s-manifests-staging/argo-workflow/externalsecret.yaml
kubectl apply -f terraform/environments/eks/k8s-manifests-staging/argo-workflow/rbac.yaml
kubectl apply -f terraform/environments/eks/k8s-manifests-staging/argo-workflow/configmap.yaml
kubectl apply -f terraform/environments/eks/k8s-manifests-staging/argo-workflow/workflow-controller-deployment.yaml
kubectl apply -f terraform/environments/eks/k8s-manifests-staging/argo-workflow/argo-server.yaml
# Optional ingress / certificate
kubectl apply -f terraform/environments/eks/k8s-manifests-staging/argo-workflow/argo-basic-auth-externalsecret.yaml
kubectl apply -f terraform/environments/eks/k8s-manifests-staging/argo-workflow/argo-server-ingress.yaml
```

Once the `argo-postgres` secret is synced and the controller connects to Postgres successfully, `kubectl get wf -n credreg-staging` should show persisted workflows even after pod restarts.

## Workflow Templates

### index-s3-to-es

Indexes all JSON-LD graphs from S3 directly to Elasticsearch. S3 is treated as the source of truth.

**Architecture:**
```
Argo Workflow (curl container)
    │
    ├──1. POST to Keycloak /token (client credentials grant)
    │      → Obtain fresh JWT
    │
    └──2. POST /workflows/index-all-s3-to-es
           │
           ▼
      Registry API
           │
           ├──▶ List S3 bucket objects
           │
           └──▶ For each .json file:
                   └──▶ Index to Elasticsearch
```

**Prerequisites - Keycloak Service Account:**

1. Create a Keycloak client in the `CE-Test` realm:
   - **Client ID**: e.g., `argo-workflows`
   - **Client authentication**: ON (confidential client)
   - **Service accounts roles**: ON
   - **Authentication flow**: Only "Service accounts roles" enabled

2. Assign the admin role to the service account:
   - Go to the client → Service Account Roles
   - Assign `ROLE_ADMINISTRATOR` from the `RegistryAPI` client

3. Get the client secret:
   - Go to the client → Credentials
   - Update the Client Secret


**Required configuration:**

1. **Keycloak Credentials Secret** (`argo-keycloak-credentials`):
   - `client_id` – Keycloak client ID
   - `client_secret` – Keycloak client secret

2. **Registry API environment variables** (already in app-configmap):
   - `ENVELOPE_GRAPHS_BUCKET` – S3 bucket containing JSON-LD graphs
   - `ELASTICSEARCH_ADDRESS` – Elasticsearch endpoint
   - `AWS_REGION` – AWS region for S3 access

**Trigger the workflow:**

Via Argo CLI:
```bash
argo submit --from workflowtemplate/index-s3-to-es -n credreg-staging
```

Via Argo REST API:
```bash
kubectl port-forward -n credreg-staging svc/argo-server 2746:2746
BEARER=$(kubectl create token argo-server -n credreg-staging)

curl -sk https://localhost:2746/api/v1/workflows/credreg-staging \
  -H "Authorization: Bearer $BEARER" \
  -H 'Content-Type: application/json' \
  -d '{
    "workflow": {
      "metadata": { "generateName": "index-s3-to-es-" },
      "spec": { "workflowTemplateRef": { "name": "index-s3-to-es" } }
    }
  }'
```

Via Argo UI:
1. Navigate to the Argo UI
2. Go to Workflow Templates
3. Select `index-s3-to-es`
4. Click "Submit"

**Monitor workflow:**
```bash
# List workflows
kubectl get wf -n credreg-staging

# Watch workflow status
argo watch -n credreg-staging <workflow-name>

# View logs
argo logs -n credreg-staging <workflow-name>
```

**Workflow parameters:**

| Parameter | Default | Description |
|-----------|---------|-------------|
| `api-base-url` | `http://main-app.credreg-staging.svc.cluster.local:9292` | Registry API base URL |
| `keycloak-url` | `https://test-ce-kc-002.credentialengine.org/realms/CE-Test/protocol/openid-connect/token` | Keycloak token endpoint |

Override parameters when submitting:
```bash
argo submit --from workflowtemplate/index-s3-to-es \
  -p api-base-url=http://custom-api:9292 \
  -p keycloak-url=https://other-keycloak/realms/X/protocol/openid-connect/token \
  -n credreg-staging
```
