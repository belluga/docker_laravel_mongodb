# Documentation: Submodule Summary - laravel-app
**Version:** 1.0

## 1. Analyzed Version

* **Submodule Name:** `laravel-app`
* **Commit Hash:** `80fff2416676f36d850fb6e1c430ec9e4ffeac1a`
* **Analysis Date:** `2025-10-18`

*Purpose: This document summarizes the key architectural aspects of the specified submodule version relevant to the main ecosystem.*

---

## 2. Core Dependencies & Technologies

* `laravel/framework` 12.x: Primary HTTP, routing, and application framework.
* `mongodb/laravel-mongodb` 5.4: Extends Eloquent with MongoDB DocumentModel capabilities across landlord and tenant contexts.
* `spatie/laravel-multitenancy` 4.x: Provides tenant discovery, context switching, and tenant-aware job execution.
* `laravel/sanctum` 4.x: Supplies stateless token authentication and ability-based authorization middleware.
* `spatie/laravel-data` 4.x: Standardizes typed DTOs for API payload transformation.
* `intervention/image` 3.x (+ Laravel bridge): Handles tenant and landlord branding asset manipulation.
* `propaganistas/laravel-phone` 6.x: Normalizes and validates international phone numbers within profile flows.

---

## 3. Structural Patterns

* **Overall Structure:** Multi-context Laravel application separating landlord and tenant domains, backed by MongoDB.
* **Key Patterns:**
  * Dual model namespaces (`App\Models\Landlord`, `App\Models\Tenants`) backed by distinct MongoDB connections for landlord control-plane versus tenant data-plane (`laravel-app/app/Models`).
  * Versioned API layer under `app/Http/Api/v1` with dedicated controller, request, and resource folders per version.
  * Custom tenant resolution via `DomainTenantFinder` selecting tenants by subdomain, web domain, or `X-App-Domain` header (`laravel-app/app/Actions/DomainTenantFinder.php`).
  * Tenancy switch task purging and rebinding MongoDB connections on each tenant transition (`laravel-app/app/Tasks/SwitchMongoTenantDatabaseTask.php`).
  * Laravel middleware groups orchestrated in `bootstrap/app.php` to isolate landlord, tenant, and account pipelines.

---

## 4. Ecosystem Configuration Points

* **Configuration Method:** `.env` variables consumed by Laravel config files; tenant metadata stored in landlord Mongo collections.
* **Key Variables/Files:**
    * `laravel-app/config/database.php`: Declares `mongodb`, `landlord`, and `tenant` connections targeting distinct DSNs (`DB_URI`, `DB_URI_LANDLORD`, `DB_URI_TENANTS`).
    * `laravel-app/config/multitenancy.php`: Registers tenant finder, tenant switch tasks, queue awareness, and connection aliases (`DB_CONNECTION_TENANTS`, `DB_CONNECTION_LANDLORD`).
    * `laravel-app/bootstrap/app.php`: Wires initialization, landlord, tenant, and account route groups plus Sanctum ability middleware.
    * `laravel-app/routes/api/*.php`: Defines landlord (`admin/api/v1`), tenant (`api/v1`), and account-scoped (`api/v1/accounts/{account_slug}`) endpoints aligned with middleware guards.
    * `.env` / `.env.example`: Provide seed values for `API_DEFAULT_VERSION`, Mongo URIs, cache, and Sanctum configuration.

---

## 5. Architectural Principle Alignment

* **P-1 (Domain-First, Schema-Second):** Aligned. Models, requests, and controllers map directly to landlord/tenant/account entities, with migrations under `database/migrations/landlord` and `database/migrations/tenants` establishing domain-centric collections.
* **P-2 (Document-Oriented by Default):** Aligned. All aggregates extend `MongoDB\Laravel\Eloquent\DocumentModel`, embed nested branding data, and leverage Mongo-specific relations (e.g., `Tenant::domains()`).
* **P-3 (API-Centric Ecosystem):** Aligned. HTTP interface is the primary contract, versioned via prefixed route groups and Sanctum-guarded endpoints.
* **P-4 (Foundational, Not Minimalist):** Aligned. Landlord provisioning auto-creates tenant databases, branding cascades, and manifest data to support future clients.
* **P-10 (Service-Oriented Logic):** Partially Aligned. Controllers encapsulate complex workflows (transactions, template provisioning) that are candidates for dedicated domain services (`laravel-app/app/Http/Api/v1/Controllers/AccountController.php`), while `app/Services` is a placeholder.
* **P-11 (Stateless Authentication):** Aligned. Sanctum tokens guard every route group, with ability checks enforcing least-privilege scopes.

---

## 6. Key Integration Points / API Surface (If Applicable)

* **API Prefix/Base:** `admin/api/v1` for landlord orchestration, `api/v1` for tenant APIs, `api/v1/accounts/{account_slug}` for account-scoped actions, plus an initialization entry point at `/initialize`.
* **Primary Endpoints/Modules:**
  * Landlord management: Tenant lifecycle, landlord user CRUD, role templates, branding updates (`laravel-app/routes/api/landlord_api_v1.php`).
  * Tenant surface: Account provisioning, role template administration, tenant user management, environment discovery (`laravel-app/routes/api/tenant_api_v1.php`).
  * Account-specific operations: Role assignment, account branding, user invitations within a tenant account context (`laravel-app/routes/api/account_api_v1.php`).
  * Initialization: Bootstrap endpoint delivering environment, tenant, and branding metadata consumed by clients (`laravel-app/routes/api/initialize.php`).
* **Authentication Method:** Laravel Sanctum bearer tokens tied to device identifiers; ability middleware (`abilities`, `ability`) enforces scoped access.

---

## 7. Notes & Observations

* API v2 scaffolding exists but lacks concrete controllers/routes, signalling planned future expansion (`laravel-app/app/Http/Api/v2`, `laravel-app/routes/api/api_v2.php`).
* Service layer stubs (`app/Services`) remain unimplemented, leaving business logic concentrated inside controllers and actions.
* Branding assets and manifests are generated per tenant using `Intervention\Image`, but storage configuration needs confirmation against deployment storage (S3, local, etc.).
* Ensure `DomainTenantFinder` local hostname overrides stay synchronized with deployment ingress hosts to avoid tenant mis-resolution across environments.
* Consider documenting Sanctum ability taxonomy centrally so clients and roadmap entries can stay consistent with controller-level expectations.
