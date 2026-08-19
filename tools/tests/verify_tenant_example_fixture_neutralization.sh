#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ROOT="$(git -C "$SCRIPT_DIR/../.." rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$DEFAULT_ROOT" ]]; then
  DEFAULT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

REPO_ROOT="$DEFAULT_ROOT"
OUTPUT_PATH=""
SCAN_LABEL="current"
LAST_RG_STATUS=0

usage() {
  cat <<'EOF'
Usage: verify_tenant_example_fixture_neutralization.sh [--repo-root PATH] [--output PATH] [--label LABEL]

Runs a redacted, case-insensitive residue guard across the four owned example/fixture files:
  - flutter-app/README.md
  - flutter-app/android/keystores/tenant.properties.example
  - laravel-app/tests/Feature/PublicWeb/WellKnownAssociationTest.php
  - laravel-app/tests/Unit/Application/Tenants/TenantAppDomainResolverServiceTest.php

The report never prints the blocked literals themselves. It records only pattern IDs,
pattern hashes, hit counts, matched files, invariant counts, and final exit status.
EOF
}

join_fragments() {
  local joined=""
  local fragment

  for fragment in "$@"; do
    joined+="$fragment"
  done

  printf '%s' "$joined"
}

run_rg_capture() {
  local __result_var="$1"
  shift

  local stdout_path
  local stderr_path
  local stdout_output
  local stderr_output
  local status

  stdout_path="$(mktemp)"
  stderr_path="$(mktemp)"

  set +e
  rg "$@" >"$stdout_path" 2>"$stderr_path"
  status=$?
  set -e

  stdout_output="$(cat "$stdout_path")"
  stderr_output="$(cat "$stderr_path")"
  rm -f "$stdout_path" "$stderr_path"

  if [[ "$status" -ne 0 && "$status" -ne 1 ]]; then
    echo "ERROR: residue scan failed while running ripgrep." >&2
    if [[ -n "$stderr_output" ]]; then
      printf '%s\n' "$stderr_output" >&2
    fi
    exit 2
  fi

  LAST_RG_STATUS="$status"
  printf -v "$__result_var" '%s' "$stdout_output"
}

run_check_capture() {
  local __result_var="$1"
  local check_mode="$2"
  local match_literal="$3"
  shift 3

  case "$check_mode" in
    exact-line-count)
      run_rg_capture "$__result_var" -n -x -F "$match_literal" "$@"
      ;;
    fixed-substring-count)
      run_rg_capture "$__result_var" -n -F "$match_literal" "$@"
      ;;
    line-regex-count)
      run_rg_capture "$__result_var" -n -e "$match_literal" "$@"
      ;;
    *)
      echo "ERROR: unsupported check mode: $check_mode" >&2
      exit 1
      ;;
  esac
}

count_nonempty_lines() {
  local input="$1"
  printf '%s\n' "$input" | sed '/^$/d' | wc -l | awk '{print $1}'
}

render_matched_files() {
  local matches="$1"
  printf '%s\n' "$matches" | sed '/^$/d' | cut -d: -f1 | sort -u
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root)
      REPO_ROOT="$2"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="$2"
      shift 2
      ;;
    --label)
      SCAN_LABEL="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

cd "$REPO_ROOT"

TARGETS=(
  "flutter-app/README.md"
  "flutter-app/android/keystores/tenant.properties.example"
  "laravel-app/tests/Feature/PublicWeb/WellKnownAssociationTest.php"
  "laravel-app/tests/Unit/Application/Tenants/TenantAppDomainResolverServiceTest.php"
)

MARKER_IDS=(
  "tenant_example_placeholder_brand"
  "legacy_learning_brand"
  "legacy_tenant_name"
  "legacy_tenant_brand_compound"
  "legacy_example_filename"
  "credential_like_value_a"
  "credential_like_value_b"
  "credential_like_value_c"
  "legacy_admin_package"
)

MARKER_PATTERNS=(
  "$(join_fragments 'boilerplate' 'belluga' 'tenant')"
  "$(join_fragments 'belluga' 'learning')"
  "$(join_fragments 'uni' 'fast')"
  "$(join_fragments 'gua' 'rappari')"
  "$(join_fragments 'landlord' '.properties')"
  "$(join_fragments '6xzj' 'iggF')"
  "$(join_fragments 'ahbW' '2gTE')"
  "$(join_fragments 'Secret' '!234')"
  "$(join_fragments 'com.' 'boilerplate' '.admin')"
)

