## CI & CD How to’s

### How to deploy an already built branch ?


- [Link](https://github.com/CredentialEngine/CredentialRegistry/actions/workflows/deploy.yaml)
- Trigger: manual
- Inputs:
    - image (e.g. `staging`, `production`, `sandbox`, `2025.11.05.0001` or branch tag)
    - environment (`staging` | `sandbox` | `production`)
- Behavior:
    - Updates deployments in the selected environment to the (already built) provided image
        - [Link](https://996810415034-ya4lri4m.us-east-1.console.aws.amazon.com/ecr/repositories/private/996810415034/registry?region=us-east-1) to image repository
        - #credreg-notify slack channel publishes tags upon builds
    - Waits for both deployments to finish rolling out (10m timeout each)
    - Notifies Slack with the result and details

### How to restart application and worker ?

- [Link](https://github.com/CredentialEngine/CredentialRegistry/actions/workflows/restart-deployments.yaml)
- Trigger: manual
- Inputs:
    - environment (`staging` | `sandbox` | `production`)
- Behavior:
    - Restarts both main-app and worker-app deployments in the selected namespace (no new image is built or applied)
    - Waits for each rollout to complete (10 min timeout per deployment)
    - Notifies Slack (#credreg-notify) with the restart result and run link

### How to Build and deploy a feature branch to a given environment ?


- [Link](https://github.com/CredentialEngine/CredentialRegistry/actions/workflows/deploy-branch-to-env.yaml)
- Trigger: manual
- Inputs:
    - branch (any ref, ie: `955-auth-required`)
    - environment (staging|sandbox|production)
- Behavior:
    - Builds and pushes the specified branch to ECR (date + ref tags)
    - Updates both deployments (registry app and worker) in the selected namespace to that image
    - Applies the environment’s ConfigMap (Environment values) and restarts app and worker
    - Waits for rollouts to complete and sends a Slack summary
    

### Change variable’s value and re-deploy an environment

- [Link](https://github.com/CredentialEngine/CredentialRegistry/actions/workflows/apply-configmap-and-restart.yaml)
- Trigger: manual
- Inputs: environment (staging|sandbox|production)
- Behavior:
    - Updates the application configuration in the chosen environment
        - relevant config file:
            - Production : [https://github.com/CredentialEngine/CredentialRegistry/blob/master/terraform/environments/eks/k8s-manifests-prod/app-configmap.yaml](https://github.com/CredentialEngine/CredentialRegistry/blob/master/terraform/environments/eks/k8s-manifests-sandbox/app-configmap.yaml)
            - Sandbox : https://github.com/CredentialEngine/CredentialRegistry/blob/master/terraform/environments/eks/k8s-manifests-sandbox/app-configmap.yaml
            - Staging : [https://github.com/CredentialEngine/CredentialRegistry/blob/master/terraform/environments/eks/k8s-manifests-staging/app-configmap.yaml](https://github.com/CredentialEngine/CredentialRegistry/blob/master/terraform/environments/eks/k8s-manifests-sandbox/app-configmap.yaml)
    - Restarts the app so the new settings take effect
    - Notifies Slack with the outcome

### Cluster Status

- [Link](https://github.com/CredentialEngine/CredentialRegistry/actions/workflows/cluster-status.yaml)
- Trigger: manual
- Behavior:
    - Shows a concise snapshot of what’s running in production, staging and sandbox
    - Sends that snapshot to Slack for quick review