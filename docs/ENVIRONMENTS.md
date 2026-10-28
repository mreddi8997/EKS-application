# Infrastructure environments

The same core infrastructure pattern is reused through environment directories. **Production readiness differs in more than scale:** availability, identities, data, integrations, monitoring and recovery also matter.

## Current configuration

| Directory | Resource environment value | VPC CIDR | Nodes | RDS class | S3 state-key suffix |
|---|---|---|---|---|---|
| dev | `dev` | `10.10.0.0/16` | t3.small, min 2 / desired 2 / max 4 | db.t3.micro | `dev/terraform.tfstate` |
| test | `test` | `10.20.0.0/16` | t3.small, min 2 / desired 2 / max 4 | db.t3.micro | `test/terraform.tfstate` |
| staging | `staging` | `10.30.0.0/16` | t3.small, min 2 / desired 2 / max 4 | db.t3.micro | `staging/terraform.tfstate` |
| production | `prod` | `10.40.0.0/16` | t3.small, min 2 / desired 2 / max 4 | db.t3.micro | `prod/terraform.tfstate` |

All shown state keys have the existing `terraform-backend-mohit/` prefix in the `terraform-backend-mohit` bucket, in `us-east-2`. Backends enable encryption and native S3 locking. Distinct state keys do not establish account separation.

The production directory and GitHub environment are named `production`, while the Terraform resource environment value and backend suffix use `prod`. This is existing configuration, not a migration instruction.

**Current sizing is identical across environments.** Do not describe production as larger or highly available solely because it has a production directory. The RDS module does not currently expose/configure Multi-AZ or deletion protection in the inspected resource. Production EKS configuration also differs in creator-admin access, which requires explicit review.

## Intended role of each environment

| Environment | Purpose | Target controls |
|---|---|---|
| Dev | Infrastructure integration and troubleshooting | Synthetic data, scoped role, reviewed changes |
| Test | Validate infrastructure changes and failure cases | Sandbox integrations, separate state and resource identities |
| Staging | Rehearse the selected production change | Production-like behaviour, release approval and documented verification |
| Production | Approved operational service | Separate account, least privilege, resilience, recovery and support controls |

The dev EKS API is configured private. Kubernetes checks require both network access and authorized EKS access; AWS OIDC authentication alone does not create VPC connectivity.

## Production design targets, not current guarantees

- Separate production AWS account, credentials, secrets and operational access.
- Capacity and Availability Zone placement based on workload and failure requirements.
- RDS Multi-AZ, backups, tested restore, appropriate retention and deletion protection.
- HTTPS, enterprise identity integration and tenant-level authorization.
- Live ServiceNow integrations isolated from non-production/sandbox integrations.
- Agreed alert thresholds, escalation and recovery objectives.

## Deployment status

Historical dev deployment evidence exists. The owner subsequently destroyed the EKS/Argo CD lab. Test, staging and production directories demonstrate configuration, not live deployed environments. This documentation does not verify current AWS resource inventory or Terraform state freshness.

Apply only after reviewing the target environment's fresh plan. Promoting a code version never means copying dev's state or saved plan into another environment.
