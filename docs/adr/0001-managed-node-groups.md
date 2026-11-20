# ADR 0001: Use EKS Managed Node Groups for Worker Nodes

## Status
Accepted

## Date
2026-11-20

## Context
Running worker nodes in AWS EKS requires selecting an orchestration and provisioning model. The primary options are:
1. Self-managed EC2 instances configured with custom AMIs and Auto Scaling Groups.
2. AWS Fargate (serverless pods).
3. EKS Managed Node Groups (MNG).
4. Karpenter just-in-time autoscaling.

The goal of Phase 1 is to establish a solid, stable baseline cluster with automated node lifecycle management, minimal operational overhead, and native AWS API integration.

## Options Considered
- **Self-managed EC2 nodes**: Offers maximum control over OS packages, boot scripts, and volume attachments. However, node draining, rolling updates, AMI version tracking, and security patching require custom scripts or complex orchestration tooling.
- **AWS Fargate**: Eliminates EC2 server management entirely, but restricts DaemonSets (precluding standard node-level monitoring agents and certain CNI plugins) and incurs higher per-pod compute costs for continuous workloads.
- **Karpenter**: Highly efficient for dynamic production scaling, but introduces additional moving parts and controller dependencies before core cluster infrastructure is established.
- **EKS Managed Node Groups**: AWS manages EC2 provisioning, AMI updates, graceful node draining via Kubernetes Eviction API during updates, and Auto Scaling Group registration.

## Decision
We chose EKS Managed Node Groups using standard Amazon Linux 2023 EKS-optimized AMIs. Node groups are provisioned in private subnets with automated termination lifecycle hooks and managed rolling upgrade capabilities.

## Consequences
### Positive
- Fully declarative configuration through Terraform `terraform-aws-modules/eks/aws`.
- Automated rolling updates with node draining are expected to reduce service disruptions during cluster maintenance.
- Out-of-the-box integration with AWS IAM, security groups, and CloudWatch.

### Negative
- Less flexibility for deep kernel customizations compared to self-managed nodes.
- Fixed instance lifecycle timing compared to Karpenter rapid provisioning.
