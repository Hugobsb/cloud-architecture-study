#!/bin/bash

set -e

echo "Stopping environment..."

docker compose -f docker/docker-compose.yml down -v