CHECK_IDS=(
  "keystore_store_password_field_count"
  "keystore_store_password_placeholder"
  "keystore_key_password_field_count"
  "keystore_key_password_placeholder"
  "readme_tenantalpha_example_count"
  "readme_tenantbeta_example_count"
  "readme_tenantalpha_app_id_count"
  "readme_tenantbeta_app_id_count"
  "readme_tenantalpha_alias_count"
  "readme_tenantbeta_alias_count"
  "readme_tenantalpha_keystore_count"
  "tenant_properties_tenantalpha_example_count"
  "tenant_properties_tenantalpha_app_id_count"
  "tenant_properties_tenantalpha_alias_count"
  "tenant_properties_tenantalpha_keystore_count"
  "laravel_feature_android_identifier_count"
  "laravel_feature_ios_identifier_count"
  "laravel_feature_landlord_identifier_count"
  "laravel_feature_tenant_association_domain_count"
  "laravel_feature_tenant_association_slug_count"
  "laravel_feature_password_field_count"
  "laravel_feature_password_placeholder"
  "laravel_unit_android_identifier_count"
  "laravel_unit_ios_identifier_count"
  "laravel_unit_legacy_identifier_count"
  "laravel_unit_tenant_theta_domain_count"
  "laravel_unit_tenant_theta_slug_count"
  "laravel_unit_password_field_count"
  "laravel_unit_password_placeholder"
)

CHECK_MODES=(
  "fixed-substring-count"
  "line-regex-count"
  "fixed-substring-count"
  "line-regex-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "line-regex-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "fixed-substring-count"
  "line-regex-count"
)

CHECK_EXPECTED_COUNTS=(
  "1"
  "1"
  "1"
  "1"
  "4"
  "1"
  "2"
  "1"
  "1"
  "1"
  "1"
  "3"
  "1"
  "1"
  "1"
  "2"
  "2"
  "4"
  "8"
  "8"
  "1"
  "1"
  "2"
  "2"
  "2"
  "1"
  "2"
  "1"
  "1"
)

CHECK_TARGETS=(
  "flutter-app/android/keystores/tenant.properties.example"
  "flutter-app/android/keystores/tenant.properties.example"
  "flutter-app/android/keystores/tenant.properties.example"
  "flutter-app/android/keystores/tenant.properties.example"
  "flutter-app/README.md"
  "flutter-app/README.md"
  "flutter-app/README.md"
  "flutter-app/README.md"
  "flutter-app/README.md"
  "flutter-app/README.md"
  "flutter-app/README.md"
  "flutter-app/android/keystores/tenant.properties.example"
  "flutter-app/android/keystores/tenant.properties.example"
  "flutter-app/android/keystores/tenant.properties.example"
  "flutter-app/android/keystores/tenant.properties.example"
  "laravel-app/tests/Feature/PublicWeb/WellKnownAssociationTest.php"
  "laravel-app/tests/Feature/PublicWeb/WellKnownAssociationTest.php"
  "laravel-app/tests/Feature/PublicWeb/WellKnownAssociationTest.php"
  "laravel-app/tests/Feature/PublicWeb/WellKnownAssociationTest.php"
  "laravel-app/tests/Feature/PublicWeb/WellKnownAssociationTest.php"
  "laravel-app/tests/Feature/PublicWeb/WellKnownAssociationTest.php"
  "laravel-app/tests/Feature/PublicWeb/WellKnownAssociationTest.php"
  "laravel-app/tests/Unit/Application/Tenants/TenantAppDomainResolverServiceTest.php"
  "laravel-app/tests/Unit/Application/Tenants/TenantAppDomainResolverServiceTest.php"
  "laravel-app/tests/Unit/Application/Tenants/TenantAppDomainResolverServiceTest.php"
  "laravel-app/tests/Unit/Application/Tenants/TenantAppDomainResolverServiceTest.php"
  "laravel-app/tests/Unit/Application/Tenants/TenantAppDomainResolverServiceTest.php"
  "laravel-app/tests/Unit/Application/Tenants/TenantAppDomainResolverServiceTest.php"
  "laravel-app/tests/Unit/Application/Tenants/TenantAppDomainResolverServiceTest.php"
)

CHECK_MATCHES=(
  "storePassword="
  "^storePassword=<storePassword>\r?$"
  "keyPassword="
  "^keyPassword=<keyPassword>\r?$"
  "tenantalpha"
  "tenantbeta"
  "com.example.tenantalpha.app"
  "com.example.tenantbeta.app"
  "tenantalpha-alias"
  "tenantbeta-alias"
  "tenantalpha-release-key.jks"
  "tenantalpha"
  "com.example.tenantalpha.app"
  "tenantalpha-alias"
  "tenantalpha-release-key.jks"
  "com.example.tenant.android"
  "com.example.tenant.ios"
  "com.example.landlord.admin"
  "tenant-association.test"
  "tenant-association"
  "'password' => '"
  "'password' => 'fixture-password-placeholder'\\],[[:space:]]*$"
  "com.example.tenant.android"
  "com.example.tenant.ios"
  "legacy.example.tenant.app"
  "tenant-theta.test"
  "tenant-theta"
  "'password' => '"
  "'password' => 'fixture-password-placeholder'\\],[[:space:]]*$"
)

