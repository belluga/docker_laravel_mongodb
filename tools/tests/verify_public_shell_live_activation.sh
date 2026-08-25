#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
compose_network="${PUBLIC_SHELL_PROOF_NETWORK:-docker_laravel_mongodb_app-network}"
proof_suffix="${PUBLIC_SHELL_PROOF_SUFFIX:-$(date +%s)-$$}"
tenant_host="${PUBLIC_SHELL_PROOF_TENANT_HOST:-tenant-shell-proof-${proof_suffix}.test}"
proof_port="${PUBLIC_SHELL_PROOF_PORT:-18090}"
app_image="${PUBLIC_SHELL_PROOF_APP_IMAGE:-project-app:local}"
nginx_image="${PUBLIC_SHELL_PROOF_NGINX_IMAGE:-project-nginx:local}"
overlay_fixture="${PUBLIC_SHELL_PROJECT_OVERLAY_FILE:-$repo_root/tools/tests/fixtures/public_shell_routes.neutral.conf}"
laravel_fixture="${PUBLIC_SHELL_LARAVEL_CONFIG_FILE:-$repo_root/laravel-app/tests/Fixtures/PublicWeb/project_public_shell_routes_neutral.php}"
profile_slug="${PUBLIC_SHELL_PROOF_PROFILE_SLUG:-public-shell-proof-profile-${proof_suffix}}"
event_slug="${PUBLIC_SHELL_PROOF_EVENT_SLUG:-public-shell-proof-event-${proof_suffix}}"
proof_account_name="${PUBLIC_SHELL_PROOF_ACCOUNT_NAME:-Public Shell Proof Account ${proof_suffix}}"
proof_account_document="${PUBLIC_SHELL_PROOF_ACCOUNT_DOCUMENT:-public-shell-proof-document-${proof_suffix}}"
proof_domain_ephemeral=1

if [[ -n "${PUBLIC_SHELL_PROOF_TENANT_HOST:-}" ]]; then
  proof_domain_ephemeral=0
fi

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    printf 'Required file not found: %s\n' "$path" >&2
    exit 1
  fi
}

assert_same_inventory() {
  local expected="$1"
  local actual="$2"
  local label="$3"

  if ! diff -u "$expected" "$actual"; then
    printf 'Public-shell inventory mismatch: %s\n' "$label" >&2
    exit 1
  fi
}

known_expected_inventory_path() {
  local path="$1"

  case "$(basename "$path")" in
    project_public_shell_routes_neutral.php)
      printf '%s\n' "$repo_root/tools/tests/fixtures/public_shell_routes.neutral.expected.tsv"
      ;;
    project_public_shell_routes.php)
      printf '%s\n' "$repo_root/tools/tests/fixtures/public_shell_routes.belluga.expected.tsv"
      ;;
    *)
      return 1
      ;;
  esac
}

parse_laravel_route_contract() {
  local path="$1"
  php -r '
    $config = require $argv[1];
    if (! is_array($config)) {
        fwrite(STDERR, "Laravel project route config must return an array.\n");
        exit(1);
    }
    $routes = $config["routes"] ?? [];
    if (! is_array($routes)) {
        fwrite(STDERR, "Laravel project route config must declare routes as an array.\n");
        exit(1);
    }
    $entries = [];
    foreach ($routes as $route) {
        $routeId = trim((string) ($route["route_id"] ?? ""));
        $path = trim((string) ($route["path"] ?? ""));
        $shape = trim((string) ($route["shape"] ?? ""));
        $semantic = trim((string) ($route["semantic"] ?? ""));
        if ($routeId === "" || $path === "" || $shape === "" || $semantic === "") {
            fwrite(STDERR, "Laravel project route config contains an incomplete route entry.\n");
            exit(1);
        }
        $entries[] = implode("\t", [$routeId, $path, $shape, $semantic]);
    }
    sort($entries);
    echo implode(PHP_EOL, $entries);
    if ($entries !== []) {
        echo PHP_EOL;
    }
  ' "$path"
}

