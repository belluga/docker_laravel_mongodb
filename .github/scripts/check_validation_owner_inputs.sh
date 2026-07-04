#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../.." && pwd)"
cd "${repo_root}"

extract_expected_validation_sha() {
  local label="$1"

  if [[ ! -f docker-compose.validation-belluga.yml ]]; then
    return 0
  fi

  local expected_sha=""
  expected_sha="$(
    sed -n "s/^# - ${label}:[[:space:]]*//p" docker-compose.validation-belluga.yml \
      | head -n1 \
      | tr -d '[:space:]'
  )"

  if [[ -n "${expected_sha}" ]]; then
    printf '%s\n' "${expected_sha}"
  fi
}

extract_gitlink_sha() {
  local repo_path="$1"
  local child_path="$2"
  local gitlink_sha=""

  gitlink_sha="$(
    git -C "${repo_path}" ls-tree HEAD -- "${child_path}" 2>/dev/null \
      | awk '$2 == "commit" { print $3; exit }'
  )"

  if [[ -n "${gitlink_sha}" ]]; then
    printf '%s\n' "${gitlink_sha}"
  fi
}

require_dir() {
  local path="$1"
  local reason="$2"

  if [[ ! -d "${path}" ]]; then
    echo "ERROR: ${reason}" >&2
    exit 1
  fi
}

require_file() {
  local path="$1"
  local reason="$2"

  if [[ ! -f "${path}" ]]; then
    echo "ERROR: ${reason}" >&2
    exit 1
  fi
}

require_sha() {
  local sha="$1"
  local reason="$2"

  if [[ ! "${sha}" =~ ^[0-9a-f]{40}$ ]]; then
    echo "ERROR: ${reason}" >&2
    exit 1
  fi
}

require_git_checkout() {
  local path="$1"
  local reason="$2"

  if ! git -C "${path}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: ${reason}" >&2
    exit 1
  fi
}

require_checkout_head() {
  local path="$1"
  local expected_sha="$2"
  local label="$3"
  local actual_sha=""

  actual_sha="$(git -C "${path}" rev-parse HEAD 2>/dev/null || true)"
  if [[ "${actual_sha}" != "${expected_sha}" ]]; then
    echo "ERROR: ${label} HEAD '${actual_sha:-missing}' does not match frozen SHA '${expected_sha}'." >&2
    exit 1
  fi
}

require_clean_checkout() {
  local path="$1"
  local label="$2"
  local checkout_status=""

  checkout_status="$(git -C "${path}" status --porcelain --untracked-files=all 2>/dev/null || true)"
  if [[ -n "${checkout_status}" ]]; then
    echo "ERROR: ${label} must be clean before CI-equivalent validation." >&2
    printf '%s\n' "${checkout_status}" >&2
    exit 1
  fi
}

if [[ -f docker-compose.validation-belluga.yml ]]; then
  validation_root="${BELLUGA_VALIDATION_ROOT:-../belluga_now_docker}"
  require_dir "${validation_root}" "validation-owner root '${validation_root}' is missing."

  expected_root_sha="$(extract_expected_validation_sha 'belluga_now_docker root' || true)"
  expected_backend_sha="$(extract_expected_validation_sha 'belluga_now_backend' || true)"
  expected_web_sha="$(extract_expected_validation_sha 'belluga_now_web' || true)"

  require_sha "${expected_root_sha}" \
    "docker-compose.validation-belluga.yml must declare the frozen belluga_now_docker root SHA."
  require_sha "${expected_backend_sha}" \
    "docker-compose.validation-belluga.yml must declare the frozen belluga_now_backend SHA."
  require_sha "${expected_web_sha}" \
    "docker-compose.validation-belluga.yml must declare the frozen belluga_now_web SHA."

  require_git_checkout "${validation_root}" \
    "validation-owner root '${validation_root}' must be a verifiable git checkout at the frozen Belluga root SHA."
  require_checkout_head "${validation_root}" "${expected_root_sha}" \
    "validation-owner root '${validation_root}'"

  root_backend_sha="$(extract_gitlink_sha "${validation_root}" 'laravel-app' || true)"
  root_web_sha="$(extract_gitlink_sha "${validation_root}" 'web-app' || true)"
  require_sha "${root_backend_sha}" \
    "validation-owner root '${validation_root}' must carry a gitlink for laravel-app."
  require_sha "${root_web_sha}" \
    "validation-owner root '${validation_root}' must carry a gitlink for web-app."

  if [[ "${root_backend_sha}" != "${expected_backend_sha}" ]]; then
    echo "ERROR: validation-owner root laravel-app gitlink '${root_backend_sha}' does not match frozen backend SHA '${expected_backend_sha}'." >&2
    exit 1
  fi
  if [[ "${root_web_sha}" != "${expected_web_sha}" ]]; then
    echo "ERROR: validation-owner root web-app gitlink '${root_web_sha}' does not match frozen web SHA '${expected_web_sha}'." >&2
    exit 1
  fi

  if [[ ! -f "${validation_root}/laravel-app/composer.json" || ! -f "${validation_root}/web-app/index.html" ]]; then
    echo "INFO: attempting validation-owner child input auto-materialization via git submodule update." >&2
    if ! git -C "${validation_root}" submodule update --init --recursive laravel-app web-app; then
      echo "ERROR: validation-owner child input auto-materialization failed for '${validation_root}'." >&2
      exit 1
    fi
  fi

  require_file "${validation_root}/laravel-app/composer.json" \
    "validation-owner Laravel input is missing at '${validation_root}/laravel-app/composer.json'; materialize the validation root child inputs before running CI-equivalent checks."
  require_file "${validation_root}/web-app/index.html" \
    "validation-owner web shell is missing at '${validation_root}/web-app/index.html'; materialize the validation root child inputs before running CI-equivalent checks."

  require_git_checkout "${validation_root}/laravel-app" \
    "validation-owner Laravel input at '${validation_root}/laravel-app' must be a git checkout at the frozen backend SHA."
  require_git_checkout "${validation_root}/web-app" \
    "validation-owner web input at '${validation_root}/web-app' must be a git checkout at the frozen web SHA."
  require_checkout_head "${validation_root}/laravel-app" "${expected_backend_sha}" \
    "validation-owner Laravel input '${validation_root}/laravel-app'"
  require_checkout_head "${validation_root}/web-app" "${expected_web_sha}" \
    "validation-owner web input '${validation_root}/web-app'"
  require_clean_checkout "${validation_root}/laravel-app" \
    "validation-owner Laravel input '${validation_root}/laravel-app'"
  require_clean_checkout "${validation_root}/web-app" \
    "validation-owner web input '${validation_root}/web-app'"

  echo "OK: validation-owner inputs materialized at '${validation_root}' with the frozen root/backend/web SHAs."
  exit 0
fi

require_file "laravel-app/composer.json" \
  "local downstream Laravel input is missing at 'laravel-app/composer.json'."
require_file "web-app/index.html" \
  "local downstream web shell is missing at 'web-app/index.html'."

echo "OK: local downstream Laravel/web inputs are materialized."
