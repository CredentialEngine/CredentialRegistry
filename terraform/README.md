# AWS INFRASTRUCTURE

## Prerequisites

### Install Metrics Server (for HPA)

Horizontal Pod Autoscalers rely on the Kubernetes Metrics API to obtain CPU / memory
usage.  The API is provided by the *metrics-server* add-on, which you must
install once in every cluster **before** deploying any HPA manifests.

The project keeps the cluster self-contained and does **not** use Helm here to
avoid an extra tool dependency; a single `kubectl apply` is enough:

```bash
# Install the latest released version
kubectl apply -f \
  https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# (Optional) if your cluster uses self-signed certificates for kubelet
# endpoints add the insecure-TLS flag:
# kubectl patch deployment metrics-server -n kube-system \
#   --type='json' \
#   -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# Verify that metrics are available
kubectl -n kube-system get deployment metrics-server
kubectl top nodes
kubectl top pods -A
```

When `kubectl top …` starts returning numbers the Metrics API is working and
Horizontal Pod Autoscalers (e.g. for the Laravel deployment) will function
without the *FailedGetResourceMetric* errors.

### NGINX Ingress Controller (production cluster)

The staging and production EKS cluster needs a Kubernetes Ingress controller so that
`Ingress` resources can expose services through a single AWS
Network-Load-Balancer (NLB).  We use the community **ingress-nginx**
project and install it with Helm.

#### A. Using Helm manually (quick, imperative)

Prerequisites

* `kubectl` is configured to talk to the **production** cluster.
* Helm ≥ v3 is installed on your workstation or CI runner.

#### 1 – Add the chart repo & create the namespace

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# namespace is only created if it does not already exist
kubectl create namespace ingress-nginx
```

#### 2 – Install / upgrade the controller

```bash
helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.replicaCount=2 \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClass=nginx \
  --set controller.service.externalTrafficPolicy=Local \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb"
```

The annotation above tells EKS to provision an NLB.  Adjust or remove it
if you are on a different cloud provider.

#### 3 – Verify

```bash
# all controller pods / services should be running
kubectl --namespace ingress-nginx get all

# the IngressClass object should exist
kubectl get ingressclass

# check that the Service has an external hostname / IP
kubectl get svc -n ingress-nginx
```

When the `nginx-ingress-controller` `Service` shows an **EXTERNAL-IP**
(or AWS hostname) you can create `Ingress` manifests that reference

```yaml
ingressClassName: nginx
```

and they will be routed through the newly created load balancer.


### EBS CSI

eksctl create iamserviceaccount \
  --region us-east-1 \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster [CLUSTER NAME] \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole_prod

  eksctl create addon --name aws-ebs-csi-driver --cluster [CLUSTER NAME] --service-account-role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/AmazonEKS_EBS_CSI_DriverRole_prod --force

### External Secrets Operator (ESO)

#### Helm values template

The chart values are version-controlled at

```
environments/eks/k8s-manifests/external-secrets-values.yaml
```

It contains two placeholders:

* `<EXTERNAL_SECRETS_ROLE_ARN>` – the ARN above.
* `<AWS_REGION>` – e.g. `us-east-1`.

### Install or upgrade (staging example)

```
# render the values file with envsubst
export ROLE_ARN=$(terraform output -raw external_secrets_irsa_role_arn)
export AWS_REGION=us-east-1

envsubst < environments/eks/k8s-manifests/external-secrets-values.yaml \
         > /tmp/eso-values.yaml

# install / upgrade
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm upgrade --install eso external-secrets/external-secrets \
     --namespace external-secrets --create-namespace \
     --values /tmp/eso-values.yaml

rm /tmp/eso-values.yaml

kubectl apply -f external-secrets-operator.yaml
```

The values set the IRSA annotation and pass `AWS_REGION` /
`AWS_DEFAULT_REGION` as environment variables.  Without those the AWS
SDK fails to call `AssumeRoleWithWebIdentity` and ESO reports *Missing Region*.

#### Verifying

```
# Store should be ready
kubectl get clustersecretstore aws-secret-manager -o=jsonpath='{.status.conditions[?(@.type=="Ready")].status}'

# ExternalSecret objects should sync and create Kubernetes Secrets
kubectl get externalsecret -A
```

If everything is configured correctly the commands above will return
`True` and your Kubernetes Secret will appear in the target namespace.

### Cluster Autoscaler

The repository includes the upstream **Cluster Autoscaler** manifest so that
the managed node group can grow or shrink automatically based on pending
pods.

#### 1 – IRSA role

`terraform apply` creates an IAM role that the autoscaler assumes via
OIDC. Grab its ARN:

```bash
terraform  output -raw cluster_autoscaler_irsa_role_arn
```

#### 2 – Annotate the ServiceAccount

Edit `environments/[environment]/k8s-manifests/cluster-autoscaler.yaml` and set the
annotation to the ARN from step 1:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cluster-autoscaler
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: <CLUSTER_AUTOSCALER_ROLE_ARN>
```

#### 3 – Deploy / upgrade

```bash
kubectl apply -f environments/[environment]/k8s-manifests/cluster-autoscaler.yaml
```

Tail the logs:

```bash
kubectl -n kube-system logs deploy/cluster-autoscaler -f | grep -iE '(scale|node group)'
```

#### 4 – Load test

Use the provided load generator to create Pending pods and trigger a
scale-up:

```bash
kubectl apply -f environments/[environment]/k8s-manifests/load-generator.yaml
kubectl get nodes -w
```

Delete when finished:

```bash
kubectl delete -f environments/[environment]/k8s-manifests/load-generator.yaml
```

#### 5 – Troubleshooting checklist

* Autoscaler log explains every decision—always read it first.
* ClusterRole includes `patch` / `update` on `nodes` and `nodes/status`
  (already in the manifest).
* Node group tags must include
  `k8s.io/cluster-autoscaler/enabled=true` and
  `k8s.io/cluster-autoscaler/<cluster-name>=owned` (added by Terraform).

With the annotation set and the tags in place the autoscaler will scale
out when pods are Unschedulable and scale in when nodes are idle.


### Cert-Manager

### Install using Helm

helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.18.2 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

#### Make sure to add the annotation to the cert-manager SA
  helm upgrade cert-manager oci://quay.io/jetstack/charts/cert-manager -n cert-manager --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::996810415034:role/ce-registry-eks-cert-manager-irsa-role --version  v1.18.2