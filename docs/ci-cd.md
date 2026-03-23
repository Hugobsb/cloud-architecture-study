# CI/CD

This repository uses a single GitHub Actions workflow for pushes to `main`.

## Behavior

- `detect-changes`: classifies what changed in the push
- `validate`: always runs repository validation
- `build-images`: runs only when the change set requires new application images
- `deploy-openshift`: runs only when the change set affects the tested OpenShift delivery path

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

## Validation scope

`scripts/ci/validate.sh` currently runs:

- `terraform fmt -check -recursive terraform`
- `terraform validate` for local Kubernetes, local OpenShift, and Azure environments
- `bash -n` on repository shell scripts
- Docker builds for API and worker

This keeps the pipeline bounded to checks that are reproducible in GitHub-hosted runners.
