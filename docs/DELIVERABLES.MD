# Project scope and evidence

## Enterprise Mobility Request Portal deliverables

| Deliverable | Evidence/status |
|---|---|
| Telecom business use case | [Architecture](ARCHITECTURE.md): new line, device allocation and delivery |
| Presentation architecture | [PNG](architecture/enterprise-mobility-request-portal.png) and [editable SVG](architecture/enterprise-mobility-request-portal.svg) |
| Approval-driven integration design | In-application decision -> DynamoDB transition -> Streams/Lambda -> ServiceNow |
| Status return design | ServiceNow -> authenticated API Gateway -> callback Lambda -> DynamoDB |
| Failure-handling design | Failed ingestion -> SQS DLQ -> CloudWatch -> SNS -> support |
| IaC source | Existing VPC/RDS modules and four environment roots under `Infra/` |
| Terraform workflow documentation | [Terraform delivery](TERRAFORM-DELIVERY.md), aligned with existing workflow files |
| Release/team documentation | [Release strategy](RELEASE.md), [environments](ENVIRONMENTS.md), [teams](TEAMS.md) |

## Demonstrated implementation

- Historical dev VPC/EKS infrastructure deployment and Terraform state evidence.
- Dev saved-plan deployment workflow with same-commit checkout and checksum verification.
- PR validation/TFLint; formatting and Checkov are currently advisory.
- Historical deployment of sample microservices, monitoring dashboards, HPA experiments and network-policy troubleshooting.
- The [separate serverless repository](https://github.com/mreddi8997/Serverless-Event-Driven-Data-Pipeline-on-AWS) implements a software-licence request lab using S3 -> Lambda -> DynamoDB and a lookup API, with asynchronous failure retention and alerting.

The owner subsequently destroyed the EKS/Argo CD lab. [Historical lab evidence](LAB-EVIDENCE.md) describes state at capture, not current live availability. No infrastructure inventory or current state reconciliation is claimed by this documentation update.

## Proposed implementation / remaining work

- Telecom-specific form schema, account/product eligibility and tenant authorization.
- Account-manager approval inside the application with audit history and conditional state changes.
- DynamoDB Streams integration filtering, duplicate-safe external creation and reconciliation.
- Configured ServiceNow catalog tasks and authenticated status callbacks.
- Terraform coverage for the complete serverless path in this repository.
- Cross-environment saved-plan apply/release-ref workflows and infrastructure health gates.
- Production RDS resilience/recovery and independent approval policy.
- Commit reviewed workload/monitoring configuration needed to reproduce the historical EKS setup.

The retail sample remains under its existing path as the microservices demonstrator. Existing application/image experiments are preserved but excluded from this presentation's CI/CD description, which is Terraform-only.
