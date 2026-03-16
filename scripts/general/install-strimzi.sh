#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="strimzi"
RELEASE_NAME="strimzi"
REPO_NAME="strimzi"
REPO_URL="https://strimzi.io/charts"

printf 'Checking namespace...\n'
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  printf 'Creating namespace %s\n' "$NAMESPACE"
  kubectl create namespace "$NAMESPACE"
else
  printf 'Namespace already exists\n'
fi

printf 'Checking Helm repo...\n'
if ! helm repo list | grep -q "$REPO_NAME"; then
  printf 'Adding Strimzi Helm repo\n'
  helm repo add "$REPO_NAME" "$REPO_URL"
else
  printf 'Helm repo already added\n'
fi

helm repo update

printf 'Checking if Strimzi is already installed...\n'
if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
  printf 'Strimzi already installed\n'
else
  printf 'Installing Strimzi operator\n'
  helm install "$RELEASE_NAME" strimzi/strimzi-kafka-operator \
    --namespace "$NAMESPACE"
fi

printf 'Strimzi installation completed\n'
