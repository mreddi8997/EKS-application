# Project Deliverables

## 1. Terraform Infrastructure and Dev Deployment

Repository: https://github.com/mreddi8997/EKS-application

Terraform configuration is organized into dev, test, staging, and
production environment directories, with shared VPC and RDS modules.
The EKS configuration uses the upstream Terraform EKS module.

The dev environment was deployed in AWS us-east-2 using GitHub Actions.
The workflow generates a saved Terraform plan, stores it in S3,
requires approval through the dev-apply environment, and applies
the saved plan.

### Terraform structure

![Terraform environments](screenshots/Terraform-code.png)

![Environment files and shared modules](screenshots/terraform-strt.png)

### Successful deployment pipeline

![Planning job and saved-plan upload](screenshots/github-actions-apply-terraform.png)

![Successful plan and apply with deployment approval](screenshots/terraform-dev-appy.png)

### Running EKS cluster

The eks-application-dev cluster is Active and runs Kubernetes 1.35.
At the time of capture, the console reported nine nodes and one
node group.

![Active EKS cluster](screenshots/eks-cluster.png)

![Cluster workload status](screenshots/eks-cluster-2.png)

### Remote Terraform state

Dev Terraform state is stored at:

s3://terraform-backend-mohit/terraform-backend-mohit/dev/terraform.tfstate

![Dev state object in S3](screenshots/terrafrom-s3-statefile.png)

### Remaining evidence

- Managed node group status and scaling configuration.
- Terraform apply resource summary.
- Verification of the Terraform-managed ECR repository requirement.

Only the dev deployment is evidenced here. The presence of other
environment directories does not demonstrate deployment to those environments.
