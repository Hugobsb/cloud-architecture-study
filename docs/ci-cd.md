# CI/CD

This repository uses a single GitHub Actions workflow for:

- pushes to `main`
- manual runs through `workflow_dispatch`

## Behavior

- `detect-changes`: classifies what changed in the push
- `validate`: always runs repository validation
- `build-images`: runs only when the change set requires new application images
- `deploy-openshift`: runs only when the change set affects the tested OpenShift delivery path

Manual runs expose `force_full_run`, which can force image publishing and OpenShift deploy even when change detection would normally skip them.

That forced path is intentionally restricted in the workflow: it only applies when `github.actor == 'Hugobsb'`.

## Change detection

The workflow uses `scripts/ci/detect-changes.sh` and exposes these booleans:

- `docs_changed`
- `app_changed`
- `infra_changed`
- `workflow_changed`
- `publish_images`
- `deploy_openshift`

Current rules:

- `services/` changes trigger image publishing and OpenShift deploy
- `k8s/overlays/openshift/` and `scripts/environments/openshift-local/` changes trigger OpenShift deploy
- `k8s/base/`, `scripts/lib/`, `scripts/environments/local/`, and `scripts/environments/azure/` changes trigger image publishing
- docs-only changes do not publish images or deploy

## Required secrets

For image publishing and OpenShift deployment:

- `IMAGE_REGISTRY_HOST`
- `IMAGE_REGISTRY_USERNAME`
- `IMAGE_REGISTRY_PASSWORD`
- `IMAGE_REGISTRY_NAMESPACE`
- `OPENSHIFT_SERVER`
- `OPENSHIFT_TOKEN`
- `OPENSHIFT_PROJECT`

The workflow pushes images to:

- `<IMAGE_REGISTRY_HOST>/<IMAGE_REGISTRY_NAMESPACE>/api:<sha>`
- `<IMAGE_REGISTRY_HOST>/<IMAGE_REGISTRY_NAMESPACE>/worker:<sha>`
- `<IMAGE_REGISTRY_HOST>/<IMAGE_REGISTRY_NAMESPACE>/api:main`
- `<IMAGE_REGISTRY_HOST>/<IMAGE_REGISTRY_NAMESPACE>/worker:main`

Current registry target:

- `ghcr.io`

For this repository, the image namespace must stay lowercase. For example:

- `hugobsb`

Using uppercase values such as `Hugobsb` produces invalid image references in OpenShift.

## Private GHCR images

The current delivery path assumes private images in GHCR.

That means two independent credentials must be configured:

- GitHub Actions secrets, so the workflow can push images
- an OpenShift pull secret, so the cluster can pull private images during deploy

Example cluster setup:

```bash
oc create secret docker-registry ghcr-pull-secret \
  --docker-server=ghcr.io \
  --docker-username=hugobsb \
  --docker-password='<github-pat-with-packages-access>' \
  --docker-email='<github-email>' \
  --dry-run=client -o yaml | oc apply -f -

oc secrets link default ghcr-pull-secret --for=pull
```

The PAT used for the OpenShift pull secret must be allowed to read the private GHCR packages.

## Notes from PR validation

These details were important while validating the workflow introduced in this PR:

- image tags must be pushed explicitly as `${github.sha}`, because deploy uses the full commit SHA as the image tag
- relying on implicit metadata-generated tags caused `manifest unknown` during OpenShift pull
- the OpenShift project must already exist; the workflow deploys into the configured project and does not create new projects
- the OpenShift overlay is project-scoped and aligned with the sandbox-style environment validated during development

## Validation scope

`scripts/ci/validate.sh` currently runs:

- `terraform fmt -check -recursive terraform`
- `terraform validate` for local Kubernetes, local OpenShift, and Azure environments
- `bash -n` on repository shell scripts
- Docker builds for API and worker

This keeps the pipeline bounded to checks that are reproducible in GitHub-hosted runners.
