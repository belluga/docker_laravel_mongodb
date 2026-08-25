#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

# This audit targets project-owned root/docker extraction surfaces. It
# intentionally excludes delphi-ai/, which is PACED/Delphi foundation context
# governed separately from this repository's generic-root runtime boundary.
if command -v rg >/dev/null 2>&1; then
  matches="$(rg -n 'Belluga Now|belluga_now|belluga-now|docker-compose\.validation-belluga|project/belluga-validation' AGENTS.md docker-compose.yml docker project README.md .env.example .dockerignore tools/ci scripts/verify_environment.sh || true)"
else
  matches="$(grep -R -nE 'Belluga Now|belluga_now|belluga-now|docker-compose\.validation-belluga|project/belluga-validation' AGENTS.md docker-compose.yml docker project README.md .env.example .dockerignore tools/ci scripts/verify_environment.sh || true)"
fi

if [[ -n "${matches}" ]]; then
  echo "ERROR: Belluga Now-specific validation markers leaked into overlay-free generic-root surfaces:" >&2
  printf '%s\n' "${matches}" >&2
  exit 1
fi

# .gitmodules is checked separately because generic boilerplate child repos can
# legitimately still live under the Belluga org; what must never return here is
# a Belluga Now runtime-repo slug in the generic-root submodule map.
if [[ -f .gitmodules ]] && grep -Eq 'belluga_now|belluga-now' .gitmodules; then
  echo "ERROR: .gitmodules must not point generic-root submodules at Belluga Now runtime repositories." >&2
  grep -nE 'belluga_now|belluga-now' .gitmodules >&2 || true
  exit 1
fi

echo "OVERLAY_FREE_DETETHER_AUDIT_OK"
