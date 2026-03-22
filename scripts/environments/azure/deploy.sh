#!/usr/bin/env bash
set -euo pipefail

source scripts/lib/bootstrap.sh
source scripts/lib/config.sh
source scripts/lib/k8s.sh

require_command kubectl "Install kubectl and authenticate against the AKS cluster."
require_command docker "Install Docker to build the application images."
require_command envsubst "Install envsubst (usually provided by gettext)."
require_kubectl_context

IMAGE_TAG=$(git rev-parse --short HEAD)

API_IMAGE="$AZURE_REGISTRY_LOGIN_SERVER/api:$IMAGE_TAG"
WORKER_IMAGE="$AZURE_REGISTRY_LOGIN_SERVER/worker:$IMAGE_TAG"

export API_IMAGE
export WORKER_IMAGE

echo "Deploying resources to AKS..."

kubectl apply -f k8s/namespace.yaml
kubectl apply -f "${K8S_BASE_DIR}/api/api-service.yaml"
kubectl apply -f "${K8S_BASE_DIR}/worker/worker-service.yaml"
kubectl apply -f "${K8S_BASE_DIR}/kafka"
kubectl apply -f "${K8S_KUBERNETES_OVERLAY_DIR}/apps"
kubectl apply -f "${K8S_BASE_DIR}/observability"
kubectl apply -f "${K8S_BASE_DIR}/observability/dashboards"
kubectl apply -f "${K8S_BASE_DIR}/reliability"

echo "Building images..."

docker build -t "$API_IMAGE" services/api
docker build -t "$WORKER_IMAGE" services/worker

echo "Pushing images..."

docker push "$API_IMAGE"
docker push "$WORKER_IMAGE"

echo "Deploying images to AKS..."

envsubst < "${K8S_BASE_DIR}/api/api-deployment.yaml" | kubectl apply -f -
envsubst < "${K8S_BASE_DIR}/worker/worker-deployment.yaml" | kubectl apply -f -

echo "Deployment completed"