parse_laravel_route_definitions() {
  local path="$1"
  php -r '
    $config = require $argv[1];
    if (! is_array($config)) {
        fwrite(STDERR, "Laravel project route config must return an array.\n");
        exit(1);
    }
    $routes = $config["routes"] ?? [];
    if (! is_array($routes)) {
        fwrite(STDERR, "Laravel project route config must declare routes as an array.\n");
        exit(1);
    }
    foreach ($routes as $route) {
        $routeId = trim((string) ($route["route_id"] ?? ""));
        $path = trim((string) ($route["path"] ?? ""));
        $shape = trim((string) ($route["shape"] ?? ""));
        $semantic = trim((string) ($route["semantic"] ?? ""));
        if ($routeId === "" || $path === "" || $shape === "" || $semantic === "") {
            fwrite(STDERR, "Laravel project route config contains an incomplete route entry.\n");
            exit(1);
        }
        if (! in_array($shape, ["exact", "one_segment"], true)) {
            fwrite(STDERR, "Laravel project route config contains an unsupported shape.\n");
            exit(1);
        }
        echo implode("\t", [$routeId, $path, $shape, $semantic]).PHP_EOL;
    }
  ' "$path"
}

seed_runtime_fixtures() {
  docker compose exec -T app php artisan tinker --execute='
    $tenant = App\Models\Landlord\Tenant::query()->first();
    if ($tenant === null) {
        throw new RuntimeException("No tenant available for public-shell live proof.");
    }
    $tenant->makeCurrent();

    $domain = $tenant->domains()
        ->withTrashed()
        ->where("type", App\Models\Landlord\Tenant::DOMAIN_TYPE_WEB)
        ->where("path", "'"$tenant_host"'")
        ->first();
    if ($domain === null) {
        $tenant->domains()->create([
            "type" => App\Models\Landlord\Tenant::DOMAIN_TYPE_WEB,
            "path" => "'"$tenant_host"'",
        ]);
    } else {
        $domain->restore();
    }

    App\Models\Tenants\AccountProfile::withTrashed()->where("slug", "'"$profile_slug"'")->forceDelete();
    App\Models\Tenants\EventOccurrence::withTrashed()->where("slug", "'"$event_slug"'")->forceDelete();
    App\Models\Tenants\Account::withTrashed()->where("document", "'"$proof_account_document"'")->forceDelete();
    App\Models\Tenants\Account::withTrashed()->where("name", "'"$proof_account_name"'")->forceDelete();

    $account = App\Models\Tenants\Account::create([
        "name" => "'"$proof_account_name"'",
        "document" => "'"$proof_account_document"'",
    ]);

    $profile = App\Models\Tenants\AccountProfile::create([
        "account_id" => (string) $account->_id,
        "profile_type" => "artist",
        "display_name" => "Public Shell Proof Profile",
        "slug" => "'"$profile_slug"'",
        "avatar_url" => "https://'"$tenant_host"'/media/public-shell-proof-avatar.png",
        "cover_url" => "https://'"$tenant_host"'/media/public-shell-proof-cover.png",
        "is_active" => true,
    ]);
    $profile->setAttribute("description", "<p>Live proof profile description.</p>");
    $profile->save();

    $event = App\Models\Tenants\EventOccurrence::create([
        "slug" => "'"$event_slug"'",
        "title" => "Public Shell Proof Event",
        "is_event_published" => true,
        "cover_url" => "https://'"$tenant_host"'/media/public-shell-proof-event.png",
    ]);
    $event->setAttribute("description", "<p>Live proof event description.</p>");
    $event->save();
  ' >/dev/null
}

cleanup_runtime_fixtures() {
  docker compose exec -T app php artisan tinker --execute='
    $tenant = App\Models\Landlord\Tenant::query()->first();
    if ($tenant === null) {
        exit;
    }
    $tenant->makeCurrent();
    App\Models\Tenants\AccountProfile::withTrashed()->where("slug", "'"$profile_slug"'")->forceDelete();
    App\Models\Tenants\EventOccurrence::withTrashed()->where("slug", "'"$event_slug"'")->forceDelete();
    App\Models\Tenants\Account::withTrashed()->where("document", "'"$proof_account_document"'")->forceDelete();
    App\Models\Tenants\Account::withTrashed()->where("name", "'"$proof_account_name"'")->forceDelete();
    if ('"$proof_domain_ephemeral"' === '1') {
        $tenant->domains()
            ->withTrashed()
            ->where("type", App\Models\Landlord\Tenant::DOMAIN_TYPE_WEB)
            ->where("path", "'"$tenant_host"'")
            ->forceDelete();
    }
  ' >/dev/null 2>&1 || true
}

