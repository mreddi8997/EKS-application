# Retail Microservices on Amazon EKS

An EKS lab deploying five retail microservices with Terraform, Helm, Argo CD, GitHub Actions, and Kubernetes monitoring.

## Implemented scope

- Terraform dev infrastructure in AWS us-east-2: VPC, EKS managed nodes, IAM configuration, and RDS configuration.
- S3 Terraform state and an approval-gated saved-plan deployment workflow.
- UI, catalog, cart, checkout, and orders deployed through separate Argo CD Applications.
- UI exposure through an ALB; backend Services are internal.
- HPA load-test evidence, Prometheus/Grafana dashboards, and CloudWatch evidence.
- Checkout egress policy allowing orders and DNS, with allowed/blocked connectivity evidence.
- UI CI builds commit-tagged Docker Hub images. Image selection and promotion are manual.

Only dev is evidenced as deployed. Test, staging, and production Terraform directories are configuration, not proof of deployed environments. The application currently uses in-memory persistence; the RDS configuration does not establish that application data is stored in RDS.

## Repository layout

| Path | Purpose |
|---|---|
| `Infra/environments/` | dev, test, staging, and production Terraform configuration |
| `Infra/modules/` | Shared VPC and RDS modules |
| `.github/workflows/` | Infrastructure and per-service CI workflows |
| `retail-store-sample-app/src/<service>/chart/` | Service Helm charts |
| [docs/DELIVERABLES.MD](docs/DELIVERABLES.MD) | Deployment evidence and completion checklist |
| [docs/RELEASE.md](docs/RELEASE.md) | Build, manual image promotion, and rollback procedure |
| [Monitoring incident](docs/incident%20troubleshooting) | Investigation and observed recovery |
| [Dashboard JSON](docs/dashboards/kubernetes-cluster-6417.json) | Exported Grafana dashboard |

## Prerequisites and cluster access

Use AWS CLI, Terraform 1.10 or newer below 2.0, kubectl, Helm, and an authorized AWS identity. The committed provider lock files determine provider versions.

The dev EKS API endpoint is private. Run Kubernetes and Helm commands from a host with network access to the VPC and an authorized EKS access entry.

```bash
git clone https://github.com/mreddi8997/EKS-application.git
cd EKS-application
aws sts get-caller-identity
aws eks update-kubeconfig --region us-east-2 --name eks-application-dev
kubectl get nodes
kubectl get pods -A
```

## Infrastructure deployment

The existing S3 backend is configured in `Infra/environments/dev/backend.tf`. The bucket, GitHub OIDC roles, and GitHub environment configuration must exist before running the deployment workflow.

For local review:

```bash
terraform -chdir=Infra/environments/dev init -lockfile=readonly
terraform -chdir=Infra/environments/dev validate
terraform -chdir=Infra/environments/dev plan
```

For the repository deployment process:

1. Open Actions → Terraform Dev Deployment → Run workflow on main.
2. Leave apply disabled for a plan-only review.
3. To deploy, run with apply enabled and review the generated saved plan.
4. Approve the dev-apply environment when the plan is acceptable.
5. The apply job downloads and checks the saved plan before applying it.

Configure GitHub environments `dev` and `dev-apply` with `AWS_ROLE_ARN` and `AWS_REGION`. Configure required reviewers for dev-apply. The workflow uses OIDC rather than static AWS access keys.

## Helm and Argo CD

Argo CD renders the service Helm charts and owns application reconciliation. Do not install a second Helm-managed copy over the same Argo CD-managed resources.

Inspect existing configuration before making changes:

```bash
kubectl get applications -n argocd
helm list -A
helm lint retail-store-sample-app/src/ui/chart
helm template ui retail-store-sample-app/src/ui/chart --namespace ui
```

For a separate lab installation, the following is a command pattern, not an export of the live deployment:

```bash
helm upgrade --install ui retail-store-sample-app/src/ui/chart \
  --namespace ui-lab --create-namespace \
  --values /path/to/reviewed-ui-values.yaml
```

The values must supply the intended image, cross-namespace service endpoints, ingress, and scaling settings. Live Application definitions and environment values were entered through Argo CD and are not yet fully committed. Export and review them before claiming a reproducible deployment from Git alone.

## Monitoring installation

Prometheus and Grafana were installed using kube-prometheus-stack. Before changing the existing release, record its name, chart version, values, PVCs, and storage configuration:

```bash
helm list -n monitoring
kubectl get pods,pvc -n monitoring
kubectl get storageclass
```

For a fresh lab, the installation command pattern is:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --version <reviewed-chart-version> \
  --values /path/to/reviewed-monitoring-values.yaml
```

Replace the placeholders with reviewed settings. This is not a reconstruction of the original install command. The current persistent storage and node-exporter ServiceMonitor settings still need export into Git.

## CI and releases

See [the release guide](docs/RELEASE.md) for workflow triggers, required secrets, manual promotion, and rollout verification.

The UI workflow validates pull requests and publishes SHA-tagged images only from main. Other microservice workflows retain their existing manual triggers and run-number tags. No automated image-update bot is configured.

## Evidence

![Retail application](docs/screenshots/retail-ui.png)

![Grafana pod metrics](docs/screenshots/grafana-pod-metrics.png)

![HPA load test](docs/screenshots/hpa-scaling.png)

The complete evidence set is in [Project Deliverables](docs/DELIVERABLES.MD). Screenshots describe the state at capture time and do not confirm current live availability.

## Remaining acceptance gaps

- Original requirements specify ECR and a k8s/ directory; this project currently uses Docker Hub and Helm templates.
- Commit reviewed Argo CD Applications, environment values, monitoring values, and network policy YAML.
- Verify OIDC provisioning ownership and whether the ECR requirement must still be implemented.
- Confirm HPA evidence shows the exact required transition from 2 to at least 5 replicas.
- Capture a successful UI SHA-image publish and corresponding deployment verification after merging.
- Verify Grafana screenshots visibly include CPU, memory, and restart counts.
- Multi-environment promotion, HTTPS, and persistent application databases remain future work.
