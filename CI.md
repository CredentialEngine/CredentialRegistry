CI/CD Workflows

This repository uses GitHub Actions for building, testing, scanning, deploying, and cluster operations. This document describes each workflow, how it is triggered, required inputs/secrets, and what it does.

Build and Push Image (.github/workflows/build.yaml)
- Triggers
  - push on branches: eks-infrastructure, staging, main, master, production, sandbox
  - workflow_dispatch (manual)
- Secrets/vars
  - secrets.AWS_ACCOUNT (AWS account id used by OIDC role)
  - secrets.SLACK_WEBHOOK_URL (optional; Slack incoming webhook)
- What it does
  - Checks out code (with submodules)
  - Authenticates to AWS via GitHub OIDC and logs into ECR
  - Builds multi-stage Docker image and pushes to ECR
    - Tags: date.build (YYYY.MM.DD.NNNN) and branch name
  - Exposes image URI as an output
  - Slack notification (always): success/failure with date tag, branch tag, and image digest

Test: Lint, Test & Analyse (.github/workflows/test.yaml)
- Triggers
  - push on: master, simplecov, semgrep_fixes, hardening-dockerfile-sq
  - pull_request
- What it does
  - Checks out code (with submodules)
  - Sets up Ruby and installs gems in non-frozen mode (handles path gem submodule)
  - Starts Postgres service, migrates DB, runs Overcommit hooks and RSpec tests
  - SonarQube scan (if configured)
  - Uploads coverage/ artifact only if it exists

Semgrep SAST (.github/workflows/sast.yaml)
- Triggers
  - pull_request
  - workflow_dispatch (manual)
- What it does
  - Runs Semgrep with config p/default on app, lib, config
    - Saves JSON report (semgrep.json) as an artifact
  - Exports SARIF with r2c-security-audit rules on app and lib
    - Uploads SARIF to GitHub Code Scanning
- Secrets/vars
  - none required; optional SLACK integration can be added similarly if desired

Terraform CI (.github/workflows/terraform.yaml)
- Triggers
  - pull_request (only when files under terraform/** change)
  - workflow_dispatch with input action: plan or apply
- Jobs
  - fmt-validate: terraform fmt -check, init, validate
  - plan: init + plan, uploads plan.txt; Slack drift notification if plan includes add/change/destroy
  - apply: init + plan + apply (only when manually dispatched with action=apply; uses protected environment terraform-apply)
- AWS access
  - Uses OIDC role arn:aws:iam::${{ secrets.AWS_ACCOUNT }}:role/github-oidc-widget
- Secrets/vars
  - secrets.AWS_ACCOUNT (required)
  - secrets.SLACK_WEBHOOK_URL (optional; used for drift notifications)

Mirror Repo (.github/workflows/mirror.yml)
- Triggers
  - push on any branch
  - workflow_dispatch (manual)
- What it does
  - Pushes full repo (branches, tags) to a target repository using git push --mirror
- Secrets
  - secrets.MIRROR_TARGET_REPO (e.g., github.com/org/target-repo.git)
  - secrets.MIRROR_TOKEN (PAT with repo scope on target)
- Note
  - If you prefer manual mirroring from local, see guidance in prior PR comments; this workflow can be disabled/deleted if not used.

Apply ConfigMap and Restart (.github/workflows/apply-configmap-and-restart.yaml)
- Trigger
  - workflow_dispatch (manual)
- Inputs
  - environment: staging or sandbox
- What it does
  - Authenticates to AWS/EKS
  - Applies app-configmap.yaml for the selected environment directory:
    - terraform/environments/eks/k8s-manifests-${environment}/app-configmap.yaml
  - Restarts main-app and worker-app deployments in the inferred namespace:
    - staging → credreg-staging
    - sandbox → credreg-sandbox
  - Slack notification (always): success/failure with environment and run link

Cluster Status (.github/workflows/cluster-status.yaml)
- Trigger
  - workflow_dispatch (manual)
- What it does
  - Authenticates to AWS/EKS and prints:
    - Nodes summary (includes env label)
    - credreg-staging: pods, deployments, HPAs
    - credreg-sandbox: pods, deployments, HPAs
  - Slack notification (always): includes job status and clipped outputs from staging/sandbox

Deploy Feature Branch to Staging (.github/workflows/deploy-feature-to-staging.yaml)
- Trigger
  - workflow_dispatch (manual)
- Input
  - branch: any git ref (branch or tag) to build and deploy
- What it does
  - Checks out the provided ref with submodules
  - Builds and pushes an image to ECR (tags: sanitized branch and date.build)
  - Updates credreg-staging deployments with the branch-tagged image:
    - deploy/main-app (container: main-app)
    - deploy/worker-app (container: worker)
  - Waits for rollout completion
- Notes
  - Designed for testing feature branches in staging without merging

Secrets and Required Configuration
- AWS
  - secrets.AWS_ACCOUNT: AWS Account ID used by the OIDC role
  - OIDC Role: arn:aws:iam::${AWS_ACCOUNT}:role/github-oidc-widget must include the permissions defined in terraform/environments/github-ci-oidc/* for the workflows to operate (ECR/EKS/S3/SSM/IAM/etc.)
- Slack
  - secrets.SLACK_WEBHOOK_URL: Incoming webhook for notifications (optional but recommended)
- Mirror (optional)
  - secrets.MIRROR_TARGET_REPO, secrets.MIRROR_TOKEN

Operational Notes
- Build image tagging
  - Each build pushes two tags: date.build (e.g., 2025.10.24.0123) and branch (e.g., sandbox)
- Submodules
  - Workflows that run Bundler or Docker builds check out git submodules recursively to resolve path-based gems
- Terraform plan/apply
  - Plan uploads plan.txt; if drift is detected, a Slack message is sent prompting manual apply
  - Apply only runs on workflow_dispatch with action=apply and may be protected by environment reviewers
- Kubernetes access
  - All cluster workflows assume EKS cluster name from env EKS_CLUSTER (currently ce-registry-eks) and region us-east-1

