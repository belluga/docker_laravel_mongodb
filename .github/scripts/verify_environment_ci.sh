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

run_guard() {
  local command=("$@")

  if ! "${command[@]}"; then
    exit 1
  fi
}

require_fixed() {
  local needle="$1"
  local path="$2"
  local reason="$3"

  if ! grep -Fq -- "${needle}" "${path}"; then
    echo "ERROR: ${reason}" >&2
    exit 1
  fi
}

forbid_fixed() {
  local needle="$1"
  local path="$2"
  local reason="$3"

  if grep -Fq -- "${needle}" "${path}"; then
    echo "ERROR: ${reason}" >&2
    exit 1
  fi
}

required_root_files=(
  ".github/scripts/check_validation_owner_inputs.sh"
  ".github/scripts/checkout_ci_submodules.sh"
  ".github/scripts/preflight_promotion_runtime_builds.sh"
  ".github/scripts/verify_environment_ci.sh"
  "tools/ci/run_contract.sh"
  "tools/ci/contracts/root-invariants.json"
  "tools/ci/contracts/promotion-runtime-builds.json"
  "tools/ci/contracts/stage-full.json"
  "tools/ci/contracts/main-proof.json"
)

required_validation_overlay_files=(
  "project/belluga-validation/ci/stage-full.json"
  "project/belluga-validation/ci/main-proof.json"
)

for file in "${required_root_files[@]}"; do
  require_file "${file}" "required root CI/runtime surface missing: ${file}"
done

if [[ -f docker-compose.validation-belluga.yml ]]; then
  for file in "${required_validation_overlay_files[@]}"; do
    require_file "${file}" "required validation-owner surface missing while docker-compose.validation-belluga.yml is active: ${file}"
  done
fi

run_guard bash .github/scripts/check_validation_owner_inputs.sh

require_fixed 'FROM php:8.4.10-fpm' docker/laravel-app/Dockerfile \
  "docker/laravel-app/Dockerfile must pin the PHP runtime-deps base image version for deterministic promotion builds."
require_fixed 'AS runtime-deps' docker/laravel-app/Dockerfile \
  "docker/laravel-app/Dockerfile must expose a runtime-deps stage for deterministic promotion preflight builds."
require_fixed 'FROM runtime-deps AS builder' docker/laravel-app/Dockerfile \
  "docker/laravel-app/Dockerfile must build the runtime image from the pinned runtime-deps stage."
require_fixed 'libzstd-dev' docker/laravel-app/Dockerfile \
  "docker/laravel-app/Dockerfile must install libzstd-dev for pinned mongodb PECL builds."
require_fixed 'ARG MONGODB_PECL_SHA256=' docker/laravel-app/Dockerfile \
  "docker/laravel-app/Dockerfile must pin the mongodb PECL tarball SHA256 for deterministic promotion builds."
require_fixed 'https://pecl.php.net/get/mongodb-${MONGODB_PECL_VERSION}.tgz' docker/laravel-app/Dockerfile \
  "docker/laravel-app/Dockerfile must fetch the pinned mongodb PECL tarball explicitly."
require_fixed 'sha256sum -c -' docker/laravel-app/Dockerfile \
  "docker/laravel-app/Dockerfile must verify the pinned mongodb PECL tarball hash."
require_fixed "sed -i 's/^#define BSON_HAVE_STRLCPY 1\$/#define BSON_HAVE_STRLCPY 0/'" docker/laravel-app/Dockerfile \
  "docker/laravel-app/Dockerfile must patch the bundled libbson strlcpy macro before compiling mongodb."
require_fixed 'php --ri mongodb >/dev/null' docker/laravel-app/Dockerfile \
  "docker/laravel-app/Dockerfile must verify that the compiled mongodb extension loads successfully."

for dockerignore_marker in '**/.env' 'laravel-app/.composer' 'laravel-app/vendor'; do
  if ! grep -Fxq "${dockerignore_marker}" .dockerignore; then
    echo "ERROR: .dockerignore must exclude '${dockerignore_marker}' from promoted runtime image contexts." >&2
    exit 1
  fi
