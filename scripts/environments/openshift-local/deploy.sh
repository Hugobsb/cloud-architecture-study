#!/usr/bin/env bash
set -euo pipefail

source scripts/lib/bootstrap.sh
source scripts/lib/config.sh

require_command oc "Install the OpenShift oc client and authenticate against OpenShift Local."
require_command podman "Install Podman to build and push the application images."
require_command envsubst "Install envsubst (usually provided by gettext)."

IMAGE_TAG=$(git rev-parse --short HEAD 2>/dev/null || printf 'local')
CURRENT_PROJECT="$(oc project -q 2>/dev/null || true)"

if [[ -z "${CURRENT_PROJECT}" ]]; then
  printf 'No active OpenShift project is configured.\n' >&2
  exit 1
fi

TARGET_PROJECT="${OPENSHIFT_PROJECT:-${CURRENT_PROJECT:-${DEFAULT_OPENSHIFT_PROJECT}}}"
TARGET_REGISTRY_HOST="${OPENSHIFT_REGISTRY_HOST:-$(oc registry info --public 2>/dev/null || true)}"

if [[ -z "${TARGET_REGISTRY_HOST}" ]]; then
  printf 'Could not determine the OpenShift public image registry host.\n' >&2
  exit 1
fi

API_IMAGE="${TARGET_REGISTRY_HOST}/${TARGET_PROJECT}/api:${IMAGE_TAG}"
WORKER_IMAGE="${TARGET_REGISTRY_HOST}/${TARGET_PROJECT}/worker:${IMAGE_TAG}"

export API_IMAGE
export WORKER_IMAGE
export OPENSHIFT_PROJECT="${TARGET_PROJECT}"

printf 'Using OpenShift project %s...\n' "${TARGET_PROJECT}"
oc project "${TARGET_PROJECT}" >/dev/null

printf 'Logging into the OpenShift internal registry...\n'
podman login --tls-verify=false -u "$(oc whoami)" -p "$(oc whoami -t)" "${TARGET_REGISTRY_HOST}"

printf 'Building images...\n'
podman build -t "${API_IMAGE}" services/api
podman build -t "${WORKER_IMAGE}" services/worker

printf 'Pushing images...\n'
podman push --tls-verify=false "${API_IMAGE}"
podman push --tls-verify=false "${WORKER_IMAGE}"

printf 'Deploying OpenShift overlay resources...\n'
while IFS= read -r manifest; do
  envsubst < "${manifest}" | oc apply -f -
done < <(find "${K8S_OPENSHIFT_OVERLAY_DIR}" -type f -name '*.yaml' | sort)

printf 'Deployment completed.\n'
printf 'API route: http://%s/job\n' "$(oc get route api -o jsonpath='{.spec.host}')"
