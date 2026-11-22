# Phase 2: GitOps Platform Verification Evidence

Date & Time: 2026-11-22T16:00:00+05:30 (10:30:00 UTC)
Environment: AWS Personal Sandbox (Region: ap-south-1)
Target Branch: phase-2-gitops

---

## 1. Measured Cluster Apply Timing
Source: `time terraform apply -no-color tfplan 2>&1 | tee docs/evidence/apply.log`
- Start Time: 2026-11-22T15:43:11+05:30
- Total Real Time: 11m 26.615s (686.615 seconds)
- User Time: 0m 4.503s
- Sys Time: 0m 0.604s
- Resources Provisioned: 58 added, 0 changed, 0 destroyed.

---

## 2. Measured Pod Counts and Status (`kubectl get pods -A`)
Total Cluster Pods: 29
Status: 29 Running, 0 Pending, 0 Failed, 0 Restarts

### Namespace Breakdown
- `kube-system` (8 pods):
  - aws-node (2 pods): 2/2 Running
  - coredns (2 pods): 1/1 Running
  - eks-pod-identity-agent (2 pods): 1/1 Running
  - kube-proxy (2 pods): 1/1 Running
- `argocd` (14 pods):
  - argocd-server (1/1 Running)
  - argocd-repo-server (1/1 Running)
  - argocd-application-controller-0 (1/1 Running)
  - argocd-applicationset-controller (1/1 Running)
  - argocd-redis (1/1 Running)
  - argocd-dex-server (1/1 Running)
  - argocd-notifications-controller (1/1 Running)
  - argocd-self-* instances (managed via Helm chart) (7 pods, 1/1 Running)
- `dev` (1 pod):
  - dev-sample-app-78c4c4999f-hh56z (1/1 Running)
- `staging` (2 pods):
  - staging-sample-app-5bd94b7ff9-d245z (1/1 Running)
  - staging-sample-app-5bd94b7ff9-mlzkd (1/1 Running)
- `kyverno` (4 pods):
  - kyverno-admission-controller-b5f755d76-hspkg (1/1 Running)
  - kyverno-background-controller-fbf6dc4b9-2mq9h (1/1 Running)
  - kyverno-cleanup-controller-c9cc448b4-qdmdg (1/1 Running)
  - kyverno-reports-controller-758c89b484-mdjlb (1/1 Running)

---

## 3. Measured ArgoCD Application Sync & Health Status (`kubectl get applications -n argocd`)
```text
NAME                 SYNC STATUS   HEALTH STATUS   REVISION                                   PROJECT
argocd-self          Synced        Healthy         10.18.2                                    default
dev-sample-app       Synced        Healthy         f4400fd1354e87e92cd4fd7fbb9da9b37e1290e2   default
root-apps            Synced        Healthy         f4400fd1354e87e92cd4fd7fbb9da9b37e1290e2   default
staging-sample-app   Synced        Healthy         f4400fd1354e87e92cd4fd7fbb9da9b37e1290e2   default
```

---

## 4. Kyverno Policy Verification & Measured Denial Text
Policy Engine: Kyverno v1.20.0 (Helm chart 3.10.0)
API: `policies.kyverno.io/v1 ValidatingPolicy`
Active Policies:
- `disallow-latest-tag` (validationActions: [Deny])
- `require-resource-limits` (validationActions: [Deny])
- `disallow-privileged-containers` (validationActions: [Deny])

### Test 1: Image using ':latest' tag
Command executed: `kubectl apply -f bad-pod-latest.yaml`
Captured Denial Text:
```text
Error from server: error when creating "/tmp/bad-pod.yaml": admission webhook "vpol.validate.kyverno.svc-fail-finegrained-disallow-latest-tag" denied the request: Policy disallow-latest-tag failed: Using ':latest' tag is not allowed. Images must use a specific pinned tag.
```

### Test 2: Missing CPU and Memory Resource Limits
Command executed: `kubectl apply -f bad-pod-no-limits.yaml`
Captured Denial Text:
```text
Error from server: error when creating "/tmp/bad-pod-priv.yaml": admission webhook "vpol.validate.kyverno.svc-fail-finegrained-require-resource-limits" denied the request: Policy require-resource-limits failed: CPU and memory resource limits are required for all containers.
```

### Test 3: Privileged Container (`privileged: true`)
Command executed: `kubectl apply -f bad-pod-privileged.yaml`
Captured Denial Text:
```text
Error from server: error when creating "/tmp/bad-pod-priv-only.yaml": admission webhook "vpol.validate.kyverno.svc-fail-finegrained-disallow-privileged-containers" denied the request: Policy disallow-privileged-containers failed: Privileged containers are not allowed.
```
