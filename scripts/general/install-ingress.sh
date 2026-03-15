#!/usr/bin/env bash

set -e

NAMESPACE="ingress-nginx"
RELEASE_NAME="ingress-nginx"
REPO_NAME="ingress-nginx"
REPO_URL="https://kubernetes.github.io/ingress-nginx"

echo "Checking namespace..."

if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
  echo "Creating namespace $NAMESPACE"
  kubectl create namespace $NAMESPACE
else
  echo "Namespace already exists"
fi

echo "Checking Helm repo..."

if ! helm repo list | grep -q "$REPO_NAME"; then
  echo "Adding ingress-nginx Helm repo"
  helm repo add $REPO_NAME $REPO_URL
else
  echo "Helm repo already added"
fi

echo "Updating Helm repos..."

helm repo update

echo "Checking if ingress controller is already installed..."

if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
  echo "Ingress controller already installed"
else
  echo "Installing NGINX ingress controller"
  helm install $RELEASE_NAME ingress-nginx/ingress-nginx \
    --namespace $NAMESPACE \
    --set controller.publishService.enabled=true \
    --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"="/healthz"
fi

echo "Ingress installation completed"
