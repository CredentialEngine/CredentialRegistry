# Triggering Argo Workflows via port-forward + curl

Use this guide when you need to submit a workflow from your workstation without going through the ingress (no basic auth). The flow is:

1. **Port-forward the Argo server service**
   ```bash
   kubectl port-forward -n credreg-staging svc/argo-server 2746:2746
   ```
   Leave this running in a separate terminal; it exposes `https://localhost:2746`.

2. **Mint a service-account token**
   ```bash
   BEARER=$(kubectl create token argo-server -n credreg-staging)
   ```
   Any SA with workflow submit/list permissions works (`argo-server` or `argo-workflow-controller`).

3. **Create the workflow payload**
   ```bash
   cat > wf.json <<'EOF'
   {
     "workflow": {
       "apiVersion": "argoproj.io/v1alpha1",
       "kind": "Workflow",
       "metadata": { "generateName": "rest-test-" },
       "spec": {
      "serviceAccountName": "argo-workflow-controller",
      "entrypoint": "hello",
         "templates": [
           {
          "name": "hello",
          "container": {
            "image": "public.ecr.aws/docker/library/debian:stable-slim",
            "command": ["bash", "-c"],
            "args": [
              "apt-get update >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y cowsay >/dev/null && /usr/games/cowsay \"hello from REST\""
            ]
          }
        }
      ]
    }
     }
   }
   EOF
   ```

4. **Submit the workflow (cURL)**
   ```bash
   curl -sk https://localhost:2746/api/v1/workflows/credreg-staging \
     -H "Authorization: Bearer $BEARER" \
     -H 'Content-Type: application/json' \
     -d @wf.json
   ```
   A successful response echoes the workflow metadata (UID, status, etc.).

## Trigger via Postman

1. Keep the port-forward running: `kubectl port-forward -n credreg-staging svc/argo-server 2746:2746`.
2. Generate a Bearer token: `kubectl create token argo-server -n credreg-staging` (copy the value).
3. In Postman:
   - **Method:** `POST`
   - **URL:** `https://localhost:2746/api/v1/workflows/credreg-staging`
   - **Headers:**
     - `Authorization: Bearer <token>`
     - `Content-Type: application/json`
   - **Body:** raw JSON from `wf.json` (same payload as above).
4. Disable SSL verification in Postman (Settings → General → “SSL certificate verification” off) or import the Argo server cert so the self-signed TLS passes.
5. Send the request; you should see the workflow metadata returned. Use the same token for subsequent requests until it expires.

5. **Verify status**
   ```bash
   kubectl get wf -n credreg-staging
   kubectl logs -n credreg-staging wf/<workflow-name>
   ```

6. **Clean up**
   - `kubectl delete wf <workflow-name> -n credreg-staging` (optional)
   - Stop the `kubectl port-forward` process.

> Tip: For ad-hoc tests, this approach avoids ingress auth entirely. When you’re ready to call the public endpoint, add the ingress basic-auth header and keep using the Bearer token in parallel.
