# Instructor presentation notes

## Business and architecture

“My proposed application is an Enterprise Mobility Request Portal. Enterprise administrators submit new-line, line-closure and device-replacement requests. I focus on a new line with a device delivered to an approved business address.

The portal's microservices run on EKS. The request service stores the original JSON in S3. An S3 event invokes validation Lambda, which creates a DynamoDB request record. The account manager approves or rejects inside the application.

DynamoDB Streams captures the decision. The integration Lambda creates a ServiceNow request only for the authorized transition to approved. ServiceNow coordinates line provisioning, device allocation and shipping. Rejected requests create no fulfilment tickets.

ServiceNow sends authenticated status callbacks through API Gateway. A callback Lambda updates DynamoDB; ServiceNow does not directly access the database. The portal displays the current progress.

If asynchronous ingestion fails after retries, the failed event reaches an SQS DLQ. CloudWatch detects the backlog and SNS notifies support. Normal form validation errors and business rejection are handled separately.”

## Infrastructure delivery

“I use short-lived branches into protected main. Terraform PR checks validate environment configuration and run linting. The implemented dev deployment is manually triggered: it generates a saved plan, stores it in S3 and uses a separate apply job to verify and apply that same plan.

Each environment has independent state. We promote reviewed code versions, not plans or state. The proposed production process uses a fresh environment plan, authorized release approval and a staffed change window. A failed infrastructure change requires inspecting actual state and preparing an approved recovery plan.”

## Evidence boundary

“My implemented work demonstrates the Terraform/EKS delivery foundation and operations labs. A separate serverless lab demonstrates S3/Lambda/DynamoDB ingestion and alerts. The telecom schema, approval and end-to-end ServiceNow integration are proposed extensions. The EKS cluster has been destroyed; screenshots are historical evidence.”
