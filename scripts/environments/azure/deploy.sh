#!/usr/bin/env bash
set -e

ACR_NAME="cloudstudyacr.azurecr.io"

IMAGE_TAG=$(git rev-parse --short HEAD)

API_IMAGE="$ACR_NAME/api:$IMAGE_TAG"
WORKER_IMAGE="$ACR_NAME/worker:$IMAGE_TAG"

export API_IMAGE
export WORKER_IMAGE

echo "Deploying resources to AKS..."

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/kafka
kubectl apply -f k8s/apps
kubectl apply -f k8s/observability
kubectl apply -f k8s/observability/dashboards
kubectl apply -f k8s/reliability

echo "Building images..."

docker build -t $API_IMAGE services/api
docker build -t $WORKER_IMAGE services/worker

echo "Pushing images..."

docker push $API_IMAGE
docker push $WORKER_IMAGE

echo "Deploying images to AKS..."

envsubst < k8s/api/api-deployment.yaml | kubectl apply -f -
envsubst < k8s/worker/worker-deployment.yaml | kubectl apply -f -

echo "Deployment completed"
