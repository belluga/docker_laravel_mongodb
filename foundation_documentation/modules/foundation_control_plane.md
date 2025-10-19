# Documentation: Foundation Control Plane Module
**Version:** 1.1

## 1. Module Index

| Module ID | Module Name | Primary Responsibility | Status | Owner |
|-----------|-------------|------------------------|--------|-------|
| MOD-001 | `foundation_control_plane` | Governs landlord and tenant provisioning, identity_state lifecycle, capability activation, and account credential governance. | In Design | Delphi Architecture Guild |

## 2. Module Specification Template

### MOD-001: `foundation_control_plane`

* **Purpose Statement:** Establish the authoritative Laravel service surface for provisioning tenants, configuring accounts, managing the identity_state lifecycle (anonymous -> verified), and issuing the initialization contract that bootstraps every client.
* **Core Entities:** Tenant, Landlord User, Account, Account User (Identity Actor), Tenant Role Template, Account Role Template, Capability Module.
* **Key Workflows:** Landlord-led tenant creation and initialization, role template seeding, account segmentation, account user onboarding/promotion, tenant manifest delivery.
* **External Dependencies:** MongoDB landlord cluster, MongoDB tenant clusters, Laravel Sanctum, Spatie Multitenancy, internal secrets store (ENV + SSM), asynchronous job queue (Redis-based Horizon).
* **Service-Level Objectives:** P99 latency = 350 ms for read endpoints, = 1.2 s for provisioning writes; availability = 99.5%; successful tenant bootstrap completion = 99.9% within 60 s.

#### 3.1 Domain Rules
* **Invariants:** Tenant slugs are immutable once provisioned and map 1:1 to tenant Mongo databases. Every tenant retains at least one active admin role template. Account users maintain a single canonical document per tenant and transition identity_state in order (`anonymous`, then `verified`) as contact points are confirmed. Ability templates remain scoped either to landlord or tenant contexts exclusively.
* **Validation Rules:** Tenant and account slugs follow `^[a-z0-9-]{3,32}$`. Account user email and phone arrays enforce uniqueness via partial indexes. Device fingerprints captured for anonymous-state auditing are SHA-256 hashes. Branding payloads must include theme seed colors to drive initialization manifest generation.
* **Authorization Requirements:** Landlord operators interact via Sanctum abilities such as `tenants:*`, `landlord-users:*`, and `tenant-branding:update`. Tenant operators rely on scoped abilities (e.g., `accounts:*`, `account-users:*`, `tenant-roles:*`). Account-level automation uses dedicated credentials bound to role templates; there is no public anonymous ability surface at this stage.

#### 3.2 API Endpoint Definitions

