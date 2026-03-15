#!/usr/bin/env bash

set -e

NAMESPACE="kafka"
RELEASE_NAME="strimzi"
REPO_NAME="strimzi"
REPO_URL="https://strimzi.io/charts"

echo "Checking namespace..."

if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
  echo "Creating namespace $NAMESPACE"
  kubectl create namespace $NAMESPACE
else
  echo "Namespace already exists"
fi

echo "Checking Helm repo..."

if ! helm repo list | grep -q "$REPO_NAME"; then
  echo "Adding Strimzi Helm repo"
  helm repo add $REPO_NAME $REPO_URL
else
  echo "Helm repo already added"
fi

helm repo update

echo "Checking if Strimzi is already installed..."

if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
  echo "Strimzi already installed"
else
  echo "Installing Strimzi operator"
  helm install $RELEASE_NAME strimzi/strimzi-kafka-operator \
    --namespace $NAMESPACE
fi

echo "Strimzi installation completed"
