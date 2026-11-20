# EKS Reference Platform

> Note: This repository is a cloud engineering reference platform and portfolio project, not a production system.

A production-style Kubernetes reference platform on AWS EKS provisioned with Terraform.

## Implementation Status

| Capability | Scope / Components | Status |
| :--- | :--- | :--- |
| Cluster & Infrastructure | Dedicated VPC (2 AZs) and EKS v1.37 via Terraform | Done (Phase 1) |
| CI/CD & Governance | OIDC-federated GitHub Actions CI, Pod Identity, Kyverno | Planned |
| GitOps & Delivery | Helm application packaging, ArgoCD app-of-apps | Planned |
| Observability | Prometheus, Grafana, alerts, 2 SLO definitions | Planned |

## Architecture Highlights (Phase 1)
- **VPC & Networking**: Dedicated VPC with 2 Availability Zones in ap-south-1, isolated public and private subnets, and a single shared NAT Gateway for cost-conscious egress.
- **EKS Cluster**: Kubernetes v1.37 provisioned via Terraform AWS EKS module v20, with endpoint public access strictly limited to operator CIDR.
- **Worker Compute**: Managed Node Group utilizing EC2 Spot instances (t3.large) across private subnets.
- **Add-ons**: CoreDNS, kube-proxy, VPC CNI, and EKS Pod Identity Agent.
- **Security & Governance**: KMS envelope encryption, dedicated cluster and node security groups, IAM roles created by the EKS module using AWS managed policies.

## Architectural Decision Records (ADRs)
- [ADR 0001: Managed Node Groups](docs/adr/0001-managed-node-groups.md)
- [ADR 0002: Single NAT Gateway](docs/adr/0002-single-nat-gateway.md)
- [ADR 0003: Spot Instances for Worker Nodes](docs/adr/0003-spot-instances-for-worker-nodes.md)
- [ADR 0004: Restricted Public API Endpoint](docs/adr/0004-restricted-public-api-endpoint.md)
- [ADR 0005: Kubernetes Version Selection](docs/adr/0005-kubernetes-version-selection.md)
