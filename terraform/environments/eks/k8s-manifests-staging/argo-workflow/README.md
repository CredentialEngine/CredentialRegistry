# Argo Workflows

These manifests install a minimal Argo Workflows control plane into the shared `credreg-staging` namespace. The controller and server components rely on a shared PostgreSQL database (for example, the RDS modules under `terraform/environments/eks`) for workflow persistence.

## Components
- `externalsecret.yaml` – syncs the AWS Secrets Manager entry `credreg-argo-workflows` into a Kubernetes Secret named `argo-postgres`.
- `configmap.yaml` – controller configuration that enables Postgres-based persistence; set the host/database here, while credentials come from the synced secret.
- `rbac.yaml` – service accounts plus the RBAC needed by the workflow controller and Argo server.
- `workflow-controller-deployment.yaml` – runs `workflow-controller` with the standard `argoexec` image.
- `argo-server.yaml` – exposes the Argo UI/API inside the cluster on port `2746`.
- `argo-basic-auth-externalsecret.yaml` – syncs the AWS Secrets Manager entry `credreg-argo-basic-auth` (or similar) to supply the base64-encoded `user:password` string for ingress auth.
- `argo-server-ingress.yaml` – optional HTTPS ingress + certificate (via cert-manager + Let’s Encrypt) and basic auth for external access to the Argo UI.

## Before applying
1. **Provision or reference a PostgreSQL instance.** Ensure the desired environment has a reachable database endpoint.
2. **Create the Secrets Manager entry.** Create `credreg-argo-workflows` (or adjust the `remoteRef.key` value) with JSON keys `host`, `port`, `database`, `username`, `password`, `sslmode`. The External Secrets Operator will sync it into the cluster and the controller/server pick them up via env vars.
3. **Update `configmap.yaml`.** Set `persistence.postgresql.host` (and database/table names if they differ) for the target environment. Even though credentials are secret-backed, Argo still requires the host in this config.
4. **Install Argo CRDs.** Apply the upstream CRDs from https://github.com/argoproj/argo-workflows/releases (required only once per cluster) before rolling out these manifests.
5. **Configure DNS if using the ingress.** Update `argo-server-ingress.yaml` with the desired hostname(s) and point the DNS record at the ingress controller’s load balancer.

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