| Endpoint | Method | Description | Required Role | Request Schema | Response Schema |
|----------|--------|-------------|---------------|----------------|-----------------|
| `/api/v1/initialize` | POST | Bootstrap landlord, first tenant, and initial landlord admin identity. | Guest | `InitializationRequest` | `InitializationResource` |
| `/api/v1/initialize` | GET | Report whether initialization has already executed. | Guest | `n/a` | `InitializationStatusResource` |
| `/admin/api/v1/auth/login` | POST | Issue Sanctum token for landlord operator. | Guest | `LandlordCredentialsPayload` | `AuthTokenResource` |
| `/admin/api/v1/auth/logout` | POST | Revoke current landlord token. | `landlord-users:read` | `n/a` | `EmptyResponse` |
| `/admin/api/v1/tenants` | POST | Provision tenant, seed admin role template, and migrate tenant database. | `tenants:create` | `TenantProvisionPayload` | `TenantResource` |
| `/admin/api/v1/tenants/{tenant_slug}` | GET | Retrieve tenant profile, domains, and status. | `tenants:read` | `n/a` | `TenantResource` |
| `/admin/api/v1/tenants/{tenant_slug}` | PATCH | Update tenant metadata (name, branding data, domains). | `tenants:update` | `TenantUpdatePayload` | `TenantResource` |
| `/admin/api/v1/tenants/{tenant_slug}` | DELETE | Soft-delete tenant and disable associated role templates. | `tenants:delete` | `n/a` | `EmptyResponse` |
| `/admin/api/v1/tenants/{tenant_slug}/restore` | POST | Restore soft-deleted tenant. | `tenants:manage` | `n/a` | `TenantResource` |
| `/admin/api/v1/branding/update` | POST | Upload landlord branding assets and regenerate variants. | `tenant-branding:update` | `LandlordBrandingPayload` | `BrandingResource` |
| `/api/v1/auth/login` | POST | Authenticate tenant/account operator and return token plus identity_state. | Guest | `TenantCredentialsPayload` | `AuthTokenResource` |
| `/api/v1/auth/logout` | POST | Revoke tenant/account token. | `account-users:*` | `n/a` | `EmptyResponse` |
| `/api/v1/auth/password_token` | POST | Issue password reset token for tenant operator. | Guest | `PasswordTokenRequest` | `PasswordTokenResource` |
| `/api/v1/accounts` | POST | Create tenant account (slug auto-generated) with optional document metadata. | `accounts:create` | `AccountProvisionPayload` | `AccountResource` |
| `/api/v1/accounts/{account_slug}` | PATCH | Update account display data, settings, or suspension flags. | `accounts:update` | `AccountUpdatePayload` | `AccountResource` |
| `/api/v1/accounts/{account_slug}/users` | POST | Invite account user; identity_state defaults to anonymous until verification. | `account-users:create` | `AccountUserPayload` | `AccountUserResource` |
| `/api/v1/accounts/{account_slug}/users/{user_id}` | PATCH | Promote or update account user (identity_state, roles, contact points). | `account-users:update` | `AccountUserUpdatePayload` | `AccountUserResource` |
| `/api/v1/accounts/{account_slug}/roles` | POST | Author account role template with scoped permissions. | `account-roles:create` | `AccountRolePayload` | `AccountRoleResource` |
| `/api/v1/accounts/{account_slug}/roles/{role_id}` | PATCH | Update account role template metadata/permissions. | `account-roles:update` | `AccountRolePayload` | `AccountRoleResource` |
| `/api/v1/domains` | POST | Register tenant domains for discovery/routing. | `tenant-domains:update` | `TenantDomainPayload` | `TenantDomainResource` |
| `/api/v1/domains/{domain_id}` | DELETE | Remove tenant domain mapping (soft delete). | `tenant-domains:update` | `n/a` | `EmptyResponse` |

#### 3.3 Data Schemas

##### Collection: `tenants`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier (landlord cluster). | Yes | |
| `name` | String | Tenant display name. | Yes | |
| `slug` | String | Immutable slug used for routing/database naming. | Yes | Unique index generated from `name`. |
| `database` | String | Tenant database name. | Yes | Derived from slug (`tenant_{slug}`). |
| `subdomain` | String | Tenant subdomain for landlord-managed routing. | Yes | Unique per tenant. |
| `app_domains` | Array<String> | Application hostnames served by the tenant. | No | Indexed for tenant discovery via `DomainTenantFinder`. |
| `description` | String | Optional tenant summary. | No | |
| `branding_data.theme_data_settings` | Document | Color palette and typography tokens. | No | Populated during initialization or branding updates. |
| `branding_data.logo_settings` | Document | Logo variants and metadata. | No | |
| `branding_data.pwa_icon` | Document | Generated icon assets. | No | |
| `deleted_at` | Date | Soft delete timestamp. | No | Present when tenant is archived. |
| `created_at` | Date | Creation timestamp. | Yes | |
| `updated_at` | Date | Last update timestamp. | Yes | |

##### Collection: `accounts`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier (tenant cluster). | Yes | |
| `name` | String | Account display name. | Yes | |
| `slug` | String | Slug generated from name, unique per tenant. | Yes | Created via Spatie Sluggable. |
| `document` | String | External identifier (tax ID, registry, etc.). | No | Unique index when present. |
| `settings` | Document | Custom configuration map for the account. | No | Cast to array in model. |
| `deleted_at` | Date | Soft delete timestamp. | No | |
| `created_at` | Date | Creation timestamp. | Yes | |
| `updated_at` | Date | Last update timestamp. | Yes | |

