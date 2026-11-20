# Cost Observations and Architecture Economics

## Reference Cost Model (ap-south-1)

Assumed USD to INR exchange rate: 1 USD = 84.00 INR (estimate).
Exclusions: Data transfer fees, KMS key usage requests, and CloudWatch log ingestion/storage are excluded from this baseline estimate.

| Component | Sizing / Specification | Unit Pricing (USD) | Estimated Hourly Burn |
| :--- | :--- | :--- | :--- |
| EKS Control Plane | 1 cluster (Standard Support v1.37) | $0.10 / cluster-hour (list price) | ~$0.100 |
| NAT Gateway | 1 single NAT Gateway | $0.045 / hour (list price, idle) | ~$0.045 |
| EC2 Spot Worker Nodes | 2x t3.large (Spot, ap-south-1) | Measured: $0.0364 - $0.0386 / hr (2026-11-20) | ~$0.075 |
| Elastic IP | 1 attached EIP | $0.005 / hour (list price) | ~$0.005 |
| EBS Volumes | 2x 20 GiB gp3 root volumes | ~$0.08 / GB-month (list price) | <$0.001 |
| **Total Estimated Burn** | | | **~$0.226 / hour (~19 INR/hour)** |

*Spot price measured via `aws ec2 describe-spot-price-history --instance-types t3.large --product-descriptions "Linux/UNIX"` on 2026-11-20: ap-south-1a ($0.0364/hr), ap-south-1b ($0.0386/hr).

## Guardrails
- **Budget Alerts**: Account budget `eks-platform-monthly` configured with a 6.00 USD monthly threshold with email alerts at 50% actual, 80% actual, and 100% forecasted spend.
- **Session Lifecycle**: Platform is provisioned for active engineering sessions and destroyed at session conclusion to avoid unattended overnight charges.

## Observed Cost
- Status: Pending Cost Explorer data ingestion, expected 2026-11-21.
