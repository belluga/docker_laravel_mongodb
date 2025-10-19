# Documentation: Foundation Control Plane Module
**Version:** 1.0

## 1. Module Index

| Module ID | Module Name | Primary Responsibility | Status | Owner |
|-----------|-------------|------------------------|--------|-------|
| MOD-001 | `foundation_control_plane` | Governs landlord and tenant provisioning, capability activation, and anonymous context contracts. | In Design | Delphi Architecture Guild |

## 2. Module Specification Template

### MOD-001: `foundation_control_plane`

* **Purpose Statement:** Establish the authoritative Laravel service surface for provisioning tenants, configuring accounts, publishing capability manifests, and issuing the initialization contract that bootstraps every client.
* **Core Entities:** Tenant, Account, Identity Actor, Anonymous Context, Capability Module, Interaction Record.
* **Key Workflows:** Landlord-led tenant creation, capability manifest authoring, account segmentation, anonymous session issuance, tenant manifest delivery.
* **External Dependencies:** MongoDB landlord cluster, MongoDB tenant clusters, Laravel Sanctum, Spatie Multitenancy, internal secrets store (ENV + SSM), asynchronous job queue (Redis-based Horizon).
* **Service-Level Objectives:** P99 latency ≤ 350 ms for read endpoints, ≤ 1.2 s for provisioning writes; availability ≥ 99.5%; successful tenant bootstrap completion ≥ 99.9% within 60 s.

#### 3.1 Domain Rules
* **Invariants:** Tenant slugs are immutable once provisioned. Every tenant must own at least one `production` capability manifest. Identity actors transition through `identity_state` (`anonymous`, then `verified`) as they gain credentials; anonymous sessions cannot exist without a valid tenant association. Ability templates must belong to either landlord or tenant scope exclusively.
* **Validation Rules:** Tenant slugs follow `^[a-z0-9-]{3,32}$`. Display names require UTF-8 safe characters ≤ 120 length. Account codes remain unique within a tenant. Manifest capability entries must reference canonical module keys documented in the Capability Module Activation Matrix. Anonymous device fingerprints must be SHA-256 hashes; verified identities require unique email or phone.
* **Authorization Requirements:** Landlord platform administrators operate landlord routes (`abilities:landlord.admin`). Tenant operators require capability-specific abilities (`abilities:tenant.configuration`). Anonymous session issuance and token refresh require the `public.anonymous` ability tied to the tenant's public API key, while account credentials inherit dedicated automation scopes.

#### 3.2 API Endpoint Definitions