wait_for_command() {
  local command="$1"
  local attempts="${2:-30}"
  local sleep_seconds="${3:-1}"
  local index=1

  while (( index <= attempts )); do
    if eval "$command" >/dev/null 2>&1; then
      return 0
    fi

    sleep "$sleep_seconds"
    index=$((index + 1))
  done

  return 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    printf 'Expected %s to contain: %s\n' "$label" "$needle" >&2
    exit 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    printf 'Expected %s not to contain: %s\n' "$label" "$needle" >&2
    exit 1
  fi
}

capture_live_runtime_state() {
  live_runtime_uid="$(docker compose exec -T app id -u www-data)"
  live_runtime_gid="$(docker compose exec -T app id -g www-data)"
  live_storage_owner="$(docker compose exec -T app stat -c '%u:%g' /var/www/storage)"
  live_bootstrap_cache_owner="$(docker compose exec -T app stat -c '%u:%g' /var/www/bootstrap/cache)"
}

assert_live_runtime_state() {
  local current_storage_owner current_bootstrap_cache_owner

  current_storage_owner="$(docker compose exec -T app stat -c '%u:%g' /var/www/storage)"
  current_bootstrap_cache_owner="$(docker compose exec -T app stat -c '%u:%g' /var/www/bootstrap/cache)"

  if [[ "$current_storage_owner" != "$live_storage_owner" || "$current_bootstrap_cache_owner" != "$live_bootstrap_cache_owner" ]]; then
    printf 'Disposable proof changed live runtime ownership: storage=%s (expected %s), bootstrap/cache=%s (expected %s)\n' \
      "$current_storage_owner" "$live_storage_owner" "$current_bootstrap_cache_owner" "$live_bootstrap_cache_owner" >&2
    exit 1
  fi

  if ! docker compose exec -T app gosu www-data sh -lc '
    for directory in /var/www/storage/framework/views /var/www/bootstrap/cache; do
      probe="$directory/.public-shell-live-activation-probe"
      touch "$probe"
      rm -f "$probe"
    done
  '; then
    printf 'Live app user lost write access after disposable public-shell proof.\n' >&2
    exit 1
  fi
}

require_file "$overlay_fixture"
require_file "$laravel_fixture"

expected_inventory_path=''
if expected_inventory_path="$(known_expected_inventory_path "$laravel_fixture" 2>/dev/null)"; then
  require_file "$expected_inventory_path"
fi

declare -a shell_exact_paths=()
profile_route_path=''
event_route_path=''
invite_route_path=''
static_route_path=''

while IFS=$'\t' read -r route_id path shape semantic; do
  if [[ -z "$route_id" ]]; then
    continue
  fi

  if [[ "$semantic" == "shell" && "$shape" == "exact" ]]; then
    shell_exact_paths+=("$path")
    continue
  fi

  if [[ -z "$profile_route_path" && "$semantic" == "account_profile_metadata" && "$shape" == "one_segment" ]]; then
    profile_route_path="$path"
    continue
  fi

  if [[ -z "$event_route_path" && "$semantic" == "event_metadata" && "$shape" == "one_segment" ]]; then
    event_route_path="$path"
    continue
  fi

  if [[ -z "$invite_route_path" && "$semantic" == "invite_metadata_test" && "$shape" == "exact" ]]; then
    invite_route_path="$path"
    continue
  fi

  if [[ -z "$static_route_path" && "$semantic" == "static_asset_metadata_test" && "$shape" == "one_segment" ]]; then
    static_route_path="$path"
  fi
done < <(parse_laravel_route_definitions "$laravel_fixture")

