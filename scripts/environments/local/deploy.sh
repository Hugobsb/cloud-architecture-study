#!/usr/bin/env bash
set -e

IMAGE_TAG=$(git rev-parse --short HEAD)

API_IMAGE="api:$IMAGE_TAG"
WORKER_IMAGE="worker:$IMAGE_TAG"

export API_IMAGE
export WORKER_IMAGE

echo "Deploying resources to AKS..."

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/kafka
kubectl apply -f k8s/apps
kubectl apply -f k8s/observability
kubectl apply -f k8s/observability/dashboards
kubectl apply -f k8s/reliability

echo "Verifying Docker environment..."

if [[ -z "${DOCKER_HOST:-}" ]]; then
  echo "ERROR: Docker is not pointing to Minikube."
  echo "Run: eval \$(minikube docker-env)"
  exit 1
fi

echo "Docker environment is set up correctly."

echo "Building images..."

docker build -t $API_IMAGE services/api
docker build -t $WORKER_IMAGE services/worker

echo "Deploying images..."

envsubst < k8s/api/api-deployment.yaml | kubectl apply -f -
envsubst < k8s/worker/worker-deployment.yaml | kubectl apply -f -

echo "Deploying services..."

kubectl apply -f k8s/api/api-service.yaml

echo "Deployment completed"