| Endpoint | Method | Description | Required Role | Request Schema | Response Schema |
|----------|--------|-------------|---------------|----------------|-----------------|
| `/admin/api/v1/auth/login` | POST | Issue landlord Sanctum token for platform operators. | Public | `LandlordCredentialsPayload` | `AuthTokenResource` |
| `/admin/api/v1/auth/logout` | POST | Invalidate landlord session token. | `abilities:landlord.auth:logout` | `n/a` | `EmptyResponse` |
| `/admin/api/v1/profile/password` | PATCH | Rotate landlord operator password. | `abilities:landlord.profile:update` | `PasswordRotationPayload` | `ProfileResource` |
| `/admin/api/v1/tenants` | POST | Provision tenant, assign default manifests, and seed landlord credentials. | `abilities:tenants:create` | `TenantProvisionPayload` | `TenantResource` |
| `/admin/api/v1/tenants/{tenant_slug}` | GET | Retrieve tenant profile, capability manifests, and operational state. | `abilities:tenants:read` | `n/a` | `TenantResource` |
| `/admin/api/v1/tenants/{tenant_slug}` | PATCH | Update tenant metadata (display name, domains, status flags). | `abilities:tenants:update` | `TenantUpdatePayload` | `TenantResource` |
| `/admin/api/v1/tenants/{tenant_slug}` | DELETE | Soft-delete tenant and revoke active manifests. | `abilities:tenants:delete` | `n/a` | `TenantResource` |
| `/admin/api/v1/tenants/{tenant_slug}/restore` | POST | Restore soft-deleted tenant and reinstate manifests. | `abilities:tenants:manage` | `n/a` | `TenantResource` |
| `/admin/api/v1/branding/update` | POST | Update global landlord branding assets. | `abilities:tenant-branding:update` | `LandlordBrandingPayload` | `BrandingResource` |
| `/admin/api/v1/users` | GET | List landlord users with pagination filters. | `abilities:landlord-users:read` | `n/a` | `LandlordUserCollection` |
| `/admin/api/v1/users/{user_id}` | PATCH | Update landlord user profile or abilities. | `abilities:landlord-users:update` | `LandlordUserUpdatePayload` | `LandlordUserResource` |
| `/admin/api/v1/roles` | POST | Create landlord role with scoped abilities. | `abilities:landlord-roles:create` | `LandlordRolePayload` | `LandlordRoleResource` |
| `/api/v1/auth/login` | POST | Authenticate tenant operators or account admins. | Public | `TenantCredentialsPayload` | `AuthTokenResource` |
| `/api/v1/auth/logout` | POST | Revoke tenant/account token. | `abilities:tenant.auth:logout` | `n/a` | `EmptyResponse` |
| `/api/v1/profile/password` | PATCH | Rotate tenant operator password. | `abilities:tenant.profile:update` | `PasswordRotationPayload` | `ProfileResource` |
| `/api/v1/domains` | POST | Register tenant domains for discovery and routing. | `abilities:tenant-domains:update` | `TenantDomainPayload` | `TenantDomainResource` |
| `/api/v1/accounts` | POST | Provision tenant-scoped account with localized policies. | `abilities:accounts:create` | `AccountProvisionPayload` | `AccountResource` |
| `/api/v1/accounts/{account_slug}` | PATCH | Update account metadata and configuration. | `abilities:accounts:update` | `AccountUpdatePayload` | `AccountResource` |
| `/api/v1/accounts/{account_slug}/users` | POST | Invite or assign user to account context. | `abilities:account-users:create` | `AccountUserPayload` | `AccountUserResource` |
| `/api/v1/accounts/{account_slug}/roles` | POST | Author account-scoped role template. | `abilities:account-roles:create` | `AccountRolePayload` | `AccountRoleResource` |
| `/api/v1/initialize` | GET | Provide initialization manifest with tenant branding, enabled capabilities, and telemetry configuration. | Public | `InitializeQuery` | `InitializationManifest` |

* All authenticated routes leverage Sanctum tokens with ability guards. Initialization now adheres to the versioned namespace `/api/v1/initialize`, keeping client bootstrap aligned with the ecosystem’s API versioning standard. Provisioning and destructive actions emit audit events that integrate with observability pipelines.

#### 3.3 Data Schemas

##### Collection: `tenants`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier. | Yes | Landlord cluster key. |
| `tenant_slug` | String | Immutable slug used for routing and domain mapping. | Yes | Lowercase kebab-case. Unique index. |
| `display_name` | String | Human-readable tenant label. | Yes | |
| `status` | String | Operational status of the tenant. | Yes | Enum. |
| `primary_domain` | String | Canonical tenant domain. | Yes | Validated against DNS format. |
| `branding.theme` | Document | Color palette, typography tokens, asset references. | No | Stored as embedded document. |
| `capability_manifest_id` | ObjectId | Reference to latest manifest document. | Yes | |
| `created_at` | Date | Creation timestamp. | Yes | |
| `updated_at` | Date | Last update timestamp. | Yes | |

**Field Definitions**

* `status`: Valid values are `draft`, `active`, `suspended`, `decommissioned` – describes lifecycle readiness per governance policy.

##### Collection: `accounts`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier. | Yes | Tenant cluster key. |
| `tenant_id` | ObjectId | Owning tenant reference. | Yes | Foreign key to `tenants._id`. |
| `account_code` | String | Immutable code used for routing and scoping. | Yes | Unique per tenant. |
| `display_name` | String | Human-readable account label. | Yes | |
| `account_tier` | String | Segmentation tier. | Yes | Enum. |
| `policy_bundle` | Document | JSON document describing localized policies and limits. | No | |
| `ability_template_id` | ObjectId | Reference to ability template. | No | |
| `created_at` | Date | Creation timestamp. | Yes | |
| `updated_at` | Date | Last update timestamp. | Yes | |

