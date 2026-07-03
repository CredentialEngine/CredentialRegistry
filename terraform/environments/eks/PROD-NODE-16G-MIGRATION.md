# Prod node resize to 16 GB — zero-downtime runbook (issue #1056)

Blue/green migration of the `credreg-prod` workload from the `t3.large` (8 GB)
`ng-prod` managed node group to a new `t3.xlarge` (16 GB) `ng-prod-v2` group.

Root cause of the #1056 502s: `main-app` (4 GB limit) runs chronically at its
memory ceiling and OOM-kills mid-publish. The 8 GB nodes cannot hold a larger
`main-app` limit, so we move to 16 GB nodes first, then raise the limit.

## Why blue/green (not an in-place edit)

`ng-prod` is a managed node group with **no launch template**, so `instance_types`
is ForceNew — editing it in place would destroy/recreate the whole prod node
group. We add a parallel group, drain onto it, then remove the old one.

## Facts established during preflight

- `ng-prod` is dedicated to `credreg-prod` (main-app ×4, worker ×1, redis-0). ES is scaled to 0.
- All pods: `nodeSelector env=production` + toleration for `env=production:NoSchedule`. `ng-prod-v2` replicates both.
- No pod anti-affinity → pods repack freely.
- PDBs: only `redis-pdb` (minAvailable=1) — blocks a normal drain of redis by design. main-app/worker have none.
- `redis-0` is EBS gp3, PV **pinned to us-east-1b** → its replacement node must be in 1b.
- EC2 quota: 1920 vCPU limit vs ~80 in use — ample for running both groups briefly.

## Impact summary

- **main-app**: zero user-facing impact (surge + drain behind a temp PDB).
- **worker**: zero (scaled to 2 for the window).
- **redis**: one deliberate ~15–30 s restart at the end. No data loss (EBS reattaches in 1b); not user-facing (cache + async Sidekiq broker). This is the only non-seamless step.

---

## Runbook

Context: `--context credreg-eks -n credreg-prod`. Profile: `credreg-sso`.

### 0. Baseline
```
kubectl --context credreg-eks -n credreg-prod get pods -o wide
kubectl --context credreg-eks get nodes -l env=production -L node.kubernetes.io/instance-type,topology.kubernetes.io/zone
```

### 1. Create the new node group (targeted apply — avoids unrelated state drift)
```
cd terraform/environments/eks
terraform plan            # expect: 1 to add (ng_prod_v2), 0 to destroy
terraform apply -target=module.eks.aws_eks_node_group.ng_prod_v2
```
Wait for the new `t3.xlarge` nodes to be `Ready` and confirm they span **both** 1a and 1b:
```
kubectl --context credreg-eks get nodes -l env=production -L node.kubernetes.io/instance-type,topology.kubernetes.io/zone
```
Do not continue until at least one `t3.xlarge` is Ready in `us-east-1b` (for redis).

### 2. Safety guards
```
kubectl --context credreg-eks -n credreg-prod apply -f - <<'EOF'
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: main-app-temp
  namespace: credreg-prod
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: main-app
EOF

kubectl --context credreg-eks -n credreg-prod scale deploy worker-app --replicas=2
kubectl --context credreg-eks -n credreg-prod rollout status deploy worker-app
```

### 3. Cordon the old t3.large prod nodes
```
for n in $(kubectl --context credreg-eks get nodes -l env=production \
  -o jsonpath='{range .items[?(@.metadata.labels.node\.kubernetes\.io/instance-type=="t3.large")]}{.metadata.name}{"\n"}{end}'); do
  kubectl --context credreg-eks cordon "$n"
done
```

### 4. Drain the old nodes one at a time — EXCEPT redis's node (do it last)
For each cordoned t3.large node that does **not** run `redis-0`:
```
kubectl --context credreg-eks drain <node> \
  --ignore-daemonsets --delete-emptydir-data --skip-wait-for-delete-timeout=60 --timeout=300s
# verify between each:
kubectl --context credreg-eks -n credreg-prod get pods -o wide
kubectl --context credreg-eks -n credreg-prod rollout status deploy main-app
```
main-app/worker pods reschedule onto the t3.xlarge nodes with no availability gap.

### 5. Migrate redis last (the ~30 s blip)
Confirm a `t3.xlarge` node is Ready in `us-east-1b`, then:
```
kubectl --context credreg-eks cordon <redis-old-node>        # if not already
kubectl --context credreg-eks -n credreg-prod delete pod redis-0
kubectl --context credreg-eks -n credreg-prod get pod redis-0 -o wide -w   # wait for 1/1 on a t3.xlarge in 1b
```
Verify the PV reattached and the app has no redis errors.

### 6. Decommission the old node group
Confirm the old nodes hold no non-daemonset pods, then remove the drained group:
```
terraform destroy -target=module.eks.aws_eks_node_group.ng_prod
```
Follow up (separate commit): delete the `ng_prod` resource + its variables from code.

### 7. Restore
```
kubectl --context credreg-eks -n credreg-prod scale deploy worker-app --replicas=1
# keep main-app-temp PDB (promote to a permanent manifest) — good hygiene
```
Optionally trim `ng_prod_v2_desired_size` toward steady state (~3) once stable.

### 8. Raise main-app memory limit (separate PR)
Now on 16 GB nodes, bump `main-app` `resources.limits.memory` (value TBD, e.g. 6–8Gi)
in `k8s-manifests-prod/app-deployment.yaml` and apply. This is the change that
actually fixes the OOM headroom; it is intentionally decoupled from the node move.

## Rollback

Before step 6, rollback is trivial (ng_prod is untouched):
```
for n in <old-nodes>; do kubectl --context credreg-eks uncordon "$n"; done
terraform destroy -target=module.eks.aws_eks_node_group.ng_prod_v2
kubectl --context credreg-eks -n credreg-prod scale deploy worker-app --replicas=1
kubectl --context credreg-eks -n credreg-prod delete pdb main-app-temp
```
Pods reschedule back onto the original t3.large nodes.
