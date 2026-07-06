#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"
cd "${repo_root}"

require_file() {
  local path="$1"
  local reason="$2"

  if [[ ! -f "${path}" ]]; then
    echo "ERROR: ${reason}" >&2
    exit 1
  fi
}

require_file "laravel-app/composer.json" \
  "local downstream Laravel input is missing at 'laravel-app/composer.json'."
require_file "web-app/index.html" \
  "local downstream web shell is missing at 'web-app/index.html'."

echo "OK: local downstream Laravel/web inputs are materialized."