**Field Definitions**

* `account_tier`: Valid values are `default`, `premium`, `enterprise` – align with capability gating and billing tiers.

##### Collection: `capability_manifests`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier. | Yes | Stored per tenant. |
| `tenant_id` | ObjectId | Owning tenant reference. | Yes | |
| `version` | Integer | Manifest version number. | Yes | Incremented on each update. |
| `activation_status` | String | Activation lifecycle for the manifest. | Yes | Enum. |
| `capabilities` | Array<Document> | Array of capability entries (module key, status, configuration map). | Yes | Each entry validated. |
| `applied_at` | Date | Timestamp when manifest became active. | No | |
| `created_at` | Date | Creation timestamp. | Yes | |

**Field Definitions**

* `activation_status`: Valid values are `draft`, `published`, `retired` – track whether clients should consume this manifest.
* `capabilities[].status`: Valid values are `disabled`, `preview`, `active`, `sunset` – signal module availability inside the tenant.

##### Collection: `ability_templates`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier. | Yes | |
| `scope` | String | Scope of the template. | Yes | Enum. |
| `tenant_id` | ObjectId | Tenant reference when scope is tenant. | No | Null for landlord scope. |
| `name` | String | Template display name. | Yes | |
| `abilities` | Array<String> | Sanctum ability strings granted by the template. | Yes | |
| `created_at` | Date | Creation timestamp. | Yes | |
| `updated_at` | Date | Last update timestamp. | Yes | |

**Field Definitions**

* `scope`: Valid values are `landlord`, `tenant` – determines where template is applicable.

##### Collection: `anonymous_sessions`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier. | Yes | Tenant cluster key. |
| `tenant_id` | ObjectId | Owning tenant reference. | Yes | |
| `device_fingerprint` | String | SHA-256 hash of device fingerprint. | Yes | Unique index per tenant. |
| `locale` | String | IETF language tag. | Yes | Defaults to tenant locale. |
| `consent_vector` | Document | Map of consent flags (`marketing`, `analytics`, `personalization`). | Yes | Boolean map. |
| `session_token` | String | Issued anonymous JWT ID. | Yes | |
| `expires_at` | Date | Expiration timestamp. | Yes | |
| `created_at` | Date | Creation timestamp. | Yes | |

**Field Definitions**

* `consent_vector.marketing`: Valid values are `true`, `false` – indicates permission to receive campaigns.
* `consent_vector.analytics`: Valid values are `true`, `false` – indicates telemetry consent.
* `consent_vector.personalization`: Valid values are `true`, `false` – indicates personalization consent.

#### 3.4 Event & Messaging Contracts

* **Outbound Events:**
  * `TenantProvisioned` – emitted after successful tenant creation; payload includes tenant slug, manifest version, operator ID.
  * `CapabilityManifestPublished` – emitted when a manifest transitions to `published`; payload includes capability diff snapshot.
  * `AnonymousSessionRegistered` – emitted when an anonymous session is created; payload captures device fingerprint hash, consent vector.
* **Inbound Events:** `TenantBillingActivated` (from Commercial Engine) to synchronize billing status; `IdentityAbilityTemplateUpdated` (from Identity module) to refresh tenant ability templates.
* **Queue/Topic Configuration:** Events published to `foundation.control-plane` topic (Kafka) with key `{tenant_slug}`. Retention 14 days. Consumers must honor idempotency via event UUID.

#### 3.5 Background Jobs & Schedulers

