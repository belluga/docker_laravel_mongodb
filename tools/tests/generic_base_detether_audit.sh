#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

# This audit targets project-owned root/docker extraction surfaces. It
# intentionally excludes delphi-ai/, which is PACED/Delphi foundation context
# governed separately from this repository's generic-root runtime boundary.
if command -v rg >/dev/null 2>&1; then
  matches="$(rg -n 'Belluga|belluga-now|belluga_now|belluga' AGENTS.md docker-compose.yml docker-compose.validation-belluga.yml docker project README.md .env.example .dockerignore .github tools || true)"
else
  matches="$(grep -R -nE 'Belluga|belluga-now|belluga_now|belluga' AGENTS.md docker-compose.yml docker-compose.validation-belluga.yml docker project README.md .env.example .dockerignore .github tools || true)"
fi

if [[ -z "${matches}" ]]; then
  echo "ERROR: expected Belluga validation markers were not found anywhere in the approved owner surfaces." >&2
  exit 1
fi

printf '%s\n' "${matches}"

unexpected_matches="$(
  printf '%s\n' "${matches}" | grep -Ev '^(docker-compose\.validation-belluga\.yml|README\.md|project/README\.md):|^project/belluga-validation/|^\.github/scripts/(verify_environment_ci|check_validation_owner_inputs)\.sh:|^tools/ci/contracts/(stage-full|main-proof)\.json:|^tools/tests/generic_base_detether_audit\.sh:' || true
)"
if [[ -n "${unexpected_matches}" ]]; then
  echo "ERROR: unexpected Belluga-specific markers leaked into generic-root surfaces:" >&2
  printf '%s\n' "${unexpected_matches}" >&2
  exit 1
fi

# .gitmodules is checked separately because generic boilerplate child repos can
# legitimately still live under the belluga GitHub org; what must never return
# here is a Belluga Now runtime-repo slug in the generic-root submodule map.
if [[ -f .gitmodules ]] && grep -Eq 'belluga_now|belluga-now' .gitmodules; then
  echo "ERROR: .gitmodules must not point generic-root submodules at Belluga Now runtime repositories." >&2
  grep -nE 'belluga_now|belluga-now' .gitmodules >&2 || true
  exit 1
fi

echo "BELLUGA_DETETHER_AUDIT_OK"
