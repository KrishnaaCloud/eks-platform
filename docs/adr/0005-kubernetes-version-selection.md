# ADR 0005: Selection of Kubernetes Version 1.37

## Status
Accepted

## Date
2026-11-20

## Context
AWS EKS clusters should run on an actively maintained Kubernetes version under STANDARD_SUPPORT to avoid AWS Extended Support surcharges. Amazon EKS clusters running on a Kubernetes version in extended support are charged $0.60 per cluster per hour (replacing the standard $0.10 per cluster per hour rate).

Querying the EKS cluster versions API (`aws eks describe-cluster-versions`) on 2026-11-20 returned:
- Version 1.37: Status `STANDARD_SUPPORT` (Released: 2026-10-01, Standard Support ends: 2027-12-01). Default AWS EKS version.
- Version 1.36: Status `STANDARD_SUPPORT` (Released: 2026-06-02, Standard Support ends: 2027-08-02).
- Version 1.35: Status `STANDARD_SUPPORT` (Released: 2026-01-27, Standard Support ends: 2027-03-27).
- Version 1.34: Status `STANDARD_SUPPORT` (Released: 2025-10-02, Standard Support ends: 2026-12-02).
- Versions 1.31-1.33: Status `EXTENDED_SUPPORT` (incurs $0.60/cluster/hour).

## Options Considered
- **Kubernetes 1.34 / 1.35**: Mature versions with long field history, but standard support expires in late 2026 or early 2027.
- **Kubernetes 1.37**: The newest available version with the longest standard support lifecycle (through December 2027) and designated by AWS as `defaultVersion`.

## Decision
We selected Kubernetes version `1.37` (`TF_VAR_kubernetes_version="1.37"`).

Measured verification: On 2026-11-20, all four cluster add-ons (`coredns`, `kube-proxy`, `vpc-cni`, `eks-pod-identity-agent`) and both worker nodes reached `Ready` / `ACTIVE` status on Kubernetes 1.37.1 with zero manual workarounds.

## Consequences
### Positive
- Operates under standard EKS pricing ($0.10/cluster-hour) without extended support surcharges.
- Longest operational lifecycle without requiring a major cluster upgrade until December 2027.

### Negative
- Some legacy third-party Helm charts may have deprecated API dependencies; all charts must be verified for 1.37 compatibility prior to deployment.
