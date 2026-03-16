#!/usr/bin/env bash
set -euo pipefail

source scripts/lib/bootstrap.sh
source scripts/lib/config.sh

printf 'Starting Minikube cluster...\n'
minikube start

printf 'Enabling Ingress addon...\n'
minikube addons enable ingress

printf 'Creating namespaces...\n'
for namespace in "$NAMESPACE_APP"; do
  kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
done

printf 'Installing Strimzi operator...\n'
./scripts/general/install-strimzi.sh

printf 'Waiting for Strimzi operator...\n'
kubectl wait deployment "$STRIMZI_OPERATOR_DEPLOYMENT" \
  --for=condition=Available \
  -n "$NAMESPACE_STRIMZI" \
  --timeout="$STRIMZI_WAIT_TIMEOUT"

printf 'Installing observability stack...\n'
./scripts/general/install-observability.sh

printf 'Bootstrap complete.\n'
