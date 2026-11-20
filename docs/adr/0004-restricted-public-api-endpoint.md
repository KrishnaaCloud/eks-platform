# ADR 0004: Restricted Public EKS Cluster API Endpoint

## Status
Accepted

## Date
2026-11-20

## Context
The Kubernetes API server endpoint (`https://<cluster-endpoint>.eks.amazonaws.com`) requires access from:
1. Operator workstation for Terraform, `kubectl`, Helm, and management operations.
2. In-cluster worker nodes communicating with the control plane.
3. Future GitHub Actions CI runners.

Exposing the EKS API endpoint publicly with `0.0.0.0/0` leaves the Kubernetes API vulnerable to credential brute-forcing, zero-day CVE exploits, and unsolicited scans.

## Options Considered
- **Public `0.0.0.0/0`**: Simplest connectivity from anywhere, but fails standard security and compliance benchmarks (CIS AWS Benchmark, AWS Well-Architected Security Pillar).
- **Private-only endpoint**: Completely secure from the public internet, but requires a Bastion host, AWS Client VPN, or Direct Connect to execute administrative commands.
- **Restricted Public Endpoint + Private Access**: Cluster endpoint public access is enabled but restricted via CIDR allowlist to the operator's current IP address (`<my_ip>/32`). Worker nodes communicate with the control plane privately via intra-VPC ENIs.

## Decision
We implemented a restricted public endpoint (`cluster_endpoint_public_access = true`, `cluster_endpoint_public_access_cidrs = [var.my_ip_cidr]`) combined with private endpoint access inside the VPC.

## Consequences
### Positive
- Complies with principle of least privilege: the API server rejects any traffic originating from unauthorized IP addresses at the AWS networking layer.
- Direct workstation management without needing costly VPN infrastructure or bastion jump hosts.
- Node-to-control-plane traffic remains strictly within the VPC private subnets.

### Negative
- Changing operator internet connections (e.g. ISP IP rotation or mobile hotspot) requires updating `my_ip_cidr` via Terraform or CLI before access is restored.
