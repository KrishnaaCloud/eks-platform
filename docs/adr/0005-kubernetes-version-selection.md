# ADR 0005: Selection of Kubernetes Version 1.37

## Status
Accepted

## Date
2026-11-20

## Context
AWS EKS clusters should run on an actively maintained Kubernetes version under STANDARD_SUPPORT to avoid AWS Extended Support surcharges ($0.60/cluster/hour added to standard $0.10/cluster/hour).

Querying the EKS cluster versions API (`aws eks describe-cluster-versions`) returns:
- Version 1.37: Status `STANDARD_SUPPORT` (Released: 2026-10-01, Standard Support ends: 2027-12-01). Default AWS EKS version.
- Version 1.36: Status `STANDARD_SUPPORT` (Released: 2026-06-02, Standard Support ends: 2027-08-02).
- Version 1.35: Status `STANDARD_SUPPORT` (Released: 2026-01-27, Standard Support ends: 2027-03-27).
- Version 1.34: Status `STANDARD_SUPPORT` (Released: 2025-10-02, Standard Support ends: 2026-12-02).
- Versions 1.31-1.33: Status `EXTENDED_SUPPORT` (incurs high surcharges).

## Options Considered
- **Kubernetes 1.34 / 1.35**: Mature versions with long field history, but standard support expires in late 2026 or early 2027.
- **Kubernetes 1.37**: The newest available version with the longest standard support lifecycle (through December 2027), modern API primitives, and designated by AWS as `defaultVersion`.

## Decision
We selected Kubernetes version `1.37` (`TF_VAR_kubernetes_version="1.37"`).

## Consequences
### Positive
- Zero risk of unexpected AWS Extended Support billing surcharges.
- Longest operational lifecycle without requiring a major cluster upgrade.
- Access to the latest Kubernetes features, performance enhancements, and security patches.

### Negative
- Some legacy third-party Helm charts may have deprecated API dependencies; all charts must be verified for 1.37 compatibility prior to deployment.
