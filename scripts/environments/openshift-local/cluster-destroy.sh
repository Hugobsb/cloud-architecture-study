#!/usr/bin/env bash
set -euo pipefail

source scripts/lib/bootstrap.sh

require_command crc "Install OpenShift Local (crc) before destroying this environment."

printf 'Deleting OpenShift Local...\n'
crc delete -f