##### Collection: `account_users`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier (tenant cluster). | Yes | |
| `name` | String | User display name. | No | |
| `emails` | Array<String> | Contact email addresses. | No | Partial unique index prevents duplicates across users. |
| `phones` | Array<String> | Contact phone numbers. | No | Partial unique index prevents duplicates across users. |
| `identity_state` | String | Lifecycle state of the identity. | Yes | Enum: `anonymous`, `verified`. |
| `password` | String | Hashed password (nullable until verification). | No | Managed via Laravel hashing. |
| `account_roles` | Array<Document> | Embedded role assignments per account. | No | Entries store `account_id`, `permissions`, `role_id`, `role_slug`, `assigned_at`. |
| `remember_token` | String | Sanctum remember token. | No | |
| `deleted_at` | Date | Soft delete timestamp. | No | |
| `created_at` | Date | Creation timestamp. | Yes | |
| `updated_at` | Date | Last update timestamp. | Yes | |

**Field Definitions**

* `identity_state`: `anonymous` (onboarded without verified contact) or `verified` (email/phone confirmed, full access granted).
* `account_roles[].permissions`: Array of strings (e.g., `catalog:view`, `accounts:*`) derived from role templates.

##### Collection: `tenant_role_templates`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier (landlord cluster). | Yes | |
| `tenant_id` | ObjectId | Tenant owner. | Yes | |
| `name` | String | Template display name. | Yes | |
| `slug` | String | Slug generated from name (duplicates allowed). | Yes | Uses Spatie Sluggable. |
| `description` | String | Optional description. | No | |
| `permissions` | Array<String> | Sanctum abilities granted when applied. | Yes | |
| `deleted_at` | Date | Soft delete timestamp. | No | |
| `created_at` | Date | Creation timestamp. | Yes | |
| `updated_at` | Date | Last update timestamp. | Yes | |

##### Collection: `account_role_templates`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier (tenant cluster). | Yes | |
| `account_id` | ObjectId | Parent account reference. | Yes | |
| `name` | String | Template display name. | Yes | |
| `slug` | String | Slug generated from name (duplicates allowed). | Yes | |
| `description` | String | Optional description. | No | |
| `permissions` | Array<String> | Sanctum abilities granted when this template is applied. | Yes | |
| `deleted_at` | Date | Soft delete timestamp. | No | |
| `created_at` | Date | Creation timestamp. | Yes | |
| `updated_at` | Date | Last update timestamp. | Yes | |

##### Collection: `domains`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier (landlord cluster). | Yes | |
| `tenant_id` | ObjectId | Tenant owner. | Yes | |
| `type` | String | Domain type (`web`, `app`). | Yes | |
| `path` | String | Domain or host value. | Yes | Unique per tenant/type combination. |
| `deleted_at` | Date | Soft delete timestamp. | No | |
| `created_at` | Date | Creation timestamp. | Yes | |
| `updated_at` | Date | Last update timestamp. | Yes | |

#### 3.4 Event & Messaging Contracts

* **Outbound Events:**
  * `TenantProvisioned` - emitted after successful tenant creation; payload includes tenant slug, database name, and operator ID.
  * `AccountUserPromoted` - emitted when an account user transitions identity_state from `anonymous` to `verified`; payload captures account_id, user_id, and promotion metadata.
  * `AccountCredentialRotated` - emitted when automation credentials are regenerated; payload lists credential identifier and initiating operator.
* **Inbound Events:** `TenantBillingActivated` (from Commercial Engine) to synchronize billing status; future `AccountCredentialRevoked` events from the Identity module will trigger credential rotation workflows.
* **Queue/Topic Configuration:** Events are published to the `foundation.control-plane` topic (Kafka) with key `{tenant_slug}`. Retention 14 days. Consumers must honor idempotency via event UUID and track identity_state transitions for auditing.

#### 3.5 Background Jobs & Schedulers

* `TenantHealthCheckJob` - verifies tenant DSNs, domain routing, and Sanctum key rotations; raises alert on failure.
* `AccountCredentialRotationJob` (planned) - rotates automation credentials and notifies dependent services.
* `IdentityPromotionReminderJob` (planned) - nudges anonymous-state account users to complete verification after configurable windows.
* All jobs execute via Laravel Horizon with Redis backend; each job persists idempotency keys and structured logs.

#### 3.6 Observability & Instrumentation

