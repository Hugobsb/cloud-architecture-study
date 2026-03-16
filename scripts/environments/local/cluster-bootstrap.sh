#!/usr/bin/env bash
set -euo pipefail

STRIMZI_NAMESPACE="strimzi"

printf 'Starting Minikube cluster...\n'
minikube start

printf 'Enabling Ingress addon...\n'
minikube addons enable ingress

printf 'Creating namespaces...\n'
for namespace in "$STRIMZI_NAMESPACE" monitoring cloud-study; do
  kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
done

printf 'Installing Strimzi operator in namespace %s...\n' "$STRIMZI_NAMESPACE"
kubectl apply -f "https://strimzi.io/install/latest?namespace=${STRIMZI_NAMESPACE}" -n "$STRIMZI_NAMESPACE"

printf 'Waiting for Strimzi operator...\n'
kubectl wait deployment strimzi-cluster-operator \
  --for=condition=Available \
  -n "$STRIMZI_NAMESPACE" \
  --timeout=120s

printf 'Bootstrap complete.\n'
