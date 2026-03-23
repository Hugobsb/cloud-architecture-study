#!/usr/bin/env bash
set -euo pipefail

source scripts/lib/bootstrap.sh

BASE_REF="${1:-}"
HEAD_REF="${2:-HEAD}"

if [[ -z "${BASE_REF}" ]]; then
  printf 'Usage: %s <base-ref> [head-ref]\n' "$0" >&2
  exit 1
fi

require_command git

CHANGED_FILES="$(git diff --name-only "${BASE_REF}" "${HEAD_REF}")"

has_match() {
  local pattern

  for pattern in "$@"; do
    if grep -E -q "${pattern}" <<<"${CHANGED_FILES}"; then
      return 0
    fi
  done

  return 1
}

docs_changed=false
app_changed=false
infra_changed=false
workflow_changed=false

if [[ -n "${CHANGED_FILES}" ]]; then
  has_match '^README\.md$|^docs/|^TEST_' && docs_changed=true
  has_match '^services/' && app_changed=true
  has_match '^k8s/|^terraform/|^scripts/' && infra_changed=true
  has_match '^\.github/workflows/' && workflow_changed=true
fi

publish_images=false
deploy_openshift=false

if [[ "${app_changed}" == true ]]; then
  publish_images=true
  deploy_openshift=true
fi

if has_match '^k8s/overlays/openshift/|^scripts/environments/openshift-local/'; then
  deploy_openshift=true
fi

if has_match '^k8s/base/|^scripts/lib/|^scripts/environments/local/|^scripts/environments/azure/'; then
  publish_images=true
fi

printf 'docs_changed=%s\n' "${docs_changed}"
printf 'app_changed=%s\n' "${app_changed}"
printf 'infra_changed=%s\n' "${infra_changed}"
printf 'workflow_changed=%s\n' "${workflow_changed}"
printf 'publish_images=%s\n' "${publish_images}"
printf 'deploy_openshift=%s\n' "${deploy_openshift}"

