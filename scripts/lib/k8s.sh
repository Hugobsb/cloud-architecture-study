#!/usr/bin/env bash

ensure_namespace() {
  local namespace="$1"

  printf 'Checking namespace %s...\n' "$namespace"
  if ! kubectl get namespace "$namespace" >/dev/null 2>&1; then
    printf 'Creating namespace %s...\n' "$namespace"
    kubectl create namespace "$namespace"
  else
    printf 'Namespace %s already exists\n' "$namespace"
  fi
}

ensure_helm_repo() {
  local repo_name="$1"
  local repo_url="$2"
  local repo_label="$3"

  printf 'Checking Helm repo %s...\n' "$repo_name"
  if ! helm repo list | grep -q "^${repo_name}[[:space:]]"; then
    printf 'Adding %s Helm repo...\n' "$repo_label"
    helm repo add "$repo_name" "$repo_url"
  else
    printf 'Helm repo %s already added\n' "$repo_name"
  fi
}

helm_release_exists() {
  local namespace="$1"
  local release_name="$2"

  helm list -n "$namespace" | grep -q "^${release_name}[[:space:]]"
}

require_kubectl_context() {
  local current_context
  current_context="$(kubectl config current-context 2>/dev/null || true)"

  if [[ -z "$current_context" ]]; then
    printf 'kubectl has no current context configured.\n' >&2
    return 1
  fi

  printf 'Using kubectl context: %s\n' "$current_context"
}
