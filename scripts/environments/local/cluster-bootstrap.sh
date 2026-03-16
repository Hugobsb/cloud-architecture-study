#!/usr/bin/env bash
set -euo pipefail

source scripts/lib/bootstrap.sh
source scripts/lib/config.sh

MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-minikube}"
MINIKUBE_DRIVER="${MINIKUBE_DRIVER:-}"
MINIKUBE_KUBERNETES_VERSION="${MINIKUBE_KUBERNETES_VERSION:-}"
MINIKUBE_CPUS="${MINIKUBE_CPUS:-}"
MINIKUBE_MEMORY="${MINIKUBE_MEMORY:-}"
MINIKUBE_DISK_SIZE="${MINIKUBE_DISK_SIZE:-}"

MINIKUBE_START_ARGS=(start "--profile=${MINIKUBE_PROFILE}")

if [[ -n "$MINIKUBE_DRIVER" ]]; then
  MINIKUBE_START_ARGS+=("--driver=${MINIKUBE_DRIVER}")
fi

if [[ -n "$MINIKUBE_KUBERNETES_VERSION" ]]; then
  MINIKUBE_START_ARGS+=("--kubernetes-version=${MINIKUBE_KUBERNETES_VERSION}")
fi

if [[ -n "$MINIKUBE_CPUS" ]]; then
  MINIKUBE_START_ARGS+=("--cpus=${MINIKUBE_CPUS}")
fi

if [[ -n "$MINIKUBE_MEMORY" ]]; then
  MINIKUBE_START_ARGS+=("--memory=${MINIKUBE_MEMORY}")
fi

if [[ -n "$MINIKUBE_DISK_SIZE" ]]; then
  MINIKUBE_START_ARGS+=("--disk-size=${MINIKUBE_DISK_SIZE}")
fi

printf 'Starting Minikube cluster (profile: %s)...\n' "$MINIKUBE_PROFILE"
minikube "${MINIKUBE_START_ARGS[@]}"

printf 'Enabling Ingress addon...\n'
minikube addons enable ingress --profile="$MINIKUBE_PROFILE"

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
