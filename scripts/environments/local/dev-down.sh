#!/usr/bin/env bash

set -euo pipefail

source scripts/lib/bootstrap.sh
source scripts/lib/config.sh

echo "Stopping environment..."

docker compose -f "$DOCKER_COMPOSE_FILE" down -v
