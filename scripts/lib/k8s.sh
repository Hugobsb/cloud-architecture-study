#!/usr/bin/env bash

ensure_namespace() {
  local namespace="$1"

  printf 'Checking namespace...\n'
  if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
    printf 'Creating namespace %s\n' "$namespace"
    kubectl create namespace "$namespace"
  else
    printf 'Namespace already exists\n'
  fi
}

ensure_helm_repo() {
  local repo_name="$1"
  local repo_url="$2"
  local repo_label="$3"

  printf 'Checking Helm repo...\n'
  if ! helm repo list | grep -q "^${repo_name}[[:space:]]"; then
    printf 'Adding %s Helm repo\n' "$repo_label"
    helm repo add "$repo_name" "$repo_url"
  else
    printf 'Helm repo already added\n'
  fi
}

helm_release_exists() {
  local namespace="$1"
  local release_name="$2"

  helm list -n "$namespace" | grep -q "^${release_name}[[:space:]]"
}
