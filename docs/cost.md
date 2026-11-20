# Cost Observations and Architecture Economics

## Reference Cost Model (ap-south-1)

| Component | Sizing / Specification | Unit Pricing (USD) | Estimated Hourly Burn |
| :--- | :--- | :--- | :--- |
| EKS Control Plane | 1 cluster (Standard Support v1.37) | $0.10 / cluster-hour | ~$0.100 |
| NAT Gateway | 1 single NAT Gateway | $0.045 / hour + $0.045/GB | ~$0.045 |
| EC2 Spot Worker Nodes | 2x t3.large (Spot, ap-south-1) | ~$0.025 / instance-hour | ~$0.050 |
| Elastic IP | 1 attached EIP | $0.005 / hour | ~$0.005 |
| EBS Volumes | 2x 20 GiB gp3 root volumes | ~$0.08 / GB-month | <$0.001 |
| **Total Estimated Burn** | | | **~$0.20 / hour (~16-18 INR/hour)** |

## Guardrails
- **Budget Alerts**: Account budget `eks-platform-monthly` configured with a 6.00 USD monthly threshold with email alerts at 50% actual, 80% actual, and 100% forecasted spend.
- **Session Lifecycle**: Platform is provisioned for active engineering sessions and destroyed at session conclusion to avoid unattended overnight charges.
