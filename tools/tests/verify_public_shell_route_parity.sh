#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
overlay_path="${PUBLIC_SHELL_PROJECT_OVERLAY_FILE:-$repo_root/tools/tests/fixtures/public_shell_routes.neutral.conf}"
laravel_config_path="${PUBLIC_SHELL_LARAVEL_CONFIG_FILE:-$repo_root/laravel-app/tests/Fixtures/PublicWeb/project_public_shell_routes_neutral.php}"
deep_link_policy_path="${DEEP_LINK_ROUTE_POLICY_CONFIG_FILE:-}"
published_example_deep_link_policy_path="$repo_root/project/laravel/deep_link_route_policy.example.php"
domain="${PUBLIC_SHELL_TEST_DOMAIN:-public-shell.test}"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    printf 'Required file not found: %s\n' "$path" >&2
    exit 1
  fi
}

parse_root_public_shell_locations() {
  local path="$1"
  php -r '
    $lines = file($argv[1], FILE_IGNORE_NEW_LINES);
    if ($lines === false) {
        fwrite(STDERR, "Unable to read {$argv[1]}\n");
        exit(1);
    }
    $current = null;
    $entries = [];
    foreach ($lines as $line) {
        if (preg_match("/^\s*location\s+(=|\^~)\s+(\S+)\s*\{\s*$/", $line, $matches) === 1) {
            $current = [$matches[1], $matches[2]];
            continue;
        }
        if ($current !== null && str_contains($line, "try_files /__tenant_public_shell__ /index.php?\$query_string;")) {
            $entries[] = ($current[0] === "=" ? "exact" : "prefix")
                ."\t".$current[1]
                ."\t".($current[0] === "=" ? "exact" : "one_segment");
        }
        if ($current !== null && preg_match("/^\s*}\s*$/", $line) === 1) {
            $current = null;
        }
    }
    sort($entries);
    echo implode(PHP_EOL, $entries);
    if ($entries !== []) {
        echo PHP_EOL;
    }
  ' "$path"
}

parse_project_public_shell_locations() {
  local path="$1"
  php -r '
    $lines = file($argv[1], FILE_IGNORE_NEW_LINES);
    if ($lines === false) {
        fwrite(STDERR, "Unable to read {$argv[1]}\n");
        exit(1);
    }
    $current = null;
    $routeId = null;
    $entries = [];
    foreach ($lines as $line) {
        if (preg_match("/^\s*location\s+(=|\^~)\s+(\S+)\s*\{\s*$/", $line, $matches) === 1) {
            $current = [$matches[1], $matches[2]];
            $routeId = null;
            continue;
        }
        if ($current !== null && preg_match("/^\s*#\s*public_shell_route_id:\s*([a-z][a-z0-9_-]{0,63})\s*$/", $line, $matches) === 1) {
            $routeId = $matches[1];
            continue;
        }
        if ($current !== null && str_contains($line, "try_files /__tenant_public_shell__ /index.php?\$query_string;")) {
            if ($routeId === null) {
                fwrite(STDERR, "Managed public-shell location is missing # public_shell_route_id in {$argv[1]}.\n");
                exit(1);
            }
            $entries[] = $routeId
                ."\t".($current[0] === "=" ? "exact" : "prefix")
                ."\t".$current[1]
                ."\t".($current[0] === "=" ? "exact" : "one_segment");
        }
        if ($current !== null && preg_match("/^\s*}\s*$/", $line) === 1) {
            $current = null;
            $routeId = null;
        }
    }
    sort($entries);
    echo implode(PHP_EOL, $entries);
    if ($entries !== []) {
        echo PHP_EOL;
    }
  ' "$path"
}

parse_laravel_project_routes() {
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
        $shape = trim((string) ($route["shape"] ?? ""));
        $path = trim((string) ($route["path"] ?? ""));
        if ($routeId === "" || $shape === "" || $path === "") {
            fwrite(STDERR, "Laravel project route config contains an incomplete route entry.\n");
            exit(1);
        }
        if (preg_match("/^[a-z][a-z0-9_-]{0,63}$/", $routeId) !== 1) {
            fwrite(STDERR, "Laravel project route config contains an invalid route_id.\n");
            exit(1);
        }
        if (! in_array($shape, ["exact", "one_segment"], true)) {
            fwrite(STDERR, "Laravel project route config contains an unsupported shape.\n");
            exit(1);
        }
        $entries[] = $routeId
            ."\t".($shape === "exact" ? "exact" : "prefix")
            ."\t".$path
            ."\t".$shape;
    }
    sort($entries);
    echo implode(PHP_EOL, $entries);
    if ($entries !== []) {
        echo PHP_EOL;
    }
  ' "$path"
}

