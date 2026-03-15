#!/bin/bash

set -e

echo "Starting local architecture..."

docker compose -f docker/docker-compose.yml up --build
