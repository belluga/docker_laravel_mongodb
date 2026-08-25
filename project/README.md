# Project Overlay Surfaces

This directory is downstream-owned.

The shared Docker/NGINX base stays generic while each consuming project keeps its
own runtime overlays and reference contracts here.

Current surfaces:

- `nginx/`: optional route overlays loaded before the generic SPA fallback.
  Managed public-shell locations should carry `# public_shell_route_id: <id>`
  inside the `location` block so the parity harness can diff Nginx ingress
  against the Laravel project inventory. Generic-owned endpoints and families
  such as `/open-app`, `/manifest.json`, and `/icon/*` stay in the shared root
  templates and must not be copied into project overlays.
- `laravel/public_shell_routes.php`: optional project-owned public-shell route
  inventory consumed by the generic Laravel allowlist loader.
- `laravel/public_shell_routes.example.php`: format reference for the project
  public-shell route inventory. Its sample `custom_public_metadata` extension
  intentionally uses a `project.*` placeholder service-container ID rather than
  a shared boilerplate class; downstream projects must replace or bind that ID
  to a service implementing the public-shell metadata extension contract before
  enabling the sample custom route.
- `laravel/required_runtime_classes.txt`: optional runtime class guard list
  consumed by `docker/laravel-app/entrypoint.sh`.
- `laravel/required_runtime_classes.example.txt`: format reference for the guard list.
- `well-known/*.example.json`: reference payload shapes for App Links / Universal
  Links contracts. Runtime delivery may remain backend-owned.

If `nginx/` contains no `*.conf` files, the shared templates still start
normally. The `include /etc/nginx/project/*.conf` directive is intentionally
safe for an empty glob.
