#!/usr/bin/env bash

[[ -d scripts && -f README.md ]] || {
  printf 'Run this script from the repository root.\n' >&2
  return 1 2>/dev/null || exit 1
}

readonly PROJECT_ROOT="$(pwd -P)"
readonly SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
