#!/usr/bin/env bash
set -euo pipefail

source scripts/lib/bootstrap.sh

require_command crc "Install OpenShift Local (crc) before bootstrapping this environment."
require_command oc "Install the OpenShift oc client before bootstrapping this environment."

CRC_CPUS="${CRC_CPUS:-4}"
CRC_MEMORY="${CRC_MEMORY:-12288}"

printf 'Running crc setup...\n'
crc setup

printf 'Starting OpenShift Local...\n'
crc start -c "${CRC_CPUS}" -m "${CRC_MEMORY}"

printf 'Configuring the OpenShift internal registry default route...\n'
oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"defaultRoute":true}}'

printf 'Bootstrap completed.\n'
printf 'Configure your shell with:\n'
printf '  eval $(crc oc-env)\n'
printf '  eval $(crc podman-env)\n'
