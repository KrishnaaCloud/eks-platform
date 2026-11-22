# ADR 0006: Choosing EKS over ECS and Maintaining Local Terraform State in Phase 1-2

## Status
Accepted

## Date
2026-11-22

## Context
Two key architectural decisions underpin the early platform design:
1. Container Orchestration Platform: Choosing between AWS Elastic Container Service (ECS) and AWS Elastic Kubernetes Service (EKS).
2. Terraform State Backend: Choosing between remote backend (S3 bucket with DynamoDB state locking) and local state (`terraform.tfstate`).

## Part 1: EKS vs ECS
### Options Considered
- **AWS ECS (Fargate / EC2)**: AWS-native container orchestration with zero control plane hourly fee and lower cognitive overhead. However, ECS lacks standard Kubernetes primitives (Custom Resource Definitions, Admission Webhooks, Operator pattern) and cannot natively run CNCF GitOps tools like ArgoCD or policy engines like Kyverno.
- **AWS EKS**: Standard upstream Kubernetes hosted on AWS. Incurs a $0.10/cluster-hour fee and higher initial complexity, but provides native Kubernetes API compatibility and unlocks the CNCF ecosystem (ArgoCD, Kyverno, Prometheus/Grafana) and multi-cloud workload portability.

### Decision
We chose AWS EKS. The core objective of this project is demonstrating enterprise-grade GitOps delivery, declarative admission guardrails, and cloud-native observability standards, all of which rely on Kubernetes primitives provided by EKS.

## Part 2: Local Terraform State in Initial Phases
### Options Considered
- **Remote S3 + DynamoDB State**: Industry standard for multi-engineer teams and automated CI/CD pipelines. Provides encrypted versioning and distributed locking, but requires pre-provisioning storage resources and IAM permissions prior to cluster creation.
- **Local State (`terraform.tfstate`) with `.gitignore` Protection**: Zero external infrastructure dependencies. State resides strictly on the operator workstation and is completely excluded from version control via `.gitignore`.

### Decision
We maintained local Terraform state for Phase 1 and Phase 2. As a single-operator reference platform with session-based teardowns, there is no concurrent write contention. Storing state locally avoids bootstrapping overhead and extra cloud resources until OIDC-federated CI/CD automation is introduced in future phases.

## Consequences
### Positive
- Access to the full CNCF ecosystem for GitOps (ArgoCD) and admission policy enforcement (Kyverno).
- Zero remote backend infrastructure cost or chicken-and-egg dependency during early phases.
- Absolute isolation of sensitive state files from the public git repository via `.gitignore`.

### Negative
- EKS incurs a fixed $0.10/hour control plane charge compared to ECS zero-cost control plane.
- Local state is vulnerable to loss if workstation disk fails, mitigated by session-based teardowns where cluster is destroyed at the end of each work session.
