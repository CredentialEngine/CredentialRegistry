# CI/CD Workflows

This repository uses GitHub Actions for build, test, security scanning, Terraform ops, and Kubernetes operations. Below is a concise catalog of each workflow: triggers, requirements, and behavior.

Build and Push Image
- Triggers: push (staging, master, production, sandbox), manual
- Behavior:
  - Builds the application container image from this repo
  - Publishes the image to AWS ECR with two tags (by date and by branch)
  - Sends a Slack message showing success/failure and the built image details

Test: Lint, Test & Analyse
- Triggers: push (master, simplecov, semgrep_fixes, hardening-dockerfile-sq), pull_request
- Behavior:
  - Installs dependencies and runs automated code checks and tests
  - Optionally runs code quality analysis (SonarQube)
  - Saves a code coverage report when available

Semgrep SAST
- Triggers: pull_request, manual
- Behavior:
  - Scans the code for security issues
  - Publishes results to GitHub’s Security tab and as a downloadable report

Terraform CI
- Triggers: pull_request (terraform/**), manual (action: plan/apply)
- Behavior:
  - Checks Terraform files are well‑formed and valid
  - Creates a plan showing what would change in AWS (and uploads it)
  - Can apply the plan when manually approved
  - Sends a Slack alert if changes (drift) are detected
- Requirements: secrets.AWS_ACCOUNT, optional secrets.SLACK_WEBHOOK_URL

Apply ConfigMap and Restart
- Trigger: manual
- Inputs: environment (staging|sandbox)
- Behavior:
  - Updates the application configuration in the chosen environment
  - Restarts the app so the new settings take effect
  - Notifies Slack with the outcome

Cluster Status
- Trigger: manual
- Behavior:
  - Shows a concise snapshot of what’s running in staging and sandbox
  - Sends that snapshot to Slack for quick review

Deploy Feature Branch to Staging
- Trigger: manual
- Input: branch (any ref)
- Behavior:
  - Builds the chosen branch as a new container image and publishes it
  - Deploys that image to the staging environment and waits until it is live

Deploy Image
- Trigger: manual
- Inputs: image (free text URI), environment (staging|sandbox|production)
- Behavior:
  - Updates deployments in the selected environment to the provided image
  - Waits for both deployments to finish rolling out (10m timeout each)
  - Notifies Slack with the result and details

Notes
- Tags: each build publishes date.build (YYYY.MM.DD.NNNN) and branch tags
- Submodules: all build/test workflows checkout submodules recursively
- Terraform: plan uploads plan.txt and can alert Slack on drift; apply is manual
- Kubernetes: workflows assume EKS_CLUSTER=ce-registry-eks and region us-east-1