temp_dir="$(mktemp -d)"
app_container="public-shell-proof-app-$$"
nginx_container="public-shell-proof-nginx-$$"
capture_live_runtime_state

cleanup() {
  docker rm -f "$nginx_container" >/dev/null 2>&1 || true
  docker rm -f "$app_container" >/dev/null 2>&1 || true
  cleanup_runtime_fixtures
  rm -rf "$temp_dir"
}
trap cleanup EXIT

if [[ -n "$expected_inventory_path" ]]; then
  actual_inventory="$temp_dir/laravel-contract.entries"
  parse_laravel_route_contract "$laravel_fixture" >"$actual_inventory"
  assert_same_inventory "$expected_inventory_path" "$actual_inventory" "known Laravel fixture route inventory"
fi

mkdir -p \
  "$temp_dir/bootstrap-cache" \
  "$temp_dir/project/nginx" \
  "$temp_dir/project/laravel" \
  "$temp_dir/storage/app/public" \
  "$temp_dir/storage/framework/cache" \
  "$temp_dir/storage/framework/sessions" \
  "$temp_dir/storage/framework/testing" \
  "$temp_dir/storage/framework/views" \
  "$temp_dir/storage/logs"
touch "$temp_dir/storage/logs/laravel.log"
cp "$overlay_fixture" "$temp_dir/project/nginx/routes.conf"
cp "$laravel_fixture" "$temp_dir/project/laravel/public_shell_routes.php"
cp -R "$repo_root/laravel-app/config" "$temp_dir/config"

cat >"$temp_dir/config/favorites.php" <<'PHP'
<?php

declare(strict_types=1);

return [
    'default_registry_key' => 'account_profile',
    'registries' => [
        [
            'registry_key' => 'account_profile',
            'target_type' => 'account_profile',
        ],
    ],
    'publicly_navigable_profile_types' => ['artist'],
];
PHP

sed "s/\${DOMAIN}/${tenant_host}/g; s/fastcgi_pass app:9000;/fastcgi_pass app-proof:9000;/" \
  "$repo_root/docker/nginx/local.conf.template" >"$temp_dir/default.conf"

# The disposable app deliberately uses the live PHP UID; keep this throwaway tree removable by the invoking host user.
chmod -R a+rwx "$temp_dir"

seed_runtime_fixtures

docker run -d --rm \
  --name "$app_container" \
  --network "$compose_network" \
  --network-alias app-proof \
  -v "$repo_root/laravel-app:/var/www" \
  -v "$repo_root/web-app:/opt/web-shell:ro" \
  -v "$temp_dir/project:/opt/project:ro" \
  -v "$temp_dir/config:/var/www/config" \
  -v "$temp_dir/bootstrap-cache:/var/www/bootstrap/cache" \
  -v "$temp_dir/storage:/var/www/storage" \
  -e LOCAL_UID="$live_runtime_uid" \
  -e LOCAL_GID="$live_runtime_gid" \
  -e FLUTTER_WEB_SHELL_PATH=/opt/web-shell/index.html \
  -e PUBLIC_WEB_PROJECT_ROUTE_CONFIG_FILE=/opt/project/laravel/public_shell_routes.php \
  "$app_image" php-fpm >/dev/null

wait_for_command "docker exec $app_container php -r 'exit(@fsockopen(\"127.0.0.1\", 9000) ? 0 : 1);'" 60 1 || {
  printf 'Timed out waiting for disposable public-shell proof app container.\n' >&2
  exit 1
}

docker run -d --rm \
  --name "$nginx_container" \
  --network "$compose_network" \
  -p "${proof_port}:80" \
  --entrypoint nginx \
  -v "$temp_dir/default.conf:/etc/nginx/conf.d/default.conf:ro" \
  -v "$temp_dir/project/nginx:/etc/nginx/project:ro" \
  -v "$repo_root/web-app:/opt/web-shell:ro" \
  -v "$temp_dir/storage:/var/www/storage" \
  "$nginx_image" -g 'daemon off;' >/dev/null