for target in "${TARGETS[@]}"; do
  if [[ ! -f "$target" ]]; then
    echo "ERROR: required scan target missing: $target" >&2
    exit 1
  fi
done

render_report() {
  local overall_marker_hit_count="$1"
  local failed_check_count="$2"
  local overall_failure_count="$3"
  local exit_status="$4"

  {
    echo "Tenant Example Neutralization Guard"
    echo "scan_label: $SCAN_LABEL"
    echo "repo_root: $REPO_ROOT"
    echo "mode: host-side-case-insensitive-fixed-string-with-slot-allowlists"
    echo "target_count: ${#TARGETS[@]}"
    echo "targets:"
    for target in "${TARGETS[@]}"; do
      echo "  - $target"
    done
    echo "marker_count: ${#MARKER_IDS[@]}"
    echo "markers:"

    local index
    for index in "${!MARKER_IDS[@]}"; do
      local pattern_id="${MARKER_IDS[$index]}"
      local pattern="${MARKER_PATTERNS[$index]}"
      local pattern_hash
      local matches
      local hit_count
      local matched_files

      pattern_hash="$(printf '%s' "$pattern" | sha256sum | awk '{print $1}')"
      run_rg_capture matches -n -F -i -e "$pattern" "${TARGETS[@]}"
      hit_count="$(count_nonempty_lines "$matches")"
      matched_files="$(render_matched_files "$matches")"

      echo "  - id: $pattern_id"
      echo "    pattern_sha256: $pattern_hash"
      echo "    hit_count: $hit_count"

      if [[ -n "$matched_files" ]]; then
        echo "    matched_files:"
        while IFS= read -r file_path; do
          [[ -n "$file_path" ]] && echo "      - $file_path"
        done <<< "$matched_files"
      else
        echo "    matched_files: []"
      fi
    done

    echo "check_count: ${#CHECK_IDS[@]}"
    echo "checks:"

    for index in "${!CHECK_IDS[@]}"; do
      local check_id="${CHECK_IDS[$index]}"
      local check_mode="${CHECK_MODES[$index]}"
      local expected_count="${CHECK_EXPECTED_COUNTS[$index]}"
      local target_csv="${CHECK_TARGETS[$index]}"
      local match_literal="${CHECK_MATCHES[$index]}"
      local actual_matches
      local actual_count
      local status="pass"
      local target_args=()
      local target_path

      IFS=',' read -r -a target_args <<< "$target_csv"
      run_check_capture actual_matches "$check_mode" "$match_literal" "${target_args[@]}"
      actual_count="$(count_nonempty_lines "$actual_matches")"

      if [[ "$actual_count" != "$expected_count" ]]; then
        status="fail"
      fi

      echo "  - id: $check_id"
      echo "    mode: $check_mode"
      echo "    expected_count: $expected_count"
      echo "    actual_count: $actual_count"
      echo "    status: $status"
      echo "    targets:"
      for target_path in "${target_args[@]}"; do
        echo "      - $target_path"
      done
    done

    echo "overall_marker_hit_count: $overall_marker_hit_count"
    echo "failed_check_count: $failed_check_count"
    echo "overall_failure_count: $overall_failure_count"
    echo "exit_status: $exit_status"
  }
}

overall_marker_args=(-n -F -i)
for pattern in "${MARKER_PATTERNS[@]}"; do
  overall_marker_args+=(-e "$pattern")
done
overall_marker_args+=("${TARGETS[@]}")
run_rg_capture overall_matches "${overall_marker_args[@]}"
overall_marker_hit_count="$(count_nonempty_lines "$overall_matches")"

failed_check_count=0
for index in "${!CHECK_IDS[@]}"; do
  target_csv="${CHECK_TARGETS[$index]}"
  match_literal="${CHECK_MATCHES[$index]}"
  expected_count="${CHECK_EXPECTED_COUNTS[$index]}"
  check_mode="${CHECK_MODES[$index]}"
  target_args=()
  IFS=',' read -r -a target_args <<< "$target_csv"
  run_check_capture check_matches "$check_mode" "$match_literal" "${target_args[@]}"
  actual_count="$(count_nonempty_lines "$check_matches")"
  if [[ "$actual_count" != "$expected_count" ]]; then
    failed_check_count=$((failed_check_count + 1))
  fi
done

overall_failure_count=$((overall_marker_hit_count + failed_check_count))

if [[ "$overall_failure_count" -gt 0 ]]; then
  exit_status=1
else
  exit_status=0
fi

if [[ -n "$OUTPUT_PATH" ]]; then
  mkdir -p "$(dirname "$OUTPUT_PATH")"
  render_report "$overall_marker_hit_count" "$failed_check_count" "$overall_failure_count" "$exit_status" > "$OUTPUT_PATH"
else
  render_report "$overall_marker_hit_count" "$failed_check_count" "$overall_failure_count" "$exit_status"
fi

exit "$exit_status"