done

for compose_image_ref in \
  'image: ${APP_IMAGE:-project-app:local}' \
  'image: ${WORKER_IMAGE:-project-worker:local}' \
  'image: ${SCHEDULER_IMAGE:-project-scheduler:local}' \
  'image: ${NGINX_IMAGE:-project-nginx:local}'; do
  require_fixed "${compose_image_ref}" docker-compose.yml \
    "docker-compose.yml must expose runtime image override '${compose_image_ref}'."
done

require_fixed './web-app:/opt/web-shell:ro' docker-compose.yml \
  "docker-compose.yml must mount web-app at './web-app:/opt/web-shell:ro' for runtime web-shell parity."
forbid_fixed './web-app:/var/www/flutter:ro' docker-compose.yml \
  "docker-compose.yml must not mount web-app into /var/www/flutter; nested bind mounts there can hide the runtime bundle."

for nginx_template in docker/nginx/local.conf.template docker/nginx/prod.conf.template; do
  require_fixed 'root /opt/web-shell;' "${nginx_template}" \
    "${nginx_template} must serve web assets from /opt/web-shell."
  forbid_fixed 'root /var/www/flutter;' "${nginx_template}" \
    "${nginx_template} must not serve web assets from /var/www/flutter."
  forbid_fixed 'root /opt/flutter-web-shell;' "${nginx_template}" \
    "${nginx_template} must not regress to the Belluga-specific /opt/flutter-web-shell mount."
done

require_fixed '--target runtime-deps' .github/scripts/preflight_promotion_runtime_builds.sh \
  "preflight_promotion_runtime_builds.sh must build the pinned runtime-deps Docker stage before promotion."
require_fixed 'project-preflight-laravel-runtime-deps:' .github/scripts/preflight_promotion_runtime_builds.sh \
  "preflight_promotion_runtime_builds.sh must use a neutral preflight tag for the Laravel runtime-deps stage."
require_fixed 'project-preflight-laravel-runtime:' .github/scripts/preflight_promotion_runtime_builds.sh \
  "preflight_promotion_runtime_builds.sh must use a neutral preflight tag for the final Laravel runtime image."
require_fixed 'project-preflight-nginx:' .github/scripts/preflight_promotion_runtime_builds.sh \
  "preflight_promotion_runtime_builds.sh must use a neutral preflight tag for the nginx runtime image."
require_fixed 'docker/nginx/Dockerfile' .github/scripts/preflight_promotion_runtime_builds.sh \
  "preflight_promotion_runtime_builds.sh must build the nginx runtime image before promotion."
require_fixed '--pull' .github/scripts/preflight_promotion_runtime_builds.sh \
  "preflight_promotion_runtime_builds.sh must refresh base-image drift via docker build --pull."
require_fixed 'preflight_docker_config="$(mktemp -d)"' .github/scripts/preflight_promotion_runtime_builds.sh \
  "preflight_promotion_runtime_builds.sh must isolate Docker credentials via an ephemeral DOCKER_CONFIG."
require_fixed 'export DOCKER_CONFIG="${preflight_docker_config}"' .github/scripts/preflight_promotion_runtime_builds.sh \
  "preflight_promotion_runtime_builds.sh must export the ephemeral DOCKER_CONFIG before public base-image pulls."

require_fixed '"path": "root-invariants.json"' tools/ci/contracts/stage-full.json \
  "stage-full manifest must import root-invariants.json."
require_fixed '"path": "promotion-runtime-builds.json"' tools/ci/contracts/stage-full.json \
  "stage-full manifest must import promotion-runtime-builds.json."
require_fixed '"id": "generic-base-detether-audit"' tools/ci/contracts/root-invariants.json \
  "root-invariants.json must require the generic-base detether audit as part of the CI-equivalent contract graph."
