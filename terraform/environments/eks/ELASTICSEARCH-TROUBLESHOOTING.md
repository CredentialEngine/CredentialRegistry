Elasticsearch Cluster Formation Runbook

Purpose: quick steps to diagnose and recover master election and discovery issues for sandbox, staging, and production.

1) Identify the namespace and files
- Sandbox: namespace `credreg-sandbox`
  - StatefulSet: `terraform/environments/eks/k8s-manifests-sandbox/elasticsearch-statefulset.yaml`
  - Headless discovery Service: `terraform/environments/eks/k8s-manifests-sandbox/elasticsearch-headless-svc.yaml`
  - Client Service (HTTP 9200): `terraform/environments/eks/k8s-manifests-sandbox/elasticsearch-svc.yaml`
- Staging: namespace `credreg-staging` (same filenames under `k8s-manifests-staging`)
- Production: namespace `credreg-prod` (same filenames under `k8s-manifests-prod`)

2) Verify discovery wiring
- Check headless (discovery) Service is truly headless and exposes transport 9300:
  - `kubectl -n <ns> get svc elasticsearch-discovery -o yaml`
  - Expect: `spec.clusterIP: None`, port 9300 present. In prod we only expose 9300.
- Ensure it publishes NotReady addresses (needed for bootstrap):
  - Expect: `spec.publishNotReadyAddresses: true`
- Endpoints resolve to Pod IPs:
  - `kubectl -n <ns> get endpoints elasticsearch-discovery -o wide`
  - Expect two 10.x IPs with port 9300.

3) Verify Pod DNS and subdomain
- StatefulSet Pod template must set the subdomain to the discovery Service name:
  - Expect in StatefulSet: `spec.template.spec.subdomain: elasticsearch-discovery`
- From a Pod, verify DNS:
  - `kubectl -n <ns> exec elasticsearch-0 -- getent hosts elasticsearch-discovery.<ns>.svc.cluster.local`
  - `kubectl -n <ns> exec elasticsearch-0 -- getent hosts elasticsearch-1.elasticsearch-discovery.<ns>.svc.cluster.local`

4) Check transport connectivity
- From each Pod:
  - `kubectl -n <ns> exec elasticsearch-0 -- sh -c "nc -zv elasticsearch-1.elasticsearch-discovery 9300 || true"`
  - `kubectl -n <ns> exec elasticsearch-1 -- sh -c "nc -zv elasticsearch-0.elasticsearch-discovery 9300 || true"`
- If connection fails, check NetworkPolicies:
  - `kubectl -n <ns> get networkpolicy`

5) First-time bootstrap (one-time only)
- For a cluster that has never formed and logs show:
  - "master not discovered yet … this node has not previously joined a bootstrapped cluster"
- Temporarily add bootstrap env to the StatefulSet (do not commit to git):
  - `kubectl -n <ns> patch statefulset elasticsearch --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/0/env/-","value":{"name":"cluster.initial_master_nodes","value":"elasticsearch-0,elasticsearch-1"}}]'`
- Restart Pods to pick it up:
  - `kubectl -n <ns> delete pod -l app=elasticsearch`
- Verify health:
  - `kubectl -n <ns> port-forward statefulset/elasticsearch 9200:9200 &`
  - `curl -s http://localhost:9200/_cluster/health?pretty` (expect yellow/green, nodes: 2)
- Remove the bootstrap env after cluster forms:
  - `IDX=$(kubectl -n <ns> get sts elasticsearch -o json | jq -r '.spec.template.spec.containers[0].env | map(.name) | index("cluster.initial_master_nodes")')`
  - `if [ "$IDX" != "null" ]; then kubectl -n <ns> patch sts elasticsearch --type='json' -p="[{\"op\":\"remove\",\"path\":\"/spec/template/spec/containers/0/env/$IDX\"}]"; fi`
  - `kubectl -n <ns> rollout status statefulset/elasticsearch`

6) Recover from stale data (destructive, wipes ES data)
- If logs show "locked into cluster UUID … remove this setting" or bootstrap still fails and you accept data loss:
  - Scale down: `kubectl -n <ns> scale sts/elasticsearch --replicas=0`
  - Delete PVCs:
    - `kubectl -n <ns> delete pvc elasticsearch-data-elasticsearch-0 || true`
    - `kubectl -n <ns> delete pvc elasticsearch-data-elasticsearch-1 || true`
  - Ensure bootstrap env is present on the StatefulSet (see step 5).
  - Scale up: `kubectl -n <ns> scale sts/elasticsearch --replicas=2`
  - Verify health, then remove bootstrap env and roll once (as in step 5).

7) Common warnings and fixes
- "address [172.x.x.x:9300] … connect_timeout" → discovery resolving to a non-headless Service. Ensure `clusterIP: None` on discovery Service.
- Per-pod DNS not resolving during bootstrap → set `publishNotReadyAddresses: true` on discovery Service and `subdomain: elasticsearch-discovery` on the Pod template.
- Field limit errors when indexing (e.g., `Limit of total fields [0] has been exceeded …`):
  - Raise per-index limit: `curl -X PUT http://elasticsearch:9200/<index>/_settings -H 'Content-Type: application/json' -d '{"index.mapping.total_fields.limit": 20000}'`
  - Or set a default template: `/_index_template/ce-default` with `index.mapping.total_fields.limit`.

8) Service separation best practice
- discovery/headless Service: P2P transport only (9300)
- client Service: HTTP only (9200). App ConfigMaps point to `http://elasticsearch:9200`.

9) Health and indices quick checks
- Health: `curl -s http://elasticsearch:9200/_cluster/health?pretty`
- Indices: `curl -s http://elasticsearch:9200/_cat/indices?h=index,docs.count,store.size`
- Total docs: `curl -s http://elasticsearch:9200/_stats/docs?pretty | jq '.indices | to_entries | map(.value.primaries.docs.count) | add'`

10) Apply manifests
- After editing files under `k8s-manifests-*`, apply them per environment:
  - `kubectl -n <ns> apply -f elasticsearch-headless-svc.yaml`
  - `kubectl -n <ns> apply -f elasticsearch-svc.yaml` (if present)
  - `kubectl -n <ns> apply -f elasticsearch-statefulset.yaml`

Keep this runbook updated as we evolve manifests and procedures.

