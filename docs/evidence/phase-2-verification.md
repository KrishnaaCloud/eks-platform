# Phase 2: GitOps Platform Verification Evidence

Date & Time: 2026-11-22T16:21:00+05:30 (10:51:00 UTC)
Environment: AWS Personal Sandbox (Region: ap-south-1)
Target Branch: phase-2-gitops

---

## 1. Measured Cluster Timing
### Apply Timing
Source: `time terraform apply -no-color tfplan 2>&1 | tee docs/evidence/apply.log`
- Start Time: 2026-11-22T15:43:11+05:30
- Total Real Time: 11m 26.615s (686.615 seconds)
- User Time: 0m 4.503s
- Sys Time: 0m 0.604s
- Resources Provisioned: 58 added, 0 changed, 0 destroyed.

### Destroy Timing
Source: `time terraform destroy -auto-approve -no-color 2>&1 | tee docs/evidence/destroy.log`
- Start Time: 2026-11-22T16:10:44+05:30
- Total Real Time: 10m 30.480s (630.480 seconds)
- User Time: 0m 7.694s
- Sys Time: 0m 0.933s
- Resources Decommissioned: 58 destroyed.

---

## 2. Interactive Terminal Verification Session

```text
$ kubectl config current-context
arn:aws:eks:ap-south-1:<REDACTED_ACCOUNT_ID>:cluster/eks-platform

$ kubectl run bad-test --image=nginx:latest
Error from server: admission webhook "vpol.validate.kyverno.svc-fail-finegrained-require-resource-limits" denied the request: Policy require-resource-limits failed: CPU and memory resource limits are required for all containers.
Note: kubectl run without flags does not set container resource limits, causing require-resource-limits to evaluate and deny admission before image tag validation.

$ kubectl run bad-limits --image=nginx:1.27
Error from server: admission webhook "vpol.validate.kyverno.svc-fail-finegrained-require-resource-limits" denied the request: Policy require-resource-limits failed: CPU and memory resource limits are required for all containers.

$ kubectl apply -f /tmp/bad-latest.yaml
Error from server: error when creating "/tmp/bad-latest.yaml": admission webhook "vpol.validate.kyverno.svc-fail-finegrained-disallow-latest-tag" denied the request: Policy disallow-latest-tag failed: Using ':latest' tag is not allowed. Images must use a specific pinned tag.
Note: Applied manifest specifying image nginx:latest WITH cpu/memory requests and limits and no privileged flag, isolating and verifying the disallow-latest-tag policy.

$ kubectl apply -f /tmp/priv.yaml
Error from server: error when creating "/tmp/priv.yaml": admission webhook "vpol.validate.kyverno.svc-fail-finegrained-disallow-privileged-containers" denied the request: Policy disallow-privileged-containers failed: Privileged containers are not allowed.

$ kubectl get applications -n argocd
NAME                 SYNC STATUS   HEALTH STATUS
argocd-self          Synced        Healthy
dev-sample-app       Synced        Healthy
root-apps            Synced        Healthy
staging-sample-app   Synced        Healthy

$ kubectl get validatingpolicies
NAME                             AGE     READY
disallow-latest-tag              8m29s   true
disallow-privileged-containers   8m28s   true
require-resource-limits          8m28s   true

$ kubectl get pods -A
NAMESPACE     NAME                                                     READY   STATUS    RESTARTS   AGE
argocd        argocd-application-controller-0                          1/1     Running   0          11m
argocd        argocd-applicationset-controller-7c578b5f4d-khqps        1/1     Running   0          11m
argocd        argocd-dex-server-6d6548f46d-zzs5l                       1/1     Running   0          11m
argocd        argocd-notifications-controller-65c7876dfd-pmmnn         1/1     Running   0          11m
argocd        argocd-redis-866bcf475c-hqjmq                            1/1     Running   0          11m
argocd        argocd-repo-server-b79775fb4-6lxq9                       1/1     Running   0          11m
argocd        argocd-self-application-controller-0                     1/1     Running   0          10m
argocd        argocd-self-applicationset-controller-6cf8f6db48-ppbnt   1/1     Running   0          10m
argocd        argocd-self-dex-server-65c87c95f4-d4nxs                  1/1     Running   0          10m
argocd        argocd-self-notifications-controller-d8c555d9c-q45fp     1/1     Running   0          10m
argocd        argocd-self-redis-6569d9d689-6cp4s                       1/1     Running   0          10m
argocd        argocd-self-repo-server-7fcb5bf5c7-krrw7                 1/1     Running   0          10m
argocd        argocd-self-server-7b4f578744-sf9fb                      1/1     Running   0          10m
argocd        argocd-server-7cc7657f99-6zgkm                           1/1     Running   0          11m
dev           dev-sample-app-78c4c4999f-hh56z                          1/1     Running   0          11m
kube-system   aws-node-j6vh7                                           2/2     Running   0          13m
kube-system   aws-node-q5d7h                                           2/2     Running   0          13m
kube-system   coredns-8966fd9f9-4mjml                                  1/1     Running   0          16m
kube-system   coredns-8966fd9f9-xmlx5                                  1/1     Running   0          16m
kube-system   eks-pod-identity-agent-f748r                             1/1     Running   0          13m
kube-system   eks-pod-identity-agent-zkmhf                             1/1     Running   0          13m
kube-system   kube-proxy-9qjzp                                         1/1     Running   0          13m
kube-system   kube-proxy-htmnj                                         1/1     Running   0          13m
kyverno       kyverno-admission-controller-b5f755d76-hspkg             1/1     Running   0          9m50s
kyverno       kyverno-background-controller-fbf6dc4b9-2mq9h            1/1     Running   0          9m50s
kyverno       kyverno-cleanup-controller-c9cc448b4-qdmdg               1/1     Running   0          9m50s
kyverno       kyverno-reports-controller-758c89b484-mdjlb              1/1     Running   0          9m50s
staging       staging-sample-app-5bd94b7ff9-d245z                      1/1     Running   0          11m
staging       staging-sample-app-5bd94b7ff9-mlzkd                      1/1     Running   0          11m
```

