#!/usr/bin/env bash
set -euo pipefail

source scripts/lib/bootstrap.sh
source scripts/lib/config.sh
source scripts/lib/k8s.sh

require_command kubectl "Install kubectl and point it to the Minikube cluster."
require_command docker "Install Docker to build the local images."
require_command envsubst "Install envsubst (usually provided by gettext)."
require_kubectl_context

IMAGE_TAG=$(git rev-parse --short HEAD 2>/dev/null || printf 'local')
API_IMAGE="api:${IMAGE_TAG}"
WORKER_IMAGE="worker:${IMAGE_TAG}"

export API_IMAGE
export WORKER_IMAGE

printf 'Deploying resources to local Kubernetes...\n'
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/api/api-service.yaml
kubectl apply -f k8s/worker/worker-service.yaml
kubectl apply -f k8s/kafka
kubectl apply -f k8s/apps
kubectl apply -f k8s/observability
kubectl apply -f k8s/observability/dashboards
kubectl apply -f k8s/reliability

printf 'Verifying Docker environment...\n'
if [[ -z "${DOCKER_HOST:-}" ]]; then
  printf 'Docker is not pointing to the Minikube image daemon.\n' >&2
  printf 'Run `eval $(minikube docker-env)` before this script,\n' >&2
  printf 'or use the profile-specific command returned by Terraform local outputs.\n' >&2
  exit 1
fi

printf 'Docker environment is set up correctly.\n'
printf 'Building images...\n'
docker build -t "$API_IMAGE" services/api
docker build -t "$WORKER_IMAGE" services/worker

printf 'Deploying workloads...\n'
envsubst < k8s/api/api-deployment.yaml | kubectl apply -f -
envsubst < k8s/worker/worker-deployment.yaml | kubectl apply -f -

printf 'Deployment completed.\n'
printf 'If ingress is enabled, map api.local to the Minikube IP or use curl --resolve.\n'