* **Logs:** JSON structured logs capturing `tenant_slug`, `account_slug`, `request_id`, `identity_state`, `ability_scope`, `outcome`, `latency_ms`.
* **Metrics:** Prometheus counters (`tenants_provisioned_total`, `account_users_by_state_total`, `account_credentials_active_total`), histograms (`tenant_provision_latency_seconds`, `account_user_promotion_latency_seconds`), gauges (`active_role_templates`).
* **Tracing:** OpenTelemetry spans named `foundation.control_plane.*`; propagate `traceparent` headers and include `identity_state` baggage for promotion flows.
* **Alerts:** Pager alert when P99 provisioning latency > 2 s for 5 minutes; warning when identity promotion failure rate exceeds 5% per tenant over 1 hour; info alert when credential rotations fail consecutively.

#### 3.7 Testing Strategy

* **Unit Tests:** Cover tenant provisioning validators, identity_state transitions, and role template assignment helpers using PHPUnit.
* **Integration Tests:** Exercise landlord initialization, tenant provisioning, account creation, and account user invitation/promotion flows across landlord and tenant Mongo connections.
* **Contract Tests:** Pact-based tests for `/api/v1/initialize`, `/admin/api/v1/tenants`, `/api/v1/accounts/{account_slug}/users`, and `/api/v1/auth/login` shared with Flutter and other clients; schema snapshots stored in repo.
* **Performance Tests:** k6 scenarios simulating parallel tenant provisioning bursts (up to 5 concurrent) and sustained account user onboarding (300 RPS) to validate SLO adherence.

## 4. Cross-Module Considerations

* **Shared Libraries:** Depends on shared DTOs from the Identity module (token payloads), role template enumerations, and cross-module ability constants.
* **Data Ownership Boundaries:** `tenants`, `domains`, `accounts`, `account_users`, and role templates (tenant/account) are owned exclusively by this module. Identity module consumes tokens issued here but does not mutate tenant data.
* **Failure & Degradation Modes:** On provisioning failure, rollback removes partially created tenants/domains and emits `TenantProvisionFailed`. If promotion workflows lag, tenants may degrade to restricted mode that limits anonymous-state privileges until verification catches up.

## 5. Implementation Notes

* **Code Structure:** Maintain PSR-12 compliance. Place HTTP controllers under `app/Http/Api/v1/Controllers` (landlord, tenant, account namespaces) and shared actions under `app/Actions`. Models live in `App/Models/Landlord` and `App/Models/Tenants` with Mongo `DocumentModel` mixins.
* **Configuration Management:** Store DSNs and manifest defaults in landlord `.env`; enforce tenant-specific connection overrides via `SwitchMongoTenantDatabaseTask`. Partial indexes on `account_users.emails`/`phones` are created via migrations; preserve them when adding new templates.
* **Deployment Pipeline:** CI runs static analysis, unit/integration suites, and publishes Docker images. CD migrates landlord database, executes tenant migrations via `php artisan tenants:migrate`, then runs smoke tests for `/api/v1/initialize`, `/admin/api/v1/tenants`, and `/api/v1/accounts/{account_slug}/users`.
* **Ingress Synchronization:** Whenever Laravel route prefixes change, mirror the update in `docker/nginx/*.conf.template` to preserve path routing across local and production deployments.

## 6. Decision Log

| Decision ID | Date | Module(s) | Summary | Status | Rationale | Linked Evidence |
|-------------|------|-----------|---------|--------|-----------|-----------------|
| DEC-001 | 2025-10-19 | foundation_control_plane | Adopt identity_state lifecycle (anonymous -> verified) anchored on `account_users` with partial unique contact indexes. | Ratified | Aligns control plane behavior with roadmap decisions and Flutter expectations. | `foundation_documentation/system_roadmap_sections/2-delivery-framework.md` |

## 7. Appendices

* **Reference APIs:** Identity endpoints documented in `foundation_documentation/system_roadmap_sections/5-foundational-api-portfolio.md` (initialize, landlord/tenant auth, account onboarding).
* **Security Review Checklist:** Ensure least-privilege Sanctum abilities, enforce TLS on landlord/tenant routes, verify hashed storage of account user passwords and secure handling of automation credentials.
* **Operational Runbooks:** Provisioning rollback guide, identity promotion troubleshooting, credential rotation procedure, and tenant domain onboarding checklist.