parse_laravel_project_route_contract() {
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
        $entries[] = $routeId."\t".$path."\t".$shape."\t".$semantic;
    }
    sort($entries);
    echo implode(PHP_EOL, $entries);
    if ($entries !== []) {
        echo PHP_EOL;
    }
  ' "$path"
}

parse_companion_inventory_projection() {
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
    $entries = [
        "privacy_policy\tgeneric_builtin\texact",
        "root_landing\tgeneric_builtin\texact",
    ];
    foreach ($routes as $route) {
        $routeId = trim((string) ($route["route_id"] ?? ""));
        $shape = trim((string) ($route["shape"] ?? ""));
        if ($routeId === "" || $shape === "") {
            fwrite(STDERR, "Laravel project route config contains an incomplete route entry.\n");
            exit(1);
        }
        if (! in_array($shape, ["exact", "one_segment"], true)) {
            fwrite(STDERR, "Laravel project route config contains an unsupported shape.\n");
            exit(1);
        }
        $entries[] = $routeId."\tpublic_shell\t".$shape;
    }
    sort($entries);
    echo implode(PHP_EOL, $entries);
    if ($entries !== []) {
        echo PHP_EOL;
    }
  ' "$path"
}

compute_companion_inventory_snapshot() {
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
    $inventory = array_merge([
        [
            "route_id" => "root_landing",
            "shape" => "exact",
            "path" => "/",
            "kind" => "generic_builtin",
        ],
        [
            "route_id" => "privacy_policy",
            "shape" => "exact",
            "path" => "/privacy-policy",
            "kind" => "generic_builtin",
        ],
    ], $routes);
    $projection = [];
    foreach ($inventory as $entry) {
        $routeId = trim((string) ($entry["route_id"] ?? ""));
        $kind = trim((string) ($entry["kind"] ?? "public_shell"));
        $shape = trim((string) ($entry["shape"] ?? ""));
        $routePath = trim((string) ($entry["path"] ?? ""));
        if ($routeId === "" || $shape === "" || $routePath === "") {
            fwrite(STDERR, "Companion inventory snapshot entry is incomplete.\n");
            exit(1);
        }
        $canonicalShape = match ($shape) {
            "exact" => "exact:".$routePath,
            "one_segment" => "one_segment:".$routePath."{segment}",
            default => throw new RuntimeException("Unsupported companion shape ".$shape),
        };
        $projection[] = [
            "route_id" => $routeId,
            "kind" => $kind,
            "canonical_shape" => $canonicalShape,
        ];
    }
    usort($projection, static fn (array $left, array $right): int
        => [$left["route_id"], $left["kind"], $left["canonical_shape"]]
        <=> [$right["route_id"], $right["kind"], $right["canonical_shape"]]
    );
    $json = json_encode($projection, JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR);
    echo "companion_route_inventory_projection_v1\t".hash("sha256", $json).PHP_EOL;
  ' "$path"
}

parse_deep_link_companion_bindings() {
  local path="$1"
  php -r '
    $config = require $argv[1];
    if (! is_array($config)) {
        fwrite(STDERR, "Deep-link route policy config must return an array.\n");
        exit(1);
    }
    $routes = $config["routes"] ?? [];
    if (! is_array($routes)) {
        fwrite(STDERR, "Deep-link route policy config must declare routes as an array.\n");
        exit(1);
    }
    $entries = [];
    foreach ($routes as $route) {
        $routeId = trim((string) ($route["route_id"] ?? ""));
        $ingressRequirement = trim((string) ($route["ingress_requirement"] ?? ""));
        if ($routeId === "" || $ingressRequirement === "") {
            fwrite(STDERR, "Deep-link route policy contains an incomplete route entry.\n");
            exit(1);
        }
        if ($ingressRequirement === "public_shell_required") {
            if (array_key_exists("path", $route) || array_key_exists("shape", $route)) {
                fwrite(STDERR, "public_shell_required route must not restate local path/shape.\n");
                exit(1);
            }
            $publicShellRouteId = trim((string) ($route["public_shell_route_id"] ?? ""));
            if ($publicShellRouteId === "") {
                fwrite(STDERR, "public_shell_required route is missing public_shell_route_id.\n");
                exit(1);
            }
            $entries[] = $routeId."\t".$publicShellRouteId;
            continue;
        }
        if ($ingressRequirement === "continuation_only") {
            if (array_key_exists("public_shell_route_id", $route)) {
                fwrite(STDERR, "continuation_only route must not declare public_shell_route_id.\n");
                exit(1);
            }
            continue;
        }
        fwrite(STDERR, sprintf(
            "Deep-link route `%s` declares unsupported ingress_requirement `%s`.\n",
            $routeId,
            $ingressRequirement
        ));
        exit(1);
    }
    sort($entries);
    echo implode(PHP_EOL, $entries);
    if ($entries !== []) {
        echo PHP_EOL;
    }
  ' "$path"
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

known_default_deep_link_policy_path() {
  local path="$1"

  case "$(basename "$path")" in
    project_public_shell_routes_neutral.php)
      printf '%s\n' "$repo_root/laravel-app/tests/Fixtures/DeepLinks/project_deep_link_route_policy_generic_required.php"
      ;;
    project_public_shell_routes.php)
      printf '%s\n' "$repo_root/laravel-app/tests/Fixtures/DeepLinks/project_deep_link_route_policy_belluga.php"
      ;;
    *)
      return 1
      ;;
  esac
}

