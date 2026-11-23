# Phase 3: Observability, SLOs & Multi-Window Burn Rate Alerting Verification Evidence

Date & Time: 2026-11-23T16:55:00+05:30 (11:25:00 UTC)  
Environment: AWS Personal Sandbox (Region: ap-south-1)  
Target Branch: phase-3-monitoring  

---

## 1. Measured Cluster Timing

### Apply Timing
Command: `time terraform apply -no-color tfplan 2>&1 | tee docs/evidence/apply.log`
- Start Time: 2026-11-23T16:09:07+05:30 (10:39:07 UTC)
- Total Real Time: **11m 52.104s** (712.104 seconds)
- User Time: 0m 4.542s
- Sys Time: 0m 0.589s
- Initial Resources: 58 added, 0 changed, 0 destroyed.
- Additional Resources: 1 security group rule (`ingress_self_all`) added to enable intra-node pod communication.

### Teardown Timing
*(To be recorded upon timed destroy execution)*

---

## 2. Cluster State & Component Verification

### Context & Nodes
```text
$ kubectl config current-context
arn:aws:eks:ap-south-1:<REDACTED_ACCOUNT_ID>:cluster/eks-platform

$ kubectl get nodes -o wide
NAME                                        STATUS   ROLES    AGE   VERSION               INTERNAL-IP   EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                  CONTAINER-RUNTIME
ip-10-0-1-202.ap-south-1.compute.internal   Ready    <none>   36m   v1.37.1-eks-9adbfea   10.0.1.202    <none>        Amazon Linux 2   5.10.230-223.885.amzn2.x86_64   containerd://1.7.25
ip-10-0-2-36.ap-south-1.compute.internal    Ready    <none>   36m   v1.37.1-eks-9adbfea   10.0.2.36     <none>        Amazon Linux 2   5.10.230-223.885.amzn2.x86_64   containerd://1.7.25
```

### GitOps Application State (ArgoCD)
All 5 applications Synced and Healthy:
```text
$ kubectl get applications -n argocd
NAME                 SYNC STATUS   HEALTH STATUS
argocd-self          Synced        Healthy
dev-sample-app       Synced        Healthy
monitoring           Synced        Healthy
root-apps            Synced        Healthy
staging-sample-app   Synced        Healthy
```

### Deployed Workloads & System Pods
37 pods across 6 namespaces, 100% Running:
```text
$ kubectl get pods -A
NAMESPACE     NAME                                                     READY   STATUS    RESTARTS   AGE
argocd        argocd-application-controller-0                          1/1     Running   0          31m
argocd        argocd-applicationset-controller-7c578b5f4d-l2774        1/1     Running   0          31m
argocd        argocd-dex-server-6d6548f46d-krxnn                       1/1     Running   1          31m
argocd        argocd-notifications-controller-65c7876dfd-fkc7t         1/1     Running   0          31m
argocd        argocd-redis-866bcf475c-gfntb                            1/1     Running   0          31m
argocd        argocd-repo-server-b79775fb4-wwkw9                       1/1     Running   0          31m
argocd        argocd-self-application-controller-0                     1/1     Running   0          30m
argocd        argocd-self-applicationset-controller-6cf8f6db48-sdb6m   1/1     Running   0          30m
argocd        argocd-self-dex-server-65c87c95f4-c856k                  1/1     Running   0          30m
argocd        argocd-self-notifications-controller-d8c555d9c-dvwgk     1/1     Running   0          30m
argocd        argocd-self-redis-6569d9d689-d4znl                       1/1     Running   0          30m
argocd        argocd-self-repo-server-7fcb5bf5c7-85zcd                 1/1     Running   0          30m
argocd        argocd-self-server-7b4f578744-mqxwq                      1/1     Running   0          30m
argocd        argocd-server-5dcc8f9fbf-m9hgf                           1/1     Running   0          31m
dev           dev-sample-app-78c4c4999f-lm75t                          1/1     Running   0          3m
kube-system   aws-node-5xknw                                           2/2     Running   0          35m
kube-system   aws-node-9jcvb                                           2/2     Running   0          35m
kube-system   coredns-8966fd9f9-dsftr                                  1/1     Running   0          39m
kube-system   coredns-8966fd9f9-fvj4t                                  1/1     Running   0          39m
kube-system   eks-pod-identity-agent-gwt82                             1/1     Running   0          35m
kube-system   eks-pod-identity-agent-nn2qc                             1/1     Running   0          35m
kube-system   kube-proxy-26gmv                                         1/1     Running   0          36m
kube-system   kube-proxy-zjldd                                         1/1     Running   0          36m
kyverno       kyverno-admission-controller-b5f755d76-w245r             1/1     Running   0          33m
kyverno       kyverno-background-controller-fbf6dc4b9-6ml5q            1/1     Running   0          33m
kyverno       kyverno-cleanup-controller-c9cc448b4-6xm86               1/1     Running   0          33m
kyverno       kyverno-reports-controller-758c89b484-nvlgw              1/1     Running   0          33m
monitoring    alertmanager-kube-prometheus-stack-alertmanager-0        2/2     Running   0          21m
monitoring    kube-prometheus-stack-operator-5f6b9cbdb6-59knf          1/1     Running   0          22m
monitoring    monitoring-grafana-df5dc485c-kpkfd                       3/3     Running   0          22m
monitoring    monitoring-kube-state-metrics-95b56975b-rjxfk            1/1     Running   0          22m
monitoring    monitoring-prometheus-node-exporter-f5cjf                1/1     Running   0          22m
monitoring    monitoring-prometheus-node-exporter-frc6m                1/1     Running   0          22m
monitoring    prometheus-blackbox-exporter-8448d45579-slfj4            1/1     Running   0          22m
monitoring    prometheus-kube-prometheus-stack-prometheus-0            2/2     Running   0          21m
staging       staging-sample-app-5bd94b7ff9-5ljrz                      1/1     Running   0          31m
staging       staging-sample-app-5bd94b7ff9-9xdnb                      1/1     Running   0          31m
```