require_fixed 'tools/tests/generic_base_detether_audit.sh' tools/ci/contracts/root-invariants.json \
  "root-invariants.json must execute tools/tests/generic_base_detether_audit.sh inside the CI-equivalent contract graph."
if [[ -f docker-compose.validation-belluga.yml ]]; then
  require_fixed '"path": "../../../project/belluga-validation/ci/stage-full.json"' tools/ci/contracts/stage-full.json \
    "stage-full manifest must expose the explicit project-owned Belluga validation contract while the validation-owner override is active."
  require_fixed '"path": "root-invariants.json"' tools/ci/contracts/main-proof.json \
    "main-proof manifest must import root-invariants.json."
  require_fixed '"path": "../../../project/belluga-validation/ci/main-proof.json"' tools/ci/contracts/main-proof.json \
    "main-proof manifest must keep production-lane blocking semantics on the explicit project-owned validation contract while the validation-owner override is active."
  require_fixed '"id": "validation-owner-inputs"' project/belluga-validation/ci/stage-full.json \
    "project/belluga-validation/ci/stage-full.json must fail closed when the validation-owner inputs are not materialized."
  require_fixed '.github/scripts/check_validation_owner_inputs.sh' project/belluga-validation/ci/stage-full.json \
    "project/belluga-validation/ci/stage-full.json must execute the validation-owner input guard before compose rendering."
else
  forbid_fixed 'belluga-validation/ci/stage-full.json' tools/ci/contracts/stage-full.json \
    "stage-full manifest must drop the Belluga validation overlay import once docker-compose.validation-belluga.yml is removed."
  forbid_fixed 'belluga-validation/ci/main-proof.json' tools/ci/contracts/main-proof.json \
    "main-proof manifest must drop the Belluga validation overlay import once docker-compose.validation-belluga.yml is removed."
fi

# checkout_ci_submodules.sh is preserved here as a structural CI checkout helper.
# It is not part of the local stage-full execution path because it mutates checkout
# state and becomes a no-op when foundation_documentation is repo-local content.
require_fixed 'git submodule sync --recursive' .github/scripts/checkout_ci_submodules.sh \
  "checkout_ci_submodules.sh must sync submodule metadata before checkout."
require_fixed 'git submodule update --init --recursive' .github/scripts/checkout_ci_submodules.sh \
  "checkout_ci_submodules.sh must initialize the required submodules recursively."
require_fixed 'FOUNDATION_DOCS_BRANCH="${FOUNDATION_DOCS_BRANCH:-main}"' .github/scripts/checkout_ci_submodules.sh \
  "checkout_ci_submodules.sh must default foundation_documentation authority to main."
require_fixed 'git -C foundation_documentation fetch origin "${FOUNDATION_DOCS_BRANCH}" --quiet' .github/scripts/checkout_ci_submodules.sh \
  "checkout_ci_submodules.sh must fetch the canonical foundation_documentation branch explicitly."
require_fixed 'git -C foundation_documentation checkout --detach "origin/${FOUNDATION_DOCS_BRANCH}" --quiet' .github/scripts/checkout_ci_submodules.sh \
  "checkout_ci_submodules.sh must materialize foundation_documentation from origin/main authority instead of the root gitlink pin."

require_fixed 'bash tools/ci/run_contract.sh --profile stage-full' README.md \
  "README must identify stage-full as the repo-owned CI Equivalent contract for the current root/docker boundary."
require_fixed 'bash tools/ci/run_contract.sh --profile main-proof' README.md \
  "README must identify main-proof as the separate production-lane semantic guard surface."
require_fixed '`stage-full`: broadest local CI Equivalent at the current root/docker boundary;' README.md \
  "README must explain the truthful stage-full boundary."
require_fixed '`main-proof`: separate production-lane semantic guard;' README.md \
  "README must explain why main-proof stays distinct from stage-full."
require_fixed 'belluga-validation/ci/' project/README.md \
  "project/README.md must document the project-owned CI contract overlay surface."

echo "OK: root CI/runtime invariants passed."