---

## 3. Dedicated Denial Messages by Policy

### 1. Disallow Latest Tag Policy Denial
Demonstrated by applying `/tmp/bad-latest.yaml` (configured with `image: nginx:latest`, valid CPU/memory limits, unprivileged):
```text
Error from server: error when creating "/tmp/bad-latest.yaml": admission webhook "vpol.validate.kyverno.svc-fail-finegrained-disallow-latest-tag" denied the request: Policy disallow-latest-tag failed: Using ':latest' tag is not allowed. Images must use a specific pinned tag.
```

### 2. Require Resource Limits Policy Denial
Demonstrated by `kubectl run bad-limits --image=nginx:1.27` (missing CPU/memory resource limits):
```text
Error from server: admission webhook "vpol.validate.kyverno.svc-fail-finegrained-require-resource-limits" denied the request: Policy require-resource-limits failed: CPU and memory resource limits are required for all containers.
```

### 3. Disallow Privileged Containers Policy Denial
Demonstrated by applying `/tmp/priv.yaml` (configured with a pinned image, valid CPU/memory limits, and `privileged: true`):
```text
Error from server: error when creating "/tmp/priv.yaml": admission webhook "vpol.validate.kyverno.svc-fail-finegrained-disallow-privileged-containers" denied the request: Policy disallow-privileged-containers failed: Privileged containers are not allowed.
```

---

## 4. Post-Destroy Residual Check (ap-south-1)
Timestamp: 2026-11-22T16:21:35+05:30
- EKS Clusters: `aws eks list-clusters` -> `{"clusters": []}`
- NAT Gateways: `aws ec2 describe-nat-gateways --filter Name=state,Values=pending,available` -> `{"NatGateways": []}`
- EBS Volumes: `aws ec2 describe-volumes --filters Name=status,Values=available` -> `{"Volumes": []}`
- Load Balancers: `aws elbv2 describe-load-balancers` -> `{"LoadBalancers": []}`
- Elastic IPs: `aws ec2 describe-addresses` -> `{"Addresses": []}`
- EC2 Instances: `aws ec2 describe-instances --filters Name=instance-state-name,Values=pending,running` -> `[]`
