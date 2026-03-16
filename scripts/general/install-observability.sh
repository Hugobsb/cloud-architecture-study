#!/usr/bin/env bash

set -euo pipefail

source scripts/lib/bootstrap.sh
source scripts/lib/config.sh
source scripts/lib/k8s.sh

ensure_namespace "$NAMESPACE_MONITORING"
ensure_helm_repo "$HELM_REPO_PROMETHEUS" "$HELM_REPO_PROMETHEUS_URL" "Prometheus"
ensure_helm_repo "$HELM_REPO_GRAFANA" "$HELM_REPO_GRAFANA_URL" "Grafana"

printf 'Updating Helm repos...\n'
helm repo update

printf 'Installing Prometheus stack...\n'
if helm_release_exists "$NAMESPACE_MONITORING" "$RELEASE_PROMETHEUS"; then
  printf 'Prometheus stack already installed\n'
else
  helm install "$RELEASE_PROMETHEUS" "$CHART_PROMETHEUS" \
    --namespace "$NAMESPACE_MONITORING"
fi

printf 'Installing Loki logging stack...\n'
if helm_release_exists "$NAMESPACE_MONITORING" "$RELEASE_LOKI"; then
  printf 'Loki already installed\n'
else
  helm install "$RELEASE_LOKI" "$CHART_LOKI" \
    -n "$NAMESPACE_MONITORING" \
    -f "$LOKI_VALUES_FILE"
fi

printf 'Installing Promtail...\n'
if helm_release_exists "$NAMESPACE_MONITORING" "$RELEASE_PROMTAIL"; then
  printf 'Promtail already installed\n'
else
  helm install "$RELEASE_PROMTAIL" "$CHART_PROMTAIL" \
    -n "$NAMESPACE_MONITORING"
fi

printf 'Observability stack installation completed\n'
