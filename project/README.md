# Project Overlay Surfaces

This directory is downstream-owned.

The shared Docker/NGINX base stays generic while each consuming project keeps its
own runtime overlays and reference contracts here.

Current surfaces:

- `nginx/`: optional route overlays loaded before the generic SPA fallback.
- `laravel/required_runtime_classes.txt`: optional runtime class guard list
  consumed by `docker/laravel-app/entrypoint.sh`.
- `laravel/required_runtime_classes.example.txt`: format reference for the guard list.
- `well-known/*.example.json`: reference payload shapes for App Links / Universal
  Links contracts. Runtime delivery may remain backend-owned.

If `nginx/` contains no `*.conf` files, the shared templates still start
normally. The `include /etc/nginx/project/*.conf` directive is intentionally
safe for an empty glob.