render_template() {
  local template_path="$1"
  local output_path="$2"

  sed "s/\${DOMAIN}/${domain}/g" "$template_path" >"$output_path"
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

assert_no_root_overlap() {
  local root_entries="$1"
  local project_entries="$2"
  local root_paths="$temp_dir/root-paths-$(basename "$root_entries")"
  local project_paths="$temp_dir/project-paths-$(basename "$project_entries")"
  local overlaps

  cut -f2 "$root_entries" | sort -u >"$root_paths"
  cut -f3 "$project_entries" | sort -u >"$project_paths"
  overlaps="$(grep -Fxf "$project_paths" "$root_paths" || true)"

  if [[ -n "$overlaps" ]]; then
    printf 'Root template still exposes one or more project-owned public-shell routes.\n' >&2
    printf '%s\n' "$overlaps" >&2
    exit 1
  fi
}

assert_no_reserved_generic_overlap() {
  local project_entries="$1"

  php -r '
    $entries = file($argv[1], FILE_IGNORE_NEW_LINES);
    if ($entries === false) {
        fwrite(STDERR, "Unable to read {$argv[1]}\n");
        exit(1);
    }

    $reservedExact = [
        "/",
        "/open-app",
        "/privacy-policy",
        "/.well-known/assetlinks.json",
        "/.well-known/apple-app-site-association",
        "/manifest.json",
        "/favicon.ico",
        "/logo-dark.png",
        "/logo-light.png",
        "/icon-dark.png",
        "/icon-light.png",
        "/index.html",
        "/main.dart.js",
        "/flutter_bootstrap.js",
        "/flutter_service_worker.js",
        "/build_metadata.json",
        "/version.json",
    ];
    $reservedPrefix = [
        "/.well-known/",
        "/icon/",
        "/assets/",
        "/storage/",
    ];

    foreach ($entries as $line) {
        $line = trim($line);
        if ($line === "") {
            continue;
        }

        [$routeId, $kind, $path] = explode("\t", $line, 4);
        if ($kind === "exact") {
            if (in_array($path, $reservedExact, true)) {
                fwrite(STDERR, "Project route {$routeId} claims reserved generic exact path {$path}.\n");
                exit(1);
            }
            foreach ($reservedPrefix as $prefix) {
                if (str_starts_with($path, $prefix)) {
                    fwrite(STDERR, "Project route {$routeId} claims reserved generic path family {$prefix} via {$path}.\n");
                    exit(1);
                }
            }
            continue;
        }

        foreach ($reservedPrefix as $prefix) {
            if (str_starts_with($path, $prefix) || str_starts_with($prefix, $path)) {
                fwrite(STDERR, "Project route {$routeId} claims reserved generic path family {$prefix} via {$path}.\n");
                exit(1);
            }
        }

        foreach ($reservedExact as $reservedPath) {
            if (str_starts_with($reservedPath, $path)) {
                fwrite(STDERR, "Project route {$routeId} would capture reserved generic exact path {$reservedPath} via {$path}.\n");
                exit(1);
            }
        }
    }
  ' "$project_entries"
}

assert_example_extension_contract() {
  local path="$1"

  php -r '
    $config = require $argv[1];
    if (! is_array($config)) {
        fwrite(STDERR, "Laravel project route config must return an array.\n");
        exit(1);
    }

    $extensions = $config["extensions"] ?? [];
    if (! is_array($extensions)) {
        fwrite(STDERR, "Laravel project route config must declare extensions as an array.\n");
        exit(1);
    }

    foreach ($extensions as $extension) {
        $extensionId = trim((string) ($extension["extension_id"] ?? ""));
        $serviceContainerId = trim((string) ($extension["service_container_id"] ?? ""));

        if ($extensionId === "" || $serviceContainerId === "") {
            fwrite(STDERR, "Published example extension contract is incomplete.\n");
            exit(1);
        }

        if (
            class_exists($serviceContainerId)
            || interface_exists($serviceContainerId)
            || str_starts_with($serviceContainerId, "project.")
        ) {
            continue;
        }

        fwrite(STDERR, sprintf(
            "Published example extension `%s` in `%s` must use a resolvable class/interface or an explicit `project.` placeholder service_container_id.\n",
            $extensionId,
            $argv[1]
        ));
        exit(1);
    }
  ' "$path"
}

assert_companion_bindings_resolve() {
  local inventory_projection="$1"
  local bindings="$2"
  local label="$3"
  local inventory_route_ids="$temp_dir/$(basename "$inventory_projection").route_ids"
  local referenced_route_ids="$temp_dir/$(basename "$bindings").referenced_ids"
  local duplicate_bindings missing_bindings

  cut -f1 "$inventory_projection" | sort -u >"$inventory_route_ids"
  cut -f2 "$bindings" | sort >"$referenced_route_ids"

  duplicate_bindings="$(cut -f2 "$bindings" | sort | uniq -d || true)"
  if [[ -n "$duplicate_bindings" ]]; then
    printf 'Duplicate public-shell companion bindings detected: %s\n' "$label" >&2
    printf '%s\n' "$duplicate_bindings" >&2
    exit 1
  fi

  missing_bindings="$(comm -23 "$referenced_route_ids" "$inventory_route_ids" || true)"
  if [[ -n "$missing_bindings" ]]; then
    printf 'Missing/stale public-shell companion bindings detected: %s\n' "$label" >&2
    printf '%s\n' "$missing_bindings" >&2
    exit 1
  fi
}

build_nginx_image() {
  docker build -q "$repo_root/docker/nginx"
}

generate_prod_certificates() {
  local target_root="$1"
  local cert_dir="$target_root/live/$domain"

  mkdir -p "$cert_dir"
  openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
    -subj "/CN=${domain}" \
    -addext "subjectAltName=DNS:${domain}" \
    -keyout "$cert_dir/privkey.pem" \
    -out "$cert_dir/fullchain.pem" >/dev/null 2>&1
}

run_nginx_test() {
  local image="$1"
  local rendered_conf="$2"
  local project_dir="$3"
  local letsencrypt_dir="${4:-}"

  local args=(
    --rm
    --entrypoint nginx
    --add-host app:127.0.0.1
    -v "$rendered_conf:/etc/nginx/conf.d/default.conf:ro"
    -v "$project_dir:/etc/nginx/project:ro"
  )

  if [[ -n "$letsencrypt_dir" ]]; then
    args+=(-v "$letsencrypt_dir:/etc/letsencrypt:ro")
  fi

  docker run "${args[@]}" "$image" -t >/dev/null
}

if [[ -z "$deep_link_policy_path" ]]; then
  if ! deep_link_policy_path="$(known_default_deep_link_policy_path "$laravel_config_path" 2>/dev/null)"; then
    printf 'Unable to infer deep-link route policy fixture for %s. Set DEEP_LINK_ROUTE_POLICY_CONFIG_FILE.\n' "$laravel_config_path" >&2
    exit 1
  fi
fi

require_file "$overlay_path"
require_file "$laravel_config_path"
require_file "$deep_link_policy_path"
require_file "$published_example_deep_link_policy_path"

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

rendered_local="$temp_dir/local.conf"
rendered_prod="$temp_dir/prod.conf"
project_dir="$temp_dir/project"
letsencrypt_dir="$temp_dir/letsencrypt"

mkdir -p "$project_dir"
cp "$overlay_path" "$project_dir/routes.conf"

render_template "$repo_root/docker/nginx/local.conf.template" "$rendered_local"
render_template "$repo_root/docker/nginx/prod.conf.template" "$rendered_prod"

root_local_entries="$temp_dir/root-local.entries"
root_prod_entries="$temp_dir/root-prod.entries"
project_entries="$temp_dir/project.entries"
laravel_entries="$temp_dir/laravel.entries"
laravel_contract_entries="$temp_dir/laravel.contract.entries"
companion_inventory_projection="$temp_dir/companion.inventory.tsv"
deep_link_bindings="$temp_dir/deep-link.bindings.tsv"
expected_root_entries="$temp_dir/expected-root.entries"
example_project_entries="$temp_dir/example-project.entries"
example_laravel_entries="$temp_dir/example-laravel.entries"
example_companion_inventory_projection="$temp_dir/example-companion.inventory.tsv"
example_deep_link_bindings="$temp_dir/example-deep-link.bindings.tsv"
active_companion_inventory_snapshot="$temp_dir/active-companion.snapshot.tsv"
example_companion_inventory_snapshot="$temp_dir/example-companion.snapshot.tsv"
example_project_dir="$temp_dir/project-example"
expected_contract_path=''

parse_root_public_shell_locations "$rendered_local" >"$root_local_entries"
parse_root_public_shell_locations "$rendered_prod" >"$root_prod_entries"
parse_project_public_shell_locations "$overlay_path" >"$project_entries"
parse_laravel_project_routes "$laravel_config_path" >"$laravel_entries"
parse_laravel_project_route_contract "$laravel_config_path" >"$laravel_contract_entries"
parse_companion_inventory_projection "$laravel_config_path" >"$companion_inventory_projection"
parse_deep_link_companion_bindings "$deep_link_policy_path" >"$deep_link_bindings"
compute_companion_inventory_snapshot "$laravel_config_path" >"$active_companion_inventory_snapshot"
parse_project_public_shell_locations "$repo_root/project/nginx/routes.conf.example" >"$example_project_entries"
parse_laravel_project_routes "$repo_root/project/laravel/public_shell_routes.example.php" >"$example_laravel_entries"
parse_companion_inventory_projection "$repo_root/project/laravel/public_shell_routes.example.php" >"$example_companion_inventory_projection"
parse_deep_link_companion_bindings "$published_example_deep_link_policy_path" >"$example_deep_link_bindings"
compute_companion_inventory_snapshot "$repo_root/project/laravel/public_shell_routes.example.php" >"$example_companion_inventory_snapshot"

cat <<'EOF' >"$expected_root_entries"
exact	/	exact
exact	/open-app	exact
exact	/privacy-policy	exact
EOF

assert_same_inventory "$expected_root_entries" "$root_local_entries" "local root template"
assert_same_inventory "$expected_root_entries" "$root_prod_entries" "production root template"
assert_same_inventory "$laravel_entries" "$project_entries" "project overlay vs Laravel project route inventory"
assert_no_root_overlap "$root_local_entries" "$project_entries"
assert_no_root_overlap "$root_prod_entries" "$project_entries"
assert_no_reserved_generic_overlap "$project_entries"
assert_companion_bindings_resolve "$companion_inventory_projection" "$deep_link_bindings" "active deep-link route policy vs companion inventory"
assert_same_inventory "$example_laravel_entries" "$example_project_entries" "published project example overlay vs Laravel example inventory"
assert_no_root_overlap "$root_local_entries" "$example_project_entries"
assert_no_root_overlap "$root_prod_entries" "$example_project_entries"
assert_no_reserved_generic_overlap "$example_project_entries"
assert_example_extension_contract "$repo_root/project/laravel/public_shell_routes.example.php"
assert_companion_bindings_resolve "$example_companion_inventory_projection" "$example_deep_link_bindings" "published deep-link route policy example vs companion inventory"

if expected_contract_path="$(known_expected_inventory_path "$laravel_config_path" 2>/dev/null)"; then
  require_file "$expected_contract_path"
  assert_same_inventory "$expected_contract_path" "$laravel_contract_entries" "known Laravel fixture route inventory"
fi

mkdir -p "$example_project_dir"
cp "$repo_root/project/nginx/routes.conf.example" "$example_project_dir/routes.conf"

nginx_image="$(build_nginx_image)"
generate_prod_certificates "$letsencrypt_dir"
run_nginx_test "$nginx_image" "$rendered_local" "$project_dir"
run_nginx_test "$nginx_image" "$rendered_prod" "$project_dir" "$letsencrypt_dir"
run_nginx_test "$nginx_image" "$rendered_local" "$example_project_dir"
run_nginx_test "$nginx_image" "$rendered_prod" "$example_project_dir" "$letsencrypt_dir"

printf 'Companion inventory snapshot (active): %s\n' "$(cat "$active_companion_inventory_snapshot")"
printf 'Companion inventory snapshot (published example): %s\n' "$(cat "$example_companion_inventory_snapshot")"
printf 'Public-shell parity verified for local+prod rendered templates.\n'
