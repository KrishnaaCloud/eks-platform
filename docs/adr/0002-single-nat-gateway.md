# ADR 0002: Provision a Single NAT Gateway for Egress

## Status
Accepted

## Date
2026-11-20

## Context
Worker nodes and internal cluster workloads reside in private subnets across two Availability Zones (AZs) in `ap-south-1`. These nodes require outbound internet connectivity to pull container images (from public registries like GitHub Container Registry and Docker Hub), download Helm charts, communicate with AWS service endpoints without VPC endpoints, and synchronize system clocks.

In AWS, NAT Gateways incur a fixed hourly charge (~$0.045/hour) plus per-GB data processing fees.

## Options Considered
- **One NAT Gateway per AZ (Multi-AZ HA)**: Standard AWS Well-Architected recommendation for high availability in mission-critical environments. If an AZ experiences a NAT gateway impairment, traffic in other AZs is unaffected. Cost: ~$65/month for two NAT gateways idle.
- **Single Shared NAT Gateway across AZs**: Both private subnets route internet-bound traffic through a single NAT Gateway located in public subnet A. Cost: ~$32.50/month (~15-20 INR/hour total cluster burn rate).
- **NAT Instance (t4g.nano/micro)**: Lowest dollar cost, but requires self-managing iptables, source/destination check disabling, OS patching, and lack of automatic failover.

## Decision
We provisioned a single NAT Gateway (`single_nat_gateway = true`, `one_nat_gateway_per_az = false`) deployed into the primary public subnet.

## Consequences
### Positive
- Halves NAT gateway infrastructure costs while providing full outbound internet functionality for all worker nodes and pods.
- Sufficient availability for a reference portfolio architecture with session-based teardowns.

### Negative
- Cross-AZ data transfer fees apply when private subnet B routes traffic through the NAT Gateway in AZ A.
- An outage of the primary AZ's public subnet halts outbound egress for workloads in both AZs until restored.