---

## 3. Live SLO Telemetry Verification

### Blackbox Probe Metrics
```text
$ kubectl exec -n monitoring prometheus-kube-prometheus-stack-prometheus-0 -c prometheus -- wget -qO- "http://localhost:9090/api/v1/query?query=probe_success"
{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"probe_success","app":"dev-sample-app","environment":"dev","instance":"http://dev-sample-app.dev.svc.cluster.local:80/","job":"blackbox-dev-sample-app","namespace":"monitoring"},"value":[1795432307.055,"1"]}]}}

$ kubectl exec -n monitoring prometheus-kube-prometheus-stack-prometheus-0 -c prometheus -- wget -qO- "http://localhost:9090/api/v1/query?query=probe_duration_seconds"
{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"probe_duration_seconds","app":"dev-sample-app","environment":"dev","instance":"http://dev-sample-app.dev.svc.cluster.local:80/","job":"blackbox-dev-sample-app","namespace":"monitoring"},"value":[1795432313.037,"0.006772836"]}]}}
```

### SLI Recording Rules
```text
$ kubectl exec -n monitoring prometheus-kube-prometheus-stack-prometheus-0 -c prometheus -- wget -qO- "http://localhost:9090/api/v1/query?query=job:sample_app_availability:ratio_rate2m"
{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"job:sample_app_availability:ratio_rate2m","app":"dev-sample-app","environment":"dev","instance":"http://dev-sample-app.dev.svc.cluster.local:80/","job":"blackbox-dev-sample-app","namespace":"monitoring"},"value":[1795432483.385,"1"]}]}}

$ kubectl exec -n monitoring prometheus-kube-prometheus-stack-prometheus-0 -c prometheus -- wget -qO- "http://localhost:9090/api/v1/query?query=job:sample_app_latency:ratio_rate2m"
{"status":"success","data":{"resultType":"vector","result":[{"metric":{"__name__":"job:sample_app_latency:ratio_rate2m","app":"dev-sample-app","environment":"dev","instance":"http://dev-sample-app.dev.svc.cluster.local:80/","job":"blackbox-dev-sample-app","namespace":"monitoring"},"value":[1795432488.693,"1"]}]}}
```

---

## 4. Failure Drill Verification: SampleAppAvailabilityFastBurn

### Measured Drill Events & Timestamps
```text
[11:20:03 UTC] Scaling deployment dev-sample-app to 0 replicas...
[11:20:13 UTC +10.0s] probe_success=0.0 (synthetic probe failure detected)
[11:21:19 UTC +76.6s] burn_rate2m=66.7, burn_rate10m=16.7 (threshold > 14.4 met) -> Alert state: pending
[11:22:24 UTC +142.0s] Fast burn alert FIRING in Prometheus and received in Alertmanager
[11:23:08 UTC] Restoring deployment dev-sample-app to 1 replica...
[11:23:32 UTC +23.5s] probe_success=1.0 (pod Running, synthetic probe recovered)
[11:25:27 UTC +138.6s] burn_rate2m drops below 14.4 -> Fast burn alert RESOLVED
```

- Target Alert: `SampleAppAvailabilityFastBurn`
- Severity: `critical`
- Time to Fire: **2m 22.0s** (142.0 seconds)
- Time to Recover: **2m 18.6s** (138.6 seconds)
- Automated Recovery: Alert resolved automatically once the workload healed.

---

## 5. Residual Billable Infrastructure Checks
*(To be populated after timed destroy)*