wait_for_command "curl -fsS -H 'Host: ${tenant_host}' http://127.0.0.1:${proof_port}/ >/dev/null" 30 1 || {
  printf 'Timed out waiting for disposable public-shell proof nginx container.\n' >&2
  exit 1
}

root_response="$(curl -fsS -H "Host: ${tenant_host}" "http://127.0.0.1:${proof_port}/")"
assert_contains "$root_response" "<title>" "root response"
assert_contains "$root_response" "<link rel=\"canonical\" href=\"http://${tenant_host}/\">" "root response"
assert_not_contains "$root_response" "Old Shell Title" "root response"

for shell_path in "${shell_exact_paths[@]}"; do
  shell_response="$(curl -fsS -H "Host: ${tenant_host}" "http://127.0.0.1:${proof_port}${shell_path}")"
  assert_contains "$shell_response" "<title>" "shell response (${shell_path})"
  assert_contains "$shell_response" "<link rel=\"canonical\" href=\"http://${tenant_host}${shell_path}\">" "shell response (${shell_path})"
  assert_not_contains "$shell_response" "Old Shell Title" "shell response (${shell_path})"
done

if [[ -n "$profile_route_path" ]]; then
  profile_response="$(curl -fsS -H "Host: ${tenant_host}" "http://127.0.0.1:${proof_port}${profile_route_path}${profile_slug}")"
  assert_contains "$profile_response" "<title>Public Shell Proof Profile |" "profile response"
  assert_contains "$profile_response" '<meta name="description" content="Live proof profile description.">' "profile response"
  assert_contains "$profile_response" "<link rel=\"canonical\" href=\"http://${tenant_host}${profile_route_path}${profile_slug}\">" "profile response"
  assert_not_contains "$profile_response" "Old Shell Title" "profile response"

  profile_deep_status="$(curl -sS -o /dev/null -w '%{http_code}' -H "Host: ${tenant_host}" "http://127.0.0.1:${proof_port}${profile_route_path}${profile_slug}/extra")"
  if [[ "$profile_deep_status" != "404" ]]; then
    printf 'Expected profile deeper path to fail closed with HTTP 404, got %s\n' "$profile_deep_status" >&2
    exit 1
  fi
fi

if [[ -n "$event_route_path" ]]; then
  event_response="$(curl -fsS -H "Host: ${tenant_host}" "http://127.0.0.1:${proof_port}${event_route_path}${event_slug}")"
  assert_contains "$event_response" "<title>Public Shell Proof Event |" "event response"
  assert_contains "$event_response" '<meta name="description" content="Live proof event description.">' "event response"
  assert_contains "$event_response" "<link rel=\"canonical\" href=\"http://${tenant_host}${event_route_path}${event_slug}\">" "event response"
fi

if [[ -n "$static_route_path" ]]; then
  static_response="$(curl -fsS -H "Host: ${tenant_host}" "http://127.0.0.1:${proof_port}${static_route_path}proof-poster")"
  assert_contains "$static_response" "<title>Proof Poster |" "static response"
  assert_contains "$static_response" '<meta name="description" content="Configured static-asset metadata for Proof Poster.">' "static response"
  assert_contains "$static_response" "<link rel=\"canonical\" href=\"http://${tenant_host}${static_route_path}proof-poster\">" "static response"

  static_deep_status="$(curl -sS -o /dev/null -w '%{http_code}' -H "Host: ${tenant_host}" "http://127.0.0.1:${proof_port}${static_route_path}proof-poster/extra")"
  if [[ "$static_deep_status" != "404" ]]; then
    printf 'Expected static deeper path to fail closed with HTTP 404, got %s\n' "$static_deep_status" >&2
    exit 1
  fi
fi

if [[ -n "$invite_route_path" ]]; then
  invite_response="$(curl -fsS -H "Host: ${tenant_host}" "http://127.0.0.1:${proof_port}${invite_route_path}?code=LIVE123")"
  assert_contains "$invite_response" "<title>Invite Landing |" "invite response"
  assert_contains "$invite_response" '<meta name="description" content="Open invite code LIVE123 from the configured project route.">' "invite response"
fi

assert_live_runtime_state

printf 'Public-shell live activation verified through disposable app+nginx runtime.\n'
