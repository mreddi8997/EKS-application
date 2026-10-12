# UI build and manual image promotion

## Current behavior

The UI workflow validates UI code changes on pull requests into main and on pushes to main. Manual dispatch is also available. Chart-only changes are excluded from the UI image workflow.

Validation uses Java 21 and the Maven wrapper's verify phase. Snyk scanning remains advisory because continue-on-error is enabled.

After validation, Docker image publication runs only when the selected ref is main and the event is not a pull request. Manual dispatch on a feature branch validates without publishing. Image promotion remains manual; the workflow does not edit Helm values or create deployment branches.

Other service CI workflows still use their existing manual triggers and run-number tags. The SHA convention documented here applies to UI.

## Required secrets

- DOCKER_USERNAME: Docker Hub namespace used for retail-ui.
- DOCKER_PASSWORD: Docker Hub access token with write access to that repository.
- SNYK: Token used by the existing advisory dependency scan.

GitHub Packages write permission is not required for Docker Hub. The workflow needs repository contents read permission.

## Build an image

1. Open a feature PR containing UI code changes.
2. Review the validation results and merge into main.
3. Wait for the main workflow's build_and_push job to succeed.
4. Record the complete source commit SHA.

The published reference is:

```text
<dockerhub-username>/retail-ui:sha-<full-main-commit-sha>
```

Do not use the feature branch commit SHA if the merge produced a different commit. Do not overwrite a published release tag. Record the registry digest as release evidence.

## Promote the image manually

The current Argo CD image settings may be UI-entered overrides. Before moving image management to Git:

1. Export each Application and its current Helm configuration.
2. Review and commit environment values, including endpoints, ingress, and autoscaling.
3. Configure the Application to read its environment values file.
4. Remove conflicting image parameters or inline overrides.
5. Render and compare the desired manifests before syncing.

A proposed file is `retail-store-sample-app/src/ui/chart/values-dev.yaml`; it is not created by this guide because live settings have not been exported.

Once Git-managed environment values are configured:

1. Create a branch from current main.
2. Change image.repository to the Docker Hub repository and image.tag to the published SHA tag.
3. Render the chart with that environment's values and review the diff.
4. Open and merge a configuration PR.
5. Argo CD auto-sync deploys the change if enabled; otherwise request Sync.
6. Verify Application sync/health, rollout status, and the application response.

Example rendering and verification commands:

```bash
helm template ui retail-store-sample-app/src/ui/chart \
  --namespace ui \
  --values retail-store-sample-app/src/ui/chart/values-dev.yaml

kubectl get deployments -n ui
kubectl rollout status deployment/<actual-ui-deployment-name> \
  -n ui --timeout=300s
kubectl get pods -n ui
kubectl get deployments -n ui \
  -o jsonpath='{range .items[*]}{.metadata.name}{": "}{.spec.template.spec.containers[*].image}{"\n"}{end}'
```

A successful push is not proof of successful deployment. Capture the workflow result, the deployed image reference, rollout result, and a smoke test.

Chart-only changes need a separate Helm validation check before merge; exclusion from the image build is not validation.

## Future environment promotion

Build once and select the same image for dev, test, staging, and production. Update only the destination environment's image reference through a PR. Keep environment-specific endpoints and secrets separate.

Use approval for production promotion. Pin reviewed chart versions as well as images so shared chart changes do not bypass release approval. The repository does not yet demonstrate deployed test, staging, or production environments.

The existing Deployment template supports image tags, not a separate digest field. Digest pinning requires an explicit chart change and validation.

## Rollback

Record the previously deployed image before promotion. To roll back, revert the image configuration change through Git and let Argo CD reconcile it, then repeat health and smoke-test checks.

For the current UI-managed configuration, restore the recorded previous image override and sync; move these changes into Git when the Application configuration is exported.

Image rollback does not reverse database migrations. Review schema compatibility separately.
