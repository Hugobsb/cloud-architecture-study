#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "${SCRIPT_DIR}/../../.." && pwd)

printf 'Starting Minikube cluster...\n'
minikube start

printf 'Enabling Ingress addon...\n'
minikube addons enable ingress

printf 'Creating namespaces...\n'
for namespace in cloud-study; do
  kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
done

printf 'Installing Strimzi operator...\n'
"${PROJECT_ROOT}/scripts/general/install-strimzi.sh"

printf 'Waiting for Strimzi operator...\n'
kubectl wait deployment strimzi-cluster-operator \
  --for=condition=Available \
  -n strimzi \
  --timeout=120s

printf 'Installing observability stack...\n'
"${PROJECT_ROOT}/scripts/general/install-observability.sh"

printf 'Bootstrap complete.\n'
