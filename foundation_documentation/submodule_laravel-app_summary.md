```markdown
# Documentation: Submodule Summary - laravel-app
**Version:** 1.1

## 1. Analyzed Version

* **Submodule Name:** `laravel-app`
* **Commit Hash:** `80fff2416676f36d850fb6e1c430ec9e4ffeac1a`
* **Analysis Date:** `2025-10-19`

*Purpose: Reflect the live Laravel control-plane implementation so architectural artifacts and client expectations remain accurate.*

---

## 2. Core Dependencies & Technologies

* `laravel/framework` 12.x (PHP 8.4) – HTTP kernel, routing, queues.
* `mongodb/laravel-mongodb` 5.4 – `DocumentModel`, Mongo schema builder, soft deletes for landlord/tenant collections.
* `spatie/laravel-multitenancy` 4.x – Tenant discovery, context switching, tenant-aware queues.
* `laravel/sanctum` 4.x – Stateless token auth with ability middleware on every route group.
* `spatie/laravel-sluggable` 3.x – Generates slugs for tenants, accounts, and role templates.
* `intervention/image` 3.x + Laravel bridge – Processes branding assets during initialization.
* `propaganistas/laravel-phone`, `spatie/laravel-data` – Utility packages used by validation/DTO layers.

---

## 3. Structural Patterns

* **Dual Context Model:** `App\Models\Landlord` manages tenants, domains, landlord users/roles; `App\Models\Tenants` handles `Account`, `AccountUser`, and role templates. Both contexts extend `DocumentModel` and `SoftDeletes`, sharing sanctum authentication where needed.
* **Tenant Resolution Chain:** `App\Actions\DomainTenantFinder` inspects subdomain, `X-App-Domain`, or full host; `SwitchMongoTenantDatabaseTask` rewires the `tenants` connection per request.
* **Routing Layout:** `bootstrap/app.php` mounts explicit groups:
  * `/api/v1/initialize` (guest) for bootstrap detection/creation.
  * `/admin/api/v1/...` (middleware `landlord`) for control plane operations.
  * `/api/v1/...` (middleware `tenant`) for tenant APIs.
  * `/api/v1/accounts/{account_slug}/...` (middleware `tenant` + `account`) for account-scoped actions.
* **Data Reality:** Migrations provision:
  * Landlord: `tenants` (unique `slug`, `subdomain`, `app_domains`), `domains`, `landlord_users`, `landlord_roles`.
  * Tenant: `accounts` (`slug`, `document`, timestamps), `account_users` (array `emails`/`phones`, immutable `first_seen_at`, `registered_at` lifecyle markers, embedded `account_roles`, unique partial indexes), `roles`, `sessions`, `password_reset_tokens`.
  These differ from earlier documentation assumptions (no `capability_manifest_id`, no standalone `anonymous_sessions` collection yet).
* **Controller-Centric Workflows:** Provisioning, branding, and role seeding live in `app/Http/Api/v1/Controllers`; the `Services` namespace is largely empty.

---

## 4. Ecosystem Configuration Points

* `.env` / `.env.example` – Provide landlord/tenant Mongo URIs (`DB_URI_LANDLORD`, `DB_URI_TENANTS`), Sanctum defaults, and `API_DEFAULT_VERSION`.
* `config/database.php` – Declares `mongodb`, `landlord`, `tenants` connections; expects the switch task to inject per-tenant database names.
* `config/multitenancy.php` – Registers tenant finder, switch task, tenant-aware queues, and custom migrate action.
* `config/auth.php` – Configures Sanctum guards for landlord vs tenant contexts.
* `routes/api/*.php` – Canonical source of exposed endpoints; there is no generated OpenAPI spec.

---

## 5. Architectural Principle Alignment

* **P-1 (Domain-First, Schema-Second):** Partially aligned. Landlord/Tenant models reflect real operational entities, but documentation still references future schema (capability manifests, anonymous sessions) not yet in migrations.
* **P-2 (Document-Oriented by Default):** Aligned. Collections embed sub-documents (`account_roles`, branding data) and rely on Mongo indexes instead of joins.
* **P-3 (API-Centric Ecosystem):** Aligned. Sanctum-protected REST APIs are the only integration surface; no server-side rendered UI.
* **P-4 (Foundational, Not Minimalist):** Partially aligned. Initialization seeds branding, tenant DBs, and admin roles, yet roadmap features (capability manifest governance, anonymous visitor tokens) remain unimplemented.
* **P-10 (Service-Oriented Logic):** Not aligned. Controllers house business logic; refactoring into domain services is pending.
* **P-11 (Stateless Authentication):** Aligned. Sanctum bearer tokens + ability checks enforce least privilege.

---

## 6. Key Integration Points / API Surface

* **Initialization (`/api/v1/initialize`):** `POST` seeds landlord + first tenant + admin user, returning a Sanctum token; `GET` blocks repeat initializations.
* **Landlord APIs (`/admin/api/v1`, sanctum + `landlord` middleware):**
  * Auth flows (`/auth/login`, `/auth/logout`, password helpers).
  * Tenant lifecycle (`/tenants` CRUD + restore/force-delete) with embedded role template seeding.
  * Landlord user & role management, including ability lists stored as string arrays.
  * Branding asset ingestion (`/branding/update`) using Intervention Image.
* **Tenant APIs (`/api/v1`, sanctum + `tenant` middleware):**
  * Auth login/logout/password reset token flow for tenant operators.
  * Domain management (web/app domains) and tenant-facing user management.
  * Account CRUD, restore, and destructive operations.
  * Tenant role template CRUD and branding updates.
* **Account APIs (`/api/v1/accounts/{account_slug}`, sanctum + `tenant` + `account` middleware):**
  * Account user CRUD with ability scoped to embedded role templates.
  * Account role template CRUD (duplicate allowed via slug options).
* **Ability Names in Use:** `tenants:*`, `tenant-users:*`, `account-users:*`, `account-roles:*`, `landlord-users:*`, `tenant-branding:update`, etc. No `public.*` scope exists yet.

---

## 7. Notes & Observations

* Anonymous visitor handling is not implemented—there is no Sanctum public token issuance, `anonymous_sessions` collection, or related controllers. Roadmap references must treat this as future scope.
* Capability manifest APIs referenced in documentation do not exist; tenants currently inherit a default admin role template during provisioning.
* Branding upload stores files locally; remote storage/S3 wiring is not in place.
* API v2 scaffolding (`routes/api/api_v2.php`) is empty.
* Service layer stubs and `spatie/laravel-data` DTOs are mostly unused; consolidating business logic into dedicated services remains an open task.
* Landlord and tenant validators now enforce canonical input ceilings (passwords 8–32 chars, display strings ≤255, descriptions ≤1000, email arrays ≤10 items with 255-char members, permission arrays ≤64, metadata arrays ≤20 entries/≈8 KB). Feature tests assert these guards as part of our input surface hardening mandate.
* Landlord auth surface now rejects tenant Sanctum tokens (`/admin/api/auth/token_validate`) and auto-populates `promotion_audit` entries when operators elevate identities during landlord user creation, ensuring the audit trail lines up with foundation_control_plane documentation.
* Anonymous → verified consolidation will migrate fingerprint histories into the canonical `account_users` document, archive the original anonymous snapshot in `merged_account_snapshots`, and hard-delete the source row to keep the live collection clean while preserving forensic evidence.
```
