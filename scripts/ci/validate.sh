#!/usr/bin/env bash
set -euo pipefail

source scripts/lib/bootstrap.sh

require_command git
require_command bash
require_command docker
require_command terraform

printf 'Running repository validation...\n'

terraform fmt -check -recursive terraform

terraform -chdir=terraform/environments/local/kubernetes init -backend=false >/dev/null
terraform -chdir=terraform/environments/local/kubernetes validate

terraform -chdir=terraform/environments/local/openshift init -backend=false >/dev/null
terraform -chdir=terraform/environments/local/openshift validate

terraform -chdir=terraform/environments/clouds/azure init -backend=false >/dev/null
terraform -chdir=terraform/environments/clouds/azure validate

bash -n scripts/environments/local/*.sh \
  scripts/environments/azure/*.sh \
  scripts/environments/openshift-local/*.sh \
  scripts/general/*.sh \
  scripts/lib/*.sh

docker build -t cloud-study-api-ci services/api
docker build -t cloud-study-worker-ci services/worker

printf 'Repository validation completed successfully.\n'

