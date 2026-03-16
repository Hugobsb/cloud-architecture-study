#!/usr/bin/env bash

set -euo pipefail

source scripts/lib/bootstrap.sh
source scripts/lib/config.sh

require_command docker "Install Docker Desktop or Docker Engine with Compose support."
require_file "$DOCKER_COMPOSE_FILE"

printf 'Stopping local Docker Compose stack...\n'
docker compose -f "$DOCKER_COMPOSE_FILE" down -v
