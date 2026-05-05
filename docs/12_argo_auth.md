# Argo Authentication

The registry talks to Argo through `ArgoWorkflowsClient`. The client supports
three authentication modes so existing deployments can keep their current setup
while EKS-to-EKS deployments can use short-lived Kubernetes service account
tokens.

## Required Argo Settings

All modes require:

- `ARGO_WORKFLOWS_BASE_URL`: Argo Workflows API base URL.
- `ARGO_WORKFLOWS_NAMESPACE`: Argo workflow namespace used for submit/get calls.
- `ARGO_WORKFLOWS_TIMEOUT_SECONDS`: optional request timeout, defaulting to `30`.

SSL verification is disabled in the generated Argo API client because the
service is expected to call an internal, trusted Argo endpoint.

## Authentication Precedence

`ArgoWorkflowsClient` chooses authentication in this order:

1. Short-lived Kubernetes service account token when all of these are present:
   - `ARGO_WORKFLOWS_K8S_API_URL`
   - `ARGO_WORKFLOWS_K8S_CLUSTER_NAME`
   - `ARGO_WORKFLOWS_K8S_SERVICE_ACCOUNT`
2. Basic auth when both of these are present:
   - `ARGO_WORKFLOWS_USERNAME`
   - `ARGO_WORKFLOWS_PASSWORD`
3. Static bearer token:
   - `ARGO_WORKFLOWS_TOKEN`

The Kubernetes token mode intentionally wins over Basic/static bearer auth. This
allows deployments to leave older secrets configured during rollout while the
new token flow takes effect as soon as its required variables are present.

## Short-Lived Kubernetes Token Mode

Use this mode when the registry app runs in one EKS cluster and needs to call
Argo in another EKS cluster using IAM auth. The app uses its AWS credentials
from IRSA to create an EKS IAM authenticator token, calls the target Kubernetes
`TokenRequest` endpoint, and uses the returned short-lived service account token
as the Argo bearer token.

Required variables:

- `ARGO_WORKFLOWS_K8S_API_URL`: Kubernetes API server URL for the cluster that
  hosts Argo.
- `ARGO_WORKFLOWS_K8S_CLUSTER_NAME`: exact EKS cluster name for the target
  cluster. This value is used as the `x-k8s-aws-id` signing header and must
  match the cluster name exactly.
- `ARGO_WORKFLOWS_K8S_SERVICE_ACCOUNT`: service account to request a token for,
  for example `credreg-app`.

Optional variables:

- `ARGO_WORKFLOWS_K8S_NAMESPACE`: namespace of the service account token to
  request. Defaults to `ARGO_WORKFLOWS_NAMESPACE`.
- `ARGO_WORKFLOWS_K8S_TOKEN_AUDIENCE`: token audience, defaulting to
  `https://kubernetes.default.svc`.
- `ARGO_WORKFLOWS_K8S_TOKEN_EXPIRATION_SECONDS`: requested token lifetime,
  defaulting to `600`.

The app caches the returned Kubernetes token and refreshes it shortly before
expiration. It does not persist the token.

## Target Cluster Access

The IAM role used by the registry pod must be accepted by the target EKS
cluster. In an IRSA deployment, this is the role annotated on the registry app
service account.

The target cluster must map that IAM role to a Kubernetes user/group that is
authorized to create service account tokens only for the intended Argo-facing
service account. The Kubernetes permission is a `create` on the `serviceaccounts/token`
subresource for the target namespace/service account.

Example target:

- namespace: `cer-api-sandbox`
- service account: `credreg-app`
- Kubernetes group: `credreg-app-token-requesters`

With that setup, the registry role can request a short-lived token for
`cer-api-sandbox/credreg-app`, and Argo receives that token in the normal
`Authorization: Bearer ...` header.

## Troubleshooting

- `401 Unauthorized` from the Kubernetes `TokenRequest` call usually means the
  target EKS cluster rejected the IAM authenticator token. Check
  `ARGO_WORKFLOWS_K8S_CLUSTER_NAME`, the target cluster IAM access mapping, and
  that the pod is actually assuming the expected IRSA role.
- `403 Forbidden` usually means IAM authentication succeeded, but Kubernetes
  RBAC does not allow the mapped user/group to create the requested service
  account token.
- `404 Not Found` usually means the namespace or service account name is wrong,
  or the target cluster URL is not the cluster that contains that service
  account.
- If Argo itself returns authorization errors after a token is successfully
  requested, check the permissions bound to the target service account that Argo
  uses for API authorization.
