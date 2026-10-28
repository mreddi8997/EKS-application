# Enterprise Mobility Request Portal architecture

## Business scope

Enterprise mobility administrators manage connections and devices for their organization's employees. Portal categories include new lines, line closure, device replacement and request tracking. This design focuses on **new line + mobile device + delivery address**.

An administrator selects an eligible plan and device, provides the employee reference and an approved delivery address, and submits the request. An authorized account manager approves or rejects it inside the portal. Approved requests proceed to internal ServiceNow fulfilment; rejected requests do not create fulfilment tickets.

This is a proposed Rogers-context use case, not a representation of Rogers' actual internal implementation.

![Enterprise Mobility Request Portal](architecture/enterprise-mobility-request-portal.png)

[Editable SVG](architecture/enterprise-mobility-request-portal.svg)

## Microservice boundaries

| Service | Responsibility |
|---|---|
| UI and request API | Category navigation, form submission, request IDs and input validation |
| Account/catalog service | Tenant-scoped account context, eligible plans and device references |
| Approval business logic | Determine the authorized account manager, record decisions and enforce allowed transitions |
| Status API | Authorize each lookup and display request/fulfilment progress |
| Validation Lambda | Parse S3 submissions, validate schema and references, create tracking records |
| ServiceNow integration Lambda | Handle approval transitions and correlate downstream requests/tasks |
| Callback Lambda | Authenticate and validate status notifications and update the tracking record |

The approval logic resides in the EKS application. There is no separate external approval engine in this design. The retained retail sample is a deployment demonstrator, not an implementation of these telecom services.

## AWS service selection

| Service | Use |
|---|---|
| Route 53 | Resolve the portal hostname; DNS resolution is not an application proxy hop |
| Application Load Balancer + ACM | HTTPS entry point and routing to the EKS workloads |
| Amazon EKS | Independently operated request, account/catalog, approval and status services |
| RDS PostgreSQL | Relational account/product reference data used by portal services |
| Amazon S3 | Immutable original request documents and attachments |
| AWS Lambda | Asynchronous ingestion and short integration/callback tasks |
| DynamoDB | Authoritative request approval and fulfilment tracking state |
| DynamoDB Streams | Capture record transitions and drive approved-request integration |
| API Gateway | Authenticated endpoint for ServiceNow task-status callbacks |
| SQS DLQ | Retain failed ingestion events after asynchronous failure handling |
| CloudWatch + SNS | Logs, DLQ backlog alarm and notifications to support |
| Secrets Manager, IAM, KMS | Integration credentials, scoped service permissions and encryption |

ServiceNow is the external fulfilment system. SSO is provided through an approved enterprise identity integration. Neither is assumed to be deployed merely because it appears in the diagram.

## 1. Submission and ingestion

1. The user authenticates and the backend verifies the enterprise account they may manage.
2. The request API validates required input and account/product eligibility. Never trust a client-supplied `APPROVED` status.
3. It generates an immutable request ID, stores the original form JSON in S3, and acknowledges receipt rather than activation.
4. An S3 `ObjectCreated` notification invokes the validation Lambda asynchronously.
5. Lambda parses and validates the document, then conditionally creates the DynamoDB record as `PENDING_APPROVAL`.

S3 stores the original submitted data. DynamoDB stores current mutable status; do not repeatedly overwrite the original JSON as status changes. Duplicate ingestion must not reset an approved or completed request to pending.

## 2. Approval inside the application

The account manager uses the portal. Server-side logic checks authority, records actor/time/reason and conditionally changes `approval_status` from `PENDING_APPROVAL` to `APPROVED` or `REJECTED`. Do not let customer self-service callers write approval attributes.

Use separate attributes for approval and fulfilment:

```json
{
  "request_id": "MOB-1001",
  "request_type": "new_line_with_device",
  "approval_status": "APPROVED",
  "fulfilment_status": "NOT_STARTED",
  "servicenow_request_id": null
}
```

Configure DynamoDB Streams with old and new images. An event-source filter can select records whose new approval status is `APPROVED`; the handler must also check that this is the authorized transition from pending, not an unrelated update that retained the approved value.

