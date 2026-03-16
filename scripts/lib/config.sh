#!/usr/bin/env bash

readonly NAMESPACE_APP="cloud-study"
readonly NAMESPACE_MONITORING="monitoring"
readonly NAMESPACE_STRIMZI="strimzi"
readonly NAMESPACE_INGRESS="ingress-nginx"

readonly RELEASE_PROMETHEUS="kube-prometheus-stack"
readonly RELEASE_LOKI="loki"
readonly RELEASE_PROMTAIL="promtail"
readonly RELEASE_STRIMZI="strimzi"
readonly RELEASE_INGRESS="ingress-nginx"

readonly HELM_REPO_PROMETHEUS="prometheus-community"
readonly HELM_REPO_PROMETHEUS_URL="https://prometheus-community.github.io/helm-charts"
readonly HELM_REPO_GRAFANA="grafana"
readonly HELM_REPO_GRAFANA_URL="https://grafana.github.io/helm-charts"
readonly HELM_REPO_STRIMZI="strimzi"
readonly HELM_REPO_STRIMZI_URL="https://strimzi.io/charts"
readonly HELM_REPO_INGRESS="ingress-nginx"
readonly HELM_REPO_INGRESS_URL="https://kubernetes.github.io/ingress-nginx"

readonly CHART_PROMETHEUS="${HELM_REPO_PROMETHEUS}/kube-prometheus-stack"
readonly CHART_LOKI="${HELM_REPO_GRAFANA}/loki"
readonly CHART_PROMTAIL="${HELM_REPO_GRAFANA}/promtail"
readonly CHART_STRIMZI="${HELM_REPO_STRIMZI}/strimzi-kafka-operator"
readonly CHART_INGRESS="${HELM_REPO_INGRESS}/ingress-nginx"

readonly STRIMZI_OPERATOR_DEPLOYMENT="strimzi-cluster-operator"
readonly STRIMZI_WAIT_TIMEOUT="120s"

readonly GRAFANA_SECRET_NAME="${RELEASE_PROMETHEUS}-grafana"
readonly GRAFANA_SERVICE_NAME="${RELEASE_PROMETHEUS}-grafana"
readonly PROMETHEUS_SERVICE_NAME="${RELEASE_PROMETHEUS}-prometheus"

readonly DOCKER_COMPOSE_FILE="docker/docker-compose.yml"
readonly LOKI_VALUES_FILE="scripts/general/helm/loki-values.yaml"

readonly AZURE_CLUSTER_NAME="${AZURE_CLUSTER_NAME:-cloud-study-cluster}"
readonly AZURE_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-cloud-study-rg}"
readonly AZURE_REGISTRY_NAME="${AZURE_REGISTRY_NAME:-cloudstudyacr}"
readonly AZURE_REGISTRY_LOGIN_SERVER="${AZURE_REGISTRY_LOGIN_SERVER:-${AZURE_REGISTRY_NAME}.azurecr.io}"
