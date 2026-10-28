# Responsibilities and collaboration

This is the proposed team model for the Enterprise Mobility Request Portal. It does not claim that all teams participated in the portfolio lab or describe Rogers' actual organization.

## Business and fulfilment teams

| Participant | Responsibility |
|---|---|
| Enterprise mobility administrator | Submit permitted requests, supply correct employee/device/address data and track progress |
| Account manager | Approve/reject inside the portal according to account authority and policy |
| Line/provisioning team | Entitlement checks, connection provisioning and activation outcome |
| Asset team | Device reservation, allocation and device/SIM references |
| Shipping team | Dispatch to approved destination and report shipping/tracking outcome |
| Service owner/business analyst | Define eligibility, task dependencies, exceptions and acceptance criteria |

## Engineering and delivery teams

| Participant | Responsibility |
|---|---|
| Application developers | Request validation, approval rules, tenant authorization, APIs and event contracts |
| Cloud/platform engineer | Terraform modules, network/EKS/RDS configuration, OIDC workflow access, infrastructure checks and recovery evidence |
| Serverless/integration developer | S3 handlers, DynamoDB transitions, duplicate-safe ServiceNow calls and authenticated callbacks |
| ServiceNow team | Catalog offering, fulfilment task routing, correlation fields and outbound status automation |
| QA | Valid/invalid input, approved/rejected outcomes, duplicate events, partial failures and business acceptance |
| Security/IAM | Approval/access boundaries, secret handling, data protection and permission review |
| Release manager | Select infrastructure revision, coordinate evidence, approvals and release window |
| Operations/support | Alert response, log investigation, failed-event triage, controlled replay and escalation |

An independent authorized reviewer should approve sensitive infrastructure plans in the target team model. The lab's current required PR approval count is zero, so do not present separation of duties as already enforced.

## Candidate's individual contribution

The documented hands-on contribution is the infrastructure/delivery foundation: Terraform environment layout and modules, GitHub Actions validation and saved-plan deployment, plus historical EKS/Helm/Argo CD operations, monitoring, load tests and network-policy troubleshooting. The separate serverless lab demonstrates S3/Lambda/DynamoDB request processing, lookup and failure alerting.

The telecom request schema, in-application approval and complete ServiceNow integration are the proposed application of those patterns. They are not implemented by renaming the existing sample code.

## Collaboration examples

- Agree with developers on account/product references, approval state transitions and event schema before integration work.
- Agree with ServiceNow owners on the catalog API, task dependencies, correlation identifiers and callback authentication.
- Review infrastructure changes with platform/security owners and include actual plan impact in the release record.
- Test the negative path: rejection must not create tickets; retry must not create duplicates; a missed callback must be reconcilable.
- During an incident, support preserves evidence, platform investigates AWS health/permissions, developers inspect handlers, and the service owner verifies business recovery.