* `PropagateManifestJob` – asynchronously applies capability manifest changes across tenant microservices; retries with exponential backoff.
* `TenantHealthCheckJob` – hourly job verifying tenant DSNs, domain routing, and Sanctum key rotations; raises alert on failure.
* `AnonymousSessionPurgeJob` – daily TTL sweep deleting expired anonymous sessions and anonymizing associated telemetry IDs.
* All jobs executed via Laravel Horizon queue with Redis backend; jobs include idempotency keys and structured logging.

#### 3.6 Observability & Instrumentation

* **Logs:** JSON structured logs with `tenant_slug`, `account_code`, `request_id`, `ability_scope`, `outcome`, `latency_ms`.
* **Metrics:** Prometheus counters (`tenants_provisioned_total`, `anonymous_sessions_created_total`), histograms (`tenant_provision_latency_seconds`), gauges (`active_manifests`).
* **Tracing:** OpenTelemetry spans named `foundation.control_plane.*`; propagate `traceparent` header to downstream workers; attach `tenant_slug` as baggage.
* **Alerts:** Pager alert when P99 provisioning latency > 2 s for 5 minutes; warning when anonymous session creation errors exceed 1% per tenant; info alert when manifest propagation retries exceed 3 attempts.

#### 3.7 Testing Strategy

* **Unit Tests:** Cover tenant validators, manifest diff utilities, ability template assemblers using PHPUnit.
* **Integration Tests:** Sandbox Mongo landlord + tenant connections to verify provisioning flows, Sanctum abilities, and domain routing.
* **Contract Tests:** Pact-based tests for `/api/v1/initialize` and `/v1/public/sessions` shared with Flutter client; schema snapshots stored in repo.
* **Performance Tests:** k6 scenarios simulating parallel tenant provisioning bursts (up to 5 concurrent) and sustained anonymous session traffic (300 RPS) to validate SLO adherence.

## 4. Cross-Module Considerations

* **Shared Libraries:** Depends on shared DTOs from Identity module and capability enums from the Capability Activation Matrix.
* **Data Ownership Boundaries:** `tenants`, `capability_manifests`, and `anonymous_sessions` are owned exclusively by this module. Identity module consumes ability templates but does not mutate tenant manifests.
* **Failure & Degradation Modes:** If tenant provisioning fails, rollback job deletes partial records and emits `TenantProvisionFailed`. Anonymous session service degrades to cached manifest responses when Mongo latency exceeds 500 ms by leveraging Redis read-through cache.

## 5. Implementation Notes

* **Code Structure:** Maintain PSR-12 compliance. Place controllers under `app/Http/Controllers/Admin/V1` and `app/Http/Controllers/Public/V1`; domain services under `app/Domain/FoundationControlPlane`.
* **Configuration Management:** Store DSNs and manifest defaults in landlord `.env`; restrict tenant secrets to AWS SSM Parameter Store with runtime fetch via Laravel config cache.
* **Deployment Pipeline:** CI pipeline runs static analysis, tests, and publishes Docker image tagged with commit hash. CD promotes image to staging with automated migration of landlord cluster, then executes smoke tests for `/api/v1/initialize`.
* **Ingress Synchronization:** Whenever Laravel route prefixes change, mirror the update in `docker/nginx/*.conf.template` to preserve path routing across local and production deployments.

## 6. Decision Log

| Decision ID | Date | Module(s) | Summary | Status | Rationale | Linked Evidence |
|-------------|------|-----------|---------|--------|-----------|-----------------|
| DEC-001 | 2025-10-19 | foundation_control_plane | Adopt capability manifest documents as the single source of truth for tenant module activation. | Ratified | Ensures deterministic tenant configuration and aligns with Capability Module Activation Matrix governance. | `foundation_documentation/system_roadmap_sections/4-capability-module-activation-matrix.md` |

## 7. Appendices

* **Reference APIs:** Identity module token endpoints (`foundation_documentation/system_roadmap_sections/5-foundational-api-portfolio.md`).
* **Security Review Checklist:** Verify principle of least privilege for Sanctum abilities, enforce TLS on all landlord routes, confirm encrypted storage for anonymous session tokens.
* **Operational Runbooks:** Provisioning rollback guide, manifest publication checklist, anonymous session anomaly investigation SOP.
