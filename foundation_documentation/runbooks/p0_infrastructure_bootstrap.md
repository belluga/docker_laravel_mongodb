# Runbook: P0 Infrastructure Bootstrap
**Version:** 1.0

## 1. Purpose

This runbook codifies the operational sequence to bootstrap the Belluga Platform Boilerplate control plane for Phase P0. It covers container orchestration, secrets layering, database provisioning, and validation checks required before enabling anonymous clients.

## 2. Environment Prerequisites

- Docker Engine 24.x with Compose V2.
- Access to the secrets store (AWS SSM or Vault) containing `FOUNDATION_MONGO_URL`, `FOUNDATION_REDIS_URL`, and `SANCTUM_PERSONAL_ACCESS_KEY`.
- DNS control for the landlord domain (e.g., `landlord.local.belluga`) and wildcard certificate for TLS termination.
- Observability stack (Prometheus, Loki, Grafana) reachable from the control plane network segment.

## 3. Bootstrap Sequence

### 3.1 Seed Configuration
1. Export required environment variables in `.env.landlord`:
   - `APP_ENV=production`
   - `APP_URL=https://landlord.local.belluga`
   - `MONGO_URL={{FOUNDATION_MONGO_URL}}`
   - `REDIS_URL={{FOUNDATION_REDIS_URL}}`
   - `SANCTUM_PERSONAL_ACCESS_KEY={{SANCTUM_PERSONAL_ACCESS_KEY}}`
2. Commit capability catalogue seeds under `database/seeders/CapabilityCatalogueSeeder.php` ensuring all module IDs referenced by `tenants.capabilities` exist.

### 3.2 Launch Core Services
1. Run `docker compose -f docker/local/p0-foundation.yml up -d mongo redis horizon landlord`.
2. Verify Mongo readiness with `docker compose exec mongo mongosh --eval "db.adminCommand('ping')"`.
3. Confirm Redis connectivity using `docker compose exec redis redis-cli ping`.

### 3.3 Apply Database Migrations
1. Execute landlord migrations: `docker compose exec landlord php artisan migrate --database=landlord`.
2. Run tenant template migrations (creates base schema applied to future tenants): `docker compose exec landlord php artisan tenants:baseline`.
3. Seed capability catalogue and landlord operator: `docker compose exec landlord php artisan db:seed --class=FoundationControlPlaneSeeder`.

### 3.4 Initialize Platform
1. POST `/v1/initialize` with payload containing landlord operator credentials and first tenant blueprint.
2. Store the response `tenant_slug` and `admin_token` securely; these values authorize subsequent account provisioning.
3. POST `/v1/anonymous/identities` with tenant slug + fingerprint payload to confirm anonymous token issuance and policy enforcement.

### 3.5 Validate Observability
1. Hit `/v1/health` (readiness) and confirm HTTP 200.
2. Scrape Prometheus endpoint `/metrics` to ensure counters `tenants_provisioned_total` and `anonymous_tokens_issued_total` exist.
3. Query Loki for log entries containing `foundation_control_plane` and `bootstrap=success`.

## 4. Ongoing Operations

- **Secrets Rotation:** Rotate `SANCTUM_PERSONAL_ACCESS_KEY` every 90 days. Re-run Section 3.3 Step 1 after rotation.
- **Anonymous Identity Policy Refresh:** Update tenant `anonymous_access_policy` fields and issue `php artisan foundation:anonymous-policies:sync` to push changes to cache.
- **Index Assurance:** Weekly, run `php artisan schema:assert` to compare expected and actual Mongo indexes; resolve drift immediately.
- **Backup Policy:** Enable daily landlord and tenant database snapshots with seven-day retention; test restoration quarterly.

## 5. Incident Response

- **Provisioning Failure:** Inspect Horizon dashboard for failed jobs tagged `anonymous_identity_issue`. Re-run `php artisan queue:retry all` after addressing root cause.
- **Identity Promotion Lag:** Review `interaction_records` for missing `identity_promotion` entries and execute `php artisan foundation:audit-promotions`.
- **Anonymous Token Abuse:** Temporarily reduce `anonymous_access_policy.rate_limits`, revoke outstanding anonymous tokens via `php artisan foundation:anonymous-tokens:revoke`, and monitor issuance metrics before restoring defaults.

## 6. Reference Materials

- `foundation_documentation/modules/foundation_control_plane.md`
- `foundation_documentation/data_schemas/p0_core_collections.md`
- `foundation_documentation/system_roadmap_sections/phase_narratives/p0-boilerplate-genesis.md`
