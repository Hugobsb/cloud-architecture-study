#!/usr/bin/env bash

set -euo pipefail

source scripts/lib/bootstrap.sh
source scripts/lib/config.sh
source scripts/lib/k8s.sh

ensure_namespace "$NAMESPACE_INGRESS"
ensure_helm_repo "$HELM_REPO_INGRESS" "$HELM_REPO_INGRESS_URL" "ingress-nginx"

printf 'Updating Helm repos...\n'
helm repo update

printf 'Checking if ingress controller is already installed...\n'
if helm_release_exists "$NAMESPACE_INGRESS" "$RELEASE_INGRESS"; then
  printf 'Ingress controller already installed\n'
else
  printf 'Installing NGINX ingress controller\n'
  helm install "$RELEASE_INGRESS" "$CHART_INGRESS" \
    --namespace "$NAMESPACE_INGRESS" \
    --set controller.publishService.enabled=true \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"="/healthz"
fi

printf 'Ingress installation completed\n'
