#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG=$(git rev-parse --short HEAD 2>/dev/null || printf 'local')
API_IMAGE="api:${IMAGE_TAG}"
WORKER_IMAGE="worker:${IMAGE_TAG}"

export API_IMAGE
export WORKER_IMAGE

printf 'Deploying resources to local Kubernetes...\n'
kubectl apply -f k8s/api/api-service.yaml
kubectl apply -f k8s/kafka
kubectl apply -f k8s/apps
kubectl apply -f k8s/observability
kubectl apply -f k8s/observability/dashboards
kubectl apply -f k8s/reliability

printf 'Verifying Docker environment...\n'
if [[ -z "${DOCKER_HOST:-}" ]]; then
  printf 'ERROR: Docker is not pointing to Minikube.\n'
  printf 'Run: eval $(minikube docker-env)\n'
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