| Record transition | Integration result |
|---|---|
| `PENDING_APPROVAL -> APPROVED` | Eligible to create the ServiceNow request |
| `PENDING_APPROVAL -> REJECTED` | No ServiceNow request or fulfilment tasks |
| Pending record insertion | No ServiceNow request |
| Shipping or other unrelated update | No new ServiceNow request |

The integration rechecks current authorization/state before a new external operation and uses durable operation identifiers. Define cancellation separately; a completed approval does not make an already executed external action reversible.

## 3. ServiceNow fulfilment

The integration submits one configured ServiceNow catalog offering and records the returned correlation identifiers. ServiceNow's configured fulfilment flow creates the parent request/requested item and the required child tasks:

| Team | Task |
|---|---|
| Line/provisioning | Check entitlement and provision or activate the new connection |
| Assets | Allocate the device and record device/SIM identifiers |
| Shipping | Dispatch the allocated device to the approved address and return tracking information |

Shipping waits for device allocation. Activation sequencing follows the agreed business policy. Eligible provisioning work may be automated; the design does not require a person to activate every valid line manually.

Streams processing is at least once. A conditional claim alone cannot prevent all duplicates if ServiceNow creates a request but the network response is lost. Reconcile by a stable external correlation field before retrying an uncertain create. Do not advertise end-to-end exactly-once delivery.

## 4. Returning progress to the portal

```text
ServiceNow task status changes
    -> configured outbound HTTPS callback
    -> API Gateway
    -> callback Lambda
    -> DynamoDB request/task status
    -> portal Status API reads and displays progress
```

ServiceNow does not directly access DynamoDB. The callback integration must be configured explicitly. Authenticate callbacks, verify ticket/request ownership, reject stale or invalid transitions, and reconcile periodically if a callback is missed.

Updating `fulfilment_status` must not retrigger approval ticket creation. The parent is complete only when all mandatory tasks have confirmed outcomes; creating tickets is not completion.

## 5. Failure handling

```text
S3-triggered validation Lambda processing error
    -> asynchronous retries exhausted / event expires
    -> SQS dead-letter queue
    -> CloudWatch alarm: ApproximateNumberOfMessagesVisible > 0
    -> SNS
    -> support notification
```

The DLQ holds the failed S3 invocation event/reference, not a copied backup of the JSON. Preserve the source object. Support inspects the failure, corrects the cause and explicitly reprocesses the request using duplicate-safe logic.

Normal form mistakes return user validation feedback. Account-manager rejection is a business outcome, not a DLQ incident. Unexpected ingestion failures use technical error handling. A CloudWatch alarm normally notifies on transition to `ALARM`, not individually for every message.

DynamoDB Streams integration errors use event-source-mapping retry/record-age limits, partial-batch handling and an appropriate on-failure destination. They do not inherit the S3 Lambda's asynchronous DLQ settings. Monitor external integration errors, stream iterator age and failure destinations separately.

## Security and operational support

- Enforce tenant/account ownership on every read and write.
- Keep EKS nodes and RDS private; use an authorized network path for the private EKS API.
- Authenticate approval actions and callback requests. Maintain an audit history.
- Use workload IAM identities and Secrets Manager; avoid embedded credentials.
- Encrypt data, restrict attachment access, redact employee/address details in logs and define retention.
- Correlate portal request IDs, Lambda logs and ServiceNow references.
- Alert on ingestion failures, stream backlog, failed integrations, overdue approvals and stale fulfilment.

## Implemented evidence and proposed work

The current Terraform covers VPC/EKS/RDS foundations. Historical operations evidence is in [LAB-EVIDENCE.md](LAB-EVIDENCE.md). The [serverless companion](https://github.com/mreddi8997/Serverless-Event-Driven-Data-Pipeline-on-AWS) demonstrates JSON ingestion, DynamoDB lookup and failure alerts for software-licence requests. Telecom schema, approved-transition integration and ServiceNow callbacks remain implementation work.

Technical references: [DynamoDB stream filtering](https://docs.aws.amazon.com/lambda/latest/dg/with-ddb-filtering.html), [Lambda asynchronous errors](https://docs.aws.amazon.com/lambda/latest/dg/invocation-async-error-handling.html), [ServiceNow catalog requests](https://www.servicenow.com/docs/r/servicenow-platform/service-catalog/c_RequestingAServiceCatalogItem.html).
