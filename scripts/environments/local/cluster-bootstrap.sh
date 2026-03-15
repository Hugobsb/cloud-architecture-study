#!/bin/bash

set -e

echo "Starting Minikube cluster..."

minikube start

echo "Enabling Ingress addon..."

minikube addons enable ingress

echo "Creating namespaces..."

kubectl create namespace kafka --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace strimzi --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace cloud-study --dry-run=client -o yaml | kubectl apply -f -

echo "Installing Strimzi operator..."

kubectl apply -f https://strimzi.io/install/latest?namespace=strimzi -n strimzi

echo "Waiting for Strimzi operator..."

kubectl wait deployment strimzi-cluster-operator \
  --for=condition=Available \
  -n strimzi \
  --timeout=120s

echo "Bootstrap complete."
