#!/usr/bin/env bash

[[ -d scripts && -f README.md ]] || {
  printf 'Run this script from the repository root.\n' >&2
  return 1 2>/dev/null || exit 1
}

readonly PROJECT_ROOT="$(pwd -P)"
readonly SCRIPTS_DIR="${PROJECT_ROOT}/scripts"

require_command() {
  local command_name="$1"
  local install_hint="${2:-}"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    if [[ -n "$install_hint" ]]; then
      printf 'Missing required command: %s. %s\n' "$command_name" "$install_hint" >&2
    else
      printf 'Missing required command: %s\n' "$command_name" >&2
    fi
    return 1
  fi
}

require_file() {
  local file_path="$1"

  if [[ ! -f "$file_path" ]]; then
    printf 'Required file not found: %s\n' "$file_path" >&2
    return 1
  fi
}
