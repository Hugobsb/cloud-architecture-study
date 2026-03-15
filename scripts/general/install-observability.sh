#!/usr/bin/env bash

set -e

NAMESPACE="monitoring"

PROM_RELEASE="kube-prometheus-stack"
LOKI_RELEASE="loki"

PROM_REPO="prometheus-community"
PROM_REPO_URL="https://prometheus-community.github.io/helm-charts"

GRAFANA_REPO="grafana"
GRAFANA_REPO_URL="https://grafana.github.io/helm-charts"

echo "Checking namespace..."

if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
  echo "Creating namespace $NAMESPACE"
  kubectl create namespace $NAMESPACE
else
  echo "Namespace already exists"
fi

echo "Checking Helm repos..."

if ! helm repo list | grep -q "$PROM_REPO"; then
  echo "Adding Prometheus repo"
  helm repo add $PROM_REPO $PROM_REPO_URL
fi

if ! helm repo list | grep -q "$GRAFANA_REPO"; then
  echo "Adding Grafana repo"
  helm repo add $GRAFANA_REPO $GRAFANA_REPO_URL
fi

helm repo update

echo "Installing Prometheus stack..."

if helm list -n $NAMESPACE | grep -q $PROM_RELEASE; then
  echo "Prometheus stack already installed"
else
  helm install $PROM_RELEASE prometheus-community/kube-prometheus-stack \
    --namespace $NAMESPACE
fi

echo "Installing Loki logging stack..."

if helm list -n $NAMESPACE | grep -q $LOKI_RELEASE; then
  echo "Loki already installed"
else
  helm install loki grafana/loki \
    -n $NAMESPACE \
    -f scripts/general/helm/loki-values.yaml
fi

echo "Installing Promtail..."

if helm list -n $NAMESPACE | grep -q promtail; then
  echo "Promtail already installed"
else
  helm install promtail grafana/promtail \
    -n $NAMESPACE
fi

echo "Observability stack installation completed"
