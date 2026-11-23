# ADR 0007: Synthetic Blackbox Probing for Service Level Objectives (SLOs)

## Status
Accepted

## Date
2026-11-23

## Context
In Phase 3, we implemented production-style Service Level Objectives (SLOs) and alerting for application workloads running on the EKS cluster. We required a robust telemetry strategy to measure user-facing Service Level Indicators (SLIs) for availability and latency.

Two primary architectural approaches were considered for measuring SLIs:
1. **Whitebox Application Telemetry**: In-process metrics instrumentation (e.g., Prometheus client libraries embedded in application code, or ingress controller / service mesh access logs).
2. **Synthetic Blackbox Probing**: External or out-of-process synthetic HTTP health probes running via the Prometheus Blackbox Exporter (`prometheus-blackbox-exporter`), executing end-to-end HTTP requests against the application service endpoint.

## Decision
We chose **Synthetic Blackbox Probing** using `prometheus-blackbox-exporter` managed by Prometheus Operator `Probe` Custom Resources (`monitoring.coreos.com/v1`).

### Rationale
1. **True User-Perspective Telemetry**: Synthetic probes exercise the complete network and request lifecycle: CoreDNS name resolution (`dev-sample-app.dev.svc.cluster.local`), Kubernetes Service virtual IP routing (kube-proxy / iptables), cross-node network overlay (AWS VPC CNI), container runtime port binding, and application HTTP processing. Whitebox metrics measure only internal execution and cannot detect upstream DNS failures, routing drops, or kube-proxy routing breakages.
2. **Decoupling from Application Runtimes**: Blackbox probing does not require modifying workload source code, vendoring client libraries, or standardizing frameworks across polyglot microservices. Any HTTP-compliant application can be immediately onboarded with declarative SLIs.
3. **Deterministic Evaluation Windows**: Consistent 10-second probing intervals provide a predictable and uniform sample distribution, avoiding metric sparseness during low-traffic periods that distort rate-based error budget calculations in whitebox metrics.
4. **Declarative Kubernetes Integration**: Prometheus Operator CRDs (`Probe`) allow GitOps management of probe definitions alongside the application manifest repository.

## Defined SLOs and Alerting Design
- **Availability SLO**: 99.0% of synthetic HTTP probes return HTTP 2xx within a rolling 30-minute window (Error Budget: 1.0%).
- **Latency SLO**: 95.0% of successful HTTP probes complete in under 50ms (0.05s) within a rolling 30-minute window (Error Budget: 5.0%).
- **Multi-Window Multi-Burn-Rate Alerting**: Implementing Google SRE multi-window burn rate alerts:
  - Critical (Fast Burn): Burn rate > 14.4 across 2m and 10m windows with `for: 1m` duration.
  - Warning (Slow Burn): Burn rate > 3.0 across 5m and 30m windows with `for: 2m` duration.
  - *Evaluation Windows Note*: Windows are shortened for demonstration in this ephemeral reference platform; standard production values for a 30-day reference period would be 1h long / 5m short (for: 2m) for fast burn, and 6h long / 30m short (for: 15m) for slow burn.

## Network Security Group Adjustment for Intra-Cluster Probing
Under the AWS VPC CNI unencapsulated flat-network model, cross-node pod-to-pod traffic traverses EC2 node ENIs directly. The default upstream EKS module v20 node security group only authorizes ephemeral ports (1025-65535) and DNS (53), which blocks synthetic probes targeting standard HTTP port 80 when the probe pod and application pod reside on different nodes.

### Decision
We added rule `ingress_self_all` (`protocol = -1`, `from_port = 0`, `to_port = 0`, `self = true`) to `node_security_group_additional_rules` in Terraform, bringing the total Terraform resource count to 59 (Phase 1 and 2 had 58).
- **Scope Restriction**: The rule allows all node-to-node traffic across all protocols and ports where the source is strictly the node security group itself (`self = true`). Ingress is strictly confined to members of the node security group; no traffic from other VPC subnets or public CIDRs is admitted.
- **Deviation & Trade-off Analysis**: This rule is broader than strictly needed, as only TCP port 80 was required for synthetic probing. Kubernetes NetworkPolicies are not implemented on this cluster, so pod-level traffic segmentation is not enforced within the node security group boundary.

## Vendored Helm Charts
To ensure reliable, deterministic GitOps deployments without external network dependencies during cluster bootstrap, the upstream Helm charts are vendored directly in the repository under `monitoring/charts/` as pinned tarballs (`.tgz`):
- `kube-prometheus-stack-69.8.0.tgz`
- `prometheus-blackbox-exporter-11.22.0.tgz`

ArgoCD reconciles the monitoring stack directly from these vendored chart archives rather than pulling from external Helm registries at runtime.

## Kyverno Policy Exemption for Monitoring Namespace
The `monitoring` namespace is explicitly exempt from all three CEL-based Kyverno `ValidatingPolicy` definitions (`disallow-latest-tag`, `disallow-privileged-containers`, and `require-resource-limits`).

### Rationale
Third-party observability components packaged in `kube-prometheus-stack` require capabilities that conflict with strict workload policies:
1. `prometheus-node-exporter` requires host filesystem mounts and root/privileged access to collect node-level hardware metrics.
2. Operator sidecars and helper init containers (e.g., configmap-reloader and admission jobs) lack explicit CPU and memory resource limits in upstream defaults.
3. Upstream subcharts may use untagged or non-conforming image references.

Enforcing workload admission policies against the monitoring namespace would block operator reconciliation and daemonset scheduling. Workload security policies are therefore targeted strictly at application namespaces (`dev` and `staging`), leaving system and observability namespaces exempt.

## Consequences
### Positive
- Direct measurement of user-perceived availability and latency across the full cluster network path.
- Clean separation between application business logic and platform observability.
- Rapid detection of network regressions, security group misconfigurations, and DNS resolution issues.
- Fully offline, reproducible GitOps reconciliation using vendored chart tarballs.

### Negative
- Synthetic probes generate synthetic load on the application endpoints (minimal at 10s scraping intervals).
- Probing from within the cluster (node-to-node) does not account for external internet transit, ingress CDN latencies, or edge load balancer failures outside AWS VPC.
- The intra-node security group rule is broader than strictly required (allows all protocols/ports between nodes), and NetworkPolicies are not implemented to isolate pod-to-pod traffic.
- The monitoring namespace operates outside the admission controller policy boundary.