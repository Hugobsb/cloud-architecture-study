#!/usr/bin/env bash

set -euo pipefail

source scripts/lib/bootstrap.sh
source scripts/lib/config.sh

az aks start \
  --name "$AZURE_CLUSTER_NAME" \
  --resource-group "$AZURE_RESOURCE_GROUP"
