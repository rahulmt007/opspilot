# Architecture and cost envelope

## Goals

OpsPilot demonstrates an agentic DevOps control plane while keeping the workload reproducible on a laptop and disposable in AWS. The agent is an orchestrator, not a general-purpose remote shell: it maps intents to reviewed actions, produces dry runs, requires approval for mutations, and records normal command output for auditability.

## Deployment profiles

| Profile | Runtime | Purpose | Expected cloud cost |
|---|---|---|---|
| Local | Docker Compose | app + Prometheus + Grafana demo | $0 AWS |
| CI | GitHub Actions + kind | tests, scans, Kubernetes rollout | $0 for standard runners in a public repo; quotas apply otherwise |
| AWS showcase | one EC2 + VPC + public IPv4 + EBS | ephemeral public demo | non-zero; intended for hours, not continuous use |
| Managed Kubernetes | EKS | future/paid extension only | excluded from free-first baseline |

AWS changed its new-customer Free Tier on July 15, 2025. New accounts may receive credits and a six-month free plan; older accounts remain on the legacy program. Eligibility is account-specific. Therefore the infrastructure makes no claim that EC2 or IPv4 is universally free.

## AWS design

The baseline has one VPC, one public subnet, an internet gateway, a security group, an encrypted gp3 root disk, an IMDSv2-only EC2 instance, and an AWS Budget. There is no NAT Gateway, load balancer, managed database, EKS cluster, or DNS zone. Public IPv4 and compute can incur charges. Keep the target alive only for a demo, then destroy it.

The example opens port 8000 publicly so a recruiter can view the demo. SSH is closed unless the operator supplies a `/32` CIDR and key. Production would add TLS, private subnets, SSM/VPC endpoints, a load balancer, multiple instances, WAF, and persistent remote Terraform state; those choices conflict with this project's tiny showcase budget.

## Agent security model

- Dry-run is the default and must be explicitly disabled.
- Commands use fixed argument arrays with `shell=False`.
- Only Docker, kubectl, kind, Terraform, and read-only Git actions are admitted.
- Natural-language tool calls omit `apply` and `destroy`; those remain direct CLI operations.
- Destructive operations require approval; CI uses a protected GitHub Environment.
- GitHub-to-AWS authentication uses short-lived OIDC credentials, not stored access keys.
- Containers run without root, Linux capabilities, privilege escalation, or a writable root filesystem.
- CI scans source/style, container vulnerabilities, and Terraform misconfiguration.

## Rollback and recovery

Kubernetes uses rolling deployments, readiness/liveness probes, and `kubectl rollout undo`. The EC2 path should deploy immutable image tags in the next phase; rollback then becomes switching the tag to the previous digest. Terraform is the lifecycle authority for AWS teardown. State must not be committed.

## Cost checklist before apply

1. Confirm whether the account is new Free Tier, legacy Free Tier, or fully paid.
2. Inspect `terraform plan` and the region's current EC2, EBS, data-transfer, and IPv4 rates.
3. Set a low `budget_usd`, verified notification email, owner, and near-term `expires_at`.
4. Use a dedicated least-privilege OIDC role and a protected `aws-showcase` environment.
5. Run `terraform destroy` immediately after the demo and verify the AWS console/billing dashboard.

Budgets notify; they do not automatically stop resources. TTL tags are evidence and automation inputs, not an automatic deletion guarantee.
