#!/usr/bin/env bash
set -euo pipefail

source scripts/lib/bootstrap.sh
source scripts/lib/config.sh

require_command minikube "Install Minikube to create the local Kubernetes cluster."
require_command kubectl "Install kubectl and configure it to talk to Minikube."
require_command helm "Install Helm to install Strimzi and the observability stack."

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
require_kubectl_context

printf 'Enabling Ingress addon...\n'
minikube addons enable ingress --profile="$MINIKUBE_PROFILE"

printf 'Applying application namespace manifest...\n'
kubectl apply -f k8s/namespace.yaml

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
printf 'If you plan to build images into Minikube, run:\n'
printf '  eval $(minikube -p %s docker-env)\n' "$MINIKUBE_PROFILE"
