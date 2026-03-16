#!/usr/bin/env bash
set -euo pipefail

source scripts/lib/bootstrap.sh
source scripts/lib/config.sh
source scripts/lib/k8s.sh

ensure_namespace "$NAMESPACE_STRIMZI"
ensure_helm_repo "$HELM_REPO_STRIMZI" "$HELM_REPO_STRIMZI_URL" "Strimzi"

helm repo update

printf 'Checking if Strimzi is already installed...\n'
if helm_release_exists "$NAMESPACE_STRIMZI" "$RELEASE_STRIMZI"; then
  printf 'Strimzi already installed\n'
else
  printf 'Installing Strimzi operator\n'
  helm install "$RELEASE_STRIMZI" "$CHART_STRIMZI" \
    --namespace "$NAMESPACE_STRIMZI"
fi

printf 'Strimzi installation completed\n'
