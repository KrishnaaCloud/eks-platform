# ADR 0003: Spot Instances for Worker Nodes

## Status
Accepted

## Date
2026-11-20

## Context
Worker nodes provide the compute capacity for core Kubernetes system components (CoreDNS, kube-proxy, VPC CNI, AWS Pod Identity Agent) and future platform workloads (ArgoCD, Prometheus, Grafana, sample microservices).

Balancing cost control on a personal AWS development account with sufficient CPU and memory headroom is required. Small instances (e.g. `t3.small` or `t3.medium`) quickly run into pod density limits imposed by AWS VPC CNI ENI allocation rules and memory pressure under observability stacks.

Pod limits are calculated using the AWS VPC CNI max-pods formula: `N * (M - 1) + 2`, where `N` is the number of network interfaces (ENIs) and `M` is the number of IPv4 addresses per interface.
- `t3.medium` (3 ENIs, 6 IPs/ENI): `3 * (6 - 1) + 2 = 17` pods (calculated, not measured).
- `t3.large` (3 ENIs, 12 IPs/ENI): `3 * (12 - 1) + 2 = 35` pods (calculated, not measured).

## Options Considered
- **On-Demand `t3.medium` (2 vCPU, 4 GiB)**: Low risk of interruption, but constrained memory limits and lower pod capacity (17 pods calculated). Cost: ~$0.0416/hr list price estimate.
- **Spot `t3.large` (2 vCPU, 8 GiB)**: Provides double the memory and higher pod capacity (35 pods calculated) at a significant discount. Measured Spot price on 2026-11-20: $0.0364/hr (ap-south-1a) and $0.0386/hr (ap-south-1b).
- **Graviton (`t4g.large`) Spot**: Competitive cost, but requires arm64 multi-arch container image validation for all third-party Helm charts.

## Decision
We selected `t3.large` instances configured with `capacity_type = "SPOT"`, with a minimum of 1, desired count of 2, and maximum of 3 instances.

## Consequences
### Positive
- Substantial cost reduction while maintaining 16 GiB of cluster memory across two nodes, expected to provide sufficient headroom for Prometheus, Grafana, and ArgoCD.
- Higher pod density per node supported by the AWS VPC CNI.
- Demonstrates handling of Spot lifecycle patterns and Kubernetes rescheduling resilience.

### Negative
- Subject to AWS 2-minute interruption notices if capacity is reclaimed. Interruption impact is expected to be mitigated in multi-node setups by Kubernetes pod eviction and replica distribution.
