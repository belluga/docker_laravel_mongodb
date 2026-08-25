#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
web_app_dir="$repo_root/web-app"

resolve_playwright_bin() {
  if [[ -n "${PLAYWRIGHT_BIN:-}" ]]; then
    printf '%s\n' "$PLAYWRIGHT_BIN"
    return 0
  fi

  if [[ -n "${NODE_PATH:-}" && -x "$NODE_PATH/.bin/playwright" ]]; then
    printf '%s\n' "$NODE_PATH/.bin/playwright"
    return 0
  fi

  if [[ -x "$web_app_dir/node_modules/.bin/playwright" ]]; then
    printf '%s\n' "$web_app_dir/node_modules/.bin/playwright"
    return 0
  fi

  if command -v playwright >/dev/null 2>&1; then
    command -v playwright
    return 0
  fi

  return 1
}

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    printf 'Missing required environment variable: %s\n' "$name" >&2
    exit 1
  fi
}

PLAYWRIGHT_BIN="$(resolve_playwright_bin)" || {
  printf 'Unable to resolve Playwright. Set PLAYWRIGHT_BIN or NODE_PATH.\n' >&2
  exit 1
}

require_env NAV_LANDLORD_URL
require_env NAV_TENANT_URL

cd "$web_app_dir"

WEB_RUNTIME_BASE_URL="$NAV_TENANT_URL" "$PLAYWRIGHT_BIN" test tests/runtime.provenance.spec.js
WEB_RUNTIME_BASE_URL="$NAV_LANDLORD_URL" "$PLAYWRIGHT_BIN" test tests/runtime.provenance.spec.js
"$PLAYWRIGHT_BIN" test tests/public_contract.spec.js
"$PLAYWRIGHT_BIN" test tests/navigation.spec.js
