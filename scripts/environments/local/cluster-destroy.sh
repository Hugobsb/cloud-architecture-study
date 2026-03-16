#!/usr/bin/env bash
set -euo pipefail

source scripts/lib/bootstrap.sh

MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-minikube}"

printf 'Deleting Minikube cluster (profile: %s)...\n' "$MINIKUBE_PROFILE"
minikube delete --profile="$MINIKUBE_PROFILE"
