## Github Actions authentication to AWS using OIDC

The following steps is a guidance to set up **GitHub Actions** to authenticate to **AWS** using the built-in OIDC provider (short-lived tokens) instead of relying on static **AWS access keys** (long-lived).

The instructions below will let you _re-create the whole mechanism from scratch_ if the OIDC provider or IAM role ever need to be rebuilt.

--------------------------------------------------------------------
1.  Prerequisites
--------------------------------------------------------------------

• AWS CLI v2 configured for the target AWS account (you need **Administrator** or equivalent permissions only _while_ creating the resources).
• GitHub repository **owner/repo** where the workflow will run (replace with yours in the examples).

--------------------------------------------------------------------
2.  Create / verify the OIDC identity provider in AWS
--------------------------------------------------------------------

AWS now automatically creates the GitHub OIDC provider (`token.actions.githubusercontent.com`) the first time it is referenced.  If your account does **not** have one yet you can create it explicitly:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" \
  --client-id-list sts.amazonaws.com
```


You should see the provider listed afterwards:

```bash
aws iam list-open-id-connect-providers
```

--------------------------------------------------------------------
3.  Write the **trust policy** (trust.json)
--------------------------------------------------------------------

This policy tells AWS STS *which* GitHub runs are allowed to assume the role.  The most common pattern is to scope it to a repository (and optionally branch / environment).

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:OWNER/REPO:*"
        }
      }
    }
  ]
}
```

Replace **OWNER/REPO** with your GitHub repository (e.g. `learningtapestry/lt-devops`).

You may further tighten the `sub` condition, e.g. `repo:OWNER/REPO:ref:refs/heads/main` to allow only the **main** branch.

--------------------------------------------------------------------
4.  Create the IAM role and attach permissions
--------------------------------------------------------------------

```bash
# 4.1 Create the role with the trust relationship from step 3
aws iam create-role \
  --role-name github-oidc-widget \
  --assume-role-policy-document file://trust.json

# 4.2 Attach an inline policy (replace the actions/resources with your needs)
aws iam put-role-policy \
  --role-name github-oidc-widget \
  --policy-name ecr+eks \
  --policy-document file://role-permissions.json
```

Example **role-permissions.json** granting ECR push/pull, EKS access and S3 uploads:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECR",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EKS",
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster"
      ],
      "Resource": "arn:aws:eks:<REGION>:<ACCOUNT_ID>:cluster/<CLUSTER_NAME>"
    }
  ]
}
```

--------------------------------------------------------------------
5.  Reference the role in your GitHub Actions workflow
--------------------------------------------------------------------

Add / update the **aws-actions/configure-aws-credentials** step (already present in our workflows):

```yaml
steps:
  - name: Configure AWS credentials
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::<AWS_ACCOUNT_ID>:role/github-oidc-widget
      aws-region: us-east-1
```

No AWS secrets are needed – GitHub issues an OIDC token that the action exchanges for temporary STS credentials under the hood.

--------------------------------------------------------------------
6.  (Optional) Test the setup locally
--------------------------------------------------------------------

```bash
aws sts assume-role-with-web-identity \
  --role-arn arn:aws:iam::<AWS_ACCOUNT_ID>:role/github-oidc-widget \
  --role-session-name "TestSession" \
  --web-identity-token "$(gh auth token)"    # requires GitHub CLI logged-in under the repo identity
```

--------------------------------------------------------------------
7.  Troubleshooting tips
--------------------------------------------------------------------

• `AccessDenied` – check the **aud** and **sub** entries in the trust policy exactly match what the GitHub token contains.  You can print the token info inside a workflow using `echo "${{ steps.[id].outputs.id_token }}" | jq -R 'split(".") | .[1] | @base64d | fromjson'`.
• `NoSuchEntity` – the role name or provider ARN is misspelled.
• Make sure the workflow actually runs in the repository / branch you allowed.

--------------------------------------------------------------------
8.  Clean-up
--------------------------------------------------------------------

```bash
aws iam delete-role-policy --role-name github-oidc-widget --policy-name ecr+eks
aws iam delete-role --role-name github-oidc-widget
# Do **not** delete the OIDC provider if other roles depend on it
```

---

Once the steps above are complete, the `github-oidc-widget` role will be ready for your GitHub Actions workflows and no static AWS keys will be stored anywhere.

--------------------------------------------------------------------
9.  Granting the role access to EKS clusters (aws-auth / access entries)
--------------------------------------------------------------------

Assuming EKS requires two parts:

1) AWS-side: the role must be allowed to call `eks:DescribeCluster` (already in `role-permissions.json`).
2) Kubernetes-side: the role must be mapped to a Kubernetes user/group in each cluster you want to access.

Staging example (works):

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::996810415034:role/[CLUSTER NAME]-eks-nodegroup-role
      username: system:node:{{EC2PrivateDNSName}}
    - groups:
      - system:masters
      rolearn: arn:aws:iam::996810415034:role/github-oidc-widget
      username: github-actions
```

Production example (missing mapping): only nodegroup role is present – the GitHub OIDC role is not mapped yet. You must add a similar entry for production.

Ways to add the mapping (pick one):

- eksctl CLI
  ```bash
  eksctl create iamidentitymapping \
    --cluster [CLUSTER NAME] \
    --region us-east-1 \
    --arn arn:aws:iam::996810415034:role/github-oidc-widget \
    --username github-actions \
    --group system:masters
  ```

- Edit aws-auth ConfigMap directly (admin context required)
  ```bash
  kubectl -n kube-system get configmap aws-auth -o yaml > aws-auth.yaml
  # Add the mapRoles item for the GitHub role (similar to the staging example), then:
  kubectl -n kube-system apply -f aws-auth.yaml
  ```

- EKS Access Entries (newer model via console / API)
  - Console: EKS → Cluster → Access → Add access entry → Principal ARN of the role → Kubernetes group `system:masters` (or a read-only group with a proper ClusterRoleBinding).

Verification steps (in CI or locally after `aws eks update-kubeconfig`):

```bash
aws sts get-caller-identity
aws eks describe-cluster --name <cluster> --region <region>
kubectl config current-context
kubectl auth can-i list pods -n <namespace>
kubectl get pods -n <namespace>
```

If these commands succeed, the role is correctly mapped and kubectl is authorized against the cluster.
