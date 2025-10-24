# Documentation: Foundation Control Plane Module
**Version:** 1.2

## 1. Module Index

| Module ID | Module Name | Primary Responsibility | Status | Owner |
|-----------|-------------|------------------------|--------|-------|
| MOD-001 | `foundation_control_plane` | Establishes tenant provisioning, account segmentation, identity_state lifecycle, and scoped anonymous identity issuance for P0. | In Design | Delphi Architecture Guild |

## 2. Module Specification Template

### MOD-001: `foundation_control_plane`

* **Purpose Statement:** Establish the authoritative Laravel service surface for provisioning tenants, segmenting accounts, advancing the identity_state lifecycle (anonymous → registered → validated), and issuing scoped anonymous identities that guard early interactions.
* **Core Entities:** Tenant, Account, Account User (Identity Actor), Capability Toggle, Anonymous Access Policy.
* **Key Workflows:** Tenant creation with capability configuration, account provisioning, scoped anonymous identity issuance, identity promotion to verified, ability management for clients.
* **External Dependencies:** MongoDB (control-plane database and tenant-scoped logical databases), Laravel Sanctum, environment-configured secrets.
* **Service-Level Objectives:** P99 latency = 350 ms for read endpoints, = 1.2 s for provisioning writes; availability = 99.5%; successful tenant bootstrap completion = 99.9% within 60 s.

#### 3.1 Domain Rules
* **Invariants:** Tenant slugs are immutable once provisioned and map 1:1 to logical Mongo databases. Each tenant must retain at least one administrative account capable of issuing ability grants and promoting identities. Account users hold a single canonical document per tenant and transition identity_state strictly in order (`anonymous` → `registered` → `validated`). Scoped anonymous identities are created at first stateful interaction and remain until promotion or expiry. Credential attachments (email/password, OAuth providers) may include multiple entries per provider for a single identity, but every credential must map to exactly one `account_users._id`; cross-identity duplication is disallowed.
* **Anonymous Consolidation:** When an identity graduates from anonymous to registered/validated, the canonical `account_users` document absorbs all fingerprint history, consents, and metadata. The superseded anonymous records are copied verbatim into the archival `merged_account_snapshots` collection (including `merged_into`, `merged_at`, `operator_id`) and then hard-deleted from the live set so active queries never surface merged ghosts. The archival collection is append-only and subject to retention policies defined by governance. A companion `identity_merge_audits` ledger records the canonical user id, merged source ids, timeline aggregates, operator context, and preserved promotion history while leaving `promotion_audit` embedded on `account_users` dedicated to lifecycle transitions only.
* **Identity Timeline Stewardship:** `account_users.first_seen_at` captures the earliest known interaction (anonymous or authenticated) and is immutable once established. `account_users.registered_at` records the first promotion into `identity_state = registered` and remains `null` while the identity is anonymous. Anonymous issuance, password registrations, and merge workflows must preserve these timestamps so downstream analytics trust the timeline.
* **Validation Rules:** Tenant and account slugs follow `^[a-z0-9-]{3,32}$`. Account user email and phone arrays enforce uniqueness via partial indexes. Device fingerprints captured for anonymous-state auditing are SHA-256 hashes. Capability toggles accept only module identifiers registered in the capability catalogue. External credential providers must be registered in the capability catalogue before links are permitted.
* **Authorization Requirements:** Landlord provisioning endpoints require Sanctum abilities `tenants:create` or `tenants:read`. Tenant-scoped administrative actions rely on abilities such as `accounts:*` and `account-users:*`. Anonymous actors obtain scoped access only by requesting `/v1/anonymous/identities`, which issues short-lived tokens without mutating tenant state.

#### 3.2 API Endpoint Definitions

| Endpoint | Method | Description | Required Ability | Request Schema | Response Schema |
|----------|--------|-------------|------------------|----------------|-----------------|
| `/v1/initialize` | POST | Bootstrap the landlord context, first tenant, and administrative operator. | Guest | `InitializationRequest` | `InitializationResource` |
| `/v1/initialize` | GET | Report whether initialization has executed. | Guest | `n/a` | `InitializationStatusResource` |
| `/v1/auth/token` | POST | Issue Sanctum token for landlord or tenant operators. | Guest | `AuthCredentialsPayload` | `AuthTokenResource` |
| `/v1/tenants` | POST | Provision tenant with capability toggles and branding seed. | `tenants:create` | `TenantProvisionPayload` | `TenantResource` |
| `/v1/tenants/{tenant_slug}` | GET | Retrieve tenant profile, capability toggles, and branding snapshot. | `tenants:read` | `n/a` | `TenantResource` |
| `/v1/anonymous/identities` | POST | Issue scoped anonymous identity token bound to tenant policies. | Guest | `AnonymousIdentityRequest` | `AnonymousIdentityResource` |
| `/v1/accounts` | POST | Create account within the current tenant and seed default abilities. | `accounts:create` | `AccountProvisionPayload` | `AccountResource` |
| `/v1/accounts/{account_id}` | GET | Retrieve account metadata and capability toggles. | `accounts:read` | `n/a` | `AccountResource` |
| `/v1/account-users` | POST | Register account user; defaults to identity_state `registered`. | `account-users:create` | `AccountUserPayload` | `AccountUserResource` |
| `/v1/account-users/{user_id}` | PATCH | Promote account user to verified state and update ability grants. | `account-users:update` | `AccountUserPromotionPayload` | `AccountUserResource` |

#### 3.3 Data Schemas

##### Collection: `tenants`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier stored in the landlord database. | Yes | |
| `name` | String | Tenant display name. | Yes | |
| `slug` | String | Immutable slug used for routing and database naming. | Yes | Unique index generated from `name`. |
| `database_name` | String | Tenant database name. | Yes | Derived from slug (`tenant_{slug}`). |
| `status` | String | Operational status of the tenant. | Yes | Enum: `active`, `suspended`. |
| `branding.primary_color` | String | Hex color token for theming. | No | Defaults to `#0F172A`. |
| `branding.secondary_color` | String | Secondary palette token. | No | |
| `branding.logo_url` | String | CDN path for logo asset. | No | |
| `capabilities` | Array<Document> | Capability toggles with version metadata. | Yes | Each entry stores `module_id`, `enabled`, `schema_version`. |
| `created_by` | ObjectId | Reference to operator that provisioned the tenant. | Yes | Points to landlord user record. |
| `created_at` | Date | Creation timestamp. | Yes | |
| `updated_at` | Date | Last update timestamp. | Yes | |

##### Collection: `accounts`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier stored in the tenant database. | Yes | |
| `tenant_id` | ObjectId | Owning tenant reference. | Yes | Indexed with `_id` for scoped queries. |
| `name` | String | Account display name. | Yes | |
| `slug` | String | Slug generated from name, unique per tenant. | Yes | Lowercase, hyphenated. |
| `default_abilities` | Array<String> | Ability slugs automatically granted to new account users. | Yes | e.g., `catalog:view`, `identity:promote`. |
| `capabilities` | Array<Document> | Account-specific toggle overrides. | No | Entries mirror `tenants.capabilities`. |
| `settings` | Document | Configuration map for account-specific preferences. | No | |
| `description` | String | Optional account summary. | No | |
| `created_at` | Date | Creation timestamp. | Yes | |
| `updated_at` | Date | Last update timestamp. | Yes | |

##### Collection: `account_users`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier stored in the tenant database. | Yes | |
| `tenant_id` | ObjectId | Owning tenant reference. | Yes | Indexed with `_id`. |
| `display_name` | String | Preferred display name. | No | |
| `emails` | Array<String> | Contact email addresses. | No | Partial unique index per tenant. |
| `phones` | Array<String> | Contact phone numbers. | No | Partial unique index per tenant. |
| `identity_state` | String | Lifecycle state of the identity. | Yes | Enum: `anonymous`, `verified`. |
| `fingerprints` | Document | Device fingerprint metadata captured when issuing anonymous identity. | Yes | Stores `hash`, `first_seen_at`, `last_seen_at`, `user_agent`. |
| `credentials` | Array<Document> | Linked credential providers. | Yes | Each entry stores provider metadata. |
| `credentials.provider` | String | Credential provider ID (`password`, `google`, `apple`, etc.). | Yes | Multiple entries per provider allowed. |
| `credentials.subject` | String | Provider-specific subject identifier. | Yes | Unique per provider. |
| `credentials.secret_hash` | String | Hashed password or token secret (when applicable). | No | Present only for password credentials. |
| `credentials.linked_at` | Date | Timestamp when credential was linked. | Yes | |
| `credentials.last_used_at` | Date | Timestamp of last successful authentication using this credential. | No | |
| `consents` | Document | Consent artifacts keyed by policy id. | Yes | Contains `terms_version`, `marketing_opt_in`, `updated_at`. |
| `promotion_audit` | Array<Document> | History of identity_state transitions. | Yes | Each entry stores `from_state`, `to_state`, `promoted_at`, `operator_id`. |
| `remember_token` | String | Sanctum remember token. | No | |
| `created_at` | Date | Creation timestamp. | Yes | |
| `updated_at` | Date | Last update timestamp. | Yes | |
| `verified_at` | Date | Timestamp when identity_state first reached `verified`. | No | |

**Field Definitions**

* `identity_state`: `anonymous` (device fingerprint captured, limited abilities), `registered` (contact recorded without validation), or `validated` (contact/credential confirmed; full access granted and promotion audit appended).
* `credentials.provider`: Enumerated providers maintained in the capability catalogue (`password`, `google`, `apple`, `microsoft`, etc.). Multiple credentials from the same provider (e.g., several Gmail accounts) may link to one identity.
* `credentials.subject`: Provider-specific identifier; uniqueness enforced per provider so a credential cannot link to multiple identities.
* `credentials.secret_hash`: Optional hashed secret for password credentials; multiple password entries may reuse the same hash when the user elects a shared password across email aliases.

##### Collection: `landlord_users`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier stored in the landlord database. | Yes | |
| `name` | String | Operator display name. | Yes | |
| `emails` | Array<String> | Contact email addresses used for landlord authentication. | Yes | Lowercased on write; partial unique index per landlord. |
| `phones` | Array<String> | Optional contact phone numbers. | No | Partial unique index per landlord. |
| `identity_state` | String | Landlord identity lifecycle state. | Yes | Enum: `registered`, `validated`. |
| `credentials` | Array<Document> | Credential evidence linked to the landlord operator. | Yes | Each entry mirrors the tenant credential structure. |
| `promotion_audit` | Array<Document> | History of landlord identity promotions. | Yes | Stores `from_state`, `to_state`, `promoted_at`, optional `operator_id`. |
| `tenant_roles` | Array<Document> | Embedded tenant role assignments. | Yes | Snapshot of permissions granted per tenant. |
| `verified_at` | Date | Timestamp of first promotion to `validated`. | No | |
| `created_at` | Date | Creation timestamp. | Yes | |
| `updated_at` | Date | Last update timestamp. | Yes | |

**Field Definitions**

* `identity_state`: `registered` (operator created, credential captured) or `validated` (credential verified; promotion audit appended). Anonymous issuance is not available for landlord identities.
* `credentials`: Same providers and document shape as tenant `account_users.credentials`, enabling multiple login methods per landlord operator.

##### Collection: `interaction_records`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Primary identifier stored in the tenant database. | Yes | |
| `tenant_id` | ObjectId | Owning tenant reference. | Yes | Indexed with `recorded_at`. |
| `account_id` | ObjectId | Account context for the interaction. | Yes | |
| `actor_id` | ObjectId | Reference to `account_users._id`; nullable when actor is anonymous. | No | |
| `actor_state` | String | Identity state at the time of interaction. | Yes | Enum: `anonymous`, `verified`. |
| `interaction_type` | String | Category of activity performed. | Yes | Enum seeded in capability catalogue (e.g., `initialization`, `anonymous_identity_issued`, `enrollment_intent`). |
| `capability_origin` | String | Module responsible for the interaction. | Yes | e.g., `foundation_control_plane`. |
| `payload` | Document | Structured details of the interaction. | Yes | Validated via JSON schema references per capability. |
| `request_context` | Document | Metadata such as IP, user-agent, locale. | Yes | |
| `trace_id` | String | Correlates to distributed trace or log context. | Yes | |
| `recorded_at` | Date | Timestamp when interaction was recorded. | Yes | |
| `created_at` | Date | Creation timestamp. | Yes | Defaults to `recorded_at`. |

**Field Definitions**

* `interaction_type`: Enumerated catalogue maintained alongside capability registry; default set for P0 includes `initialization`, `anonymous_identity_issued`, `identity_promotion`, `ability_assignment`.
* `payload`: Each capability publishes a JSON schema snippet to validate payload structure (e.g., for `identity_promotion` enforce presence of `previous_state`, `new_state`, `operator_id`).

#### 3.4 Event & Messaging Contracts

* **Outbound Events:**
  * `TenantProvisioned` – emitted after successful tenant creation; payload includes tenant slug, database name, capability toggles, and operator ID.
  * `IdentityPromoted` – emitted when an account user transitions from `anonymous` to `verified`; payload captures `tenant_id`, `account_id`, `user_id`, and promotion metadata.
* **Inbound Events:** None for P0. Downstream billing and catalog activation events remain out of scope until P1.
* **Queue/Topic Configuration:** Events publish to the `foundation.control-plane` topic (Kafka) with key `{tenant_slug}`. Retention seven days. Consumers enforce idempotency via event UUID.

#### 3.5 Background Jobs & Schedulers

* `AnonymousIdentityExpiryJob` – expires stale anonymous identity tokens and cleans up fingerprint records when dormant beyond policy thresholds.
* `CredentialLinkAuditJob` – periodically verifies credential uniqueness and deactivates orphaned credential entries when provider deauthorizes access.
* `IdentityPromotionAuditJob` – reconciles `interaction_records` with account user promotion history to guarantee audit completeness.
* Jobs execute via Laravel Horizon backed by Redis; each job persists idempotency keys and structured logs.

#### 3.6 Observability & Instrumentation

* **Logs:** JSON structured logs capturing `tenant_slug`, `account_id`, `request_id`, `identity_state`, `ability_scope`, `outcome`, `latency_ms`, `credential_provider`.
* **Metrics:** Prometheus counters (`tenants_provisioned_total`, `anonymous_tokens_issued_total`, `credentials_linked_total`, `account_users_by_state_total`), histograms (`tenant_provision_latency_seconds`, `identity_promotion_latency_seconds`, `credential_link_latency_seconds`), gauges (`active_capabilities_total`).
* **Tracing:** OpenTelemetry spans named `foundation.control_plane.*`; propagate `traceparent` headers and include `identity_state` baggage for promotion flows. Credential linking spans add `credential_provider` attribute.
* **Alerts:** Pager alert when P99 provisioning latency > 2 s for five minutes; warning when identity promotion failure rate exceeds 5% per tenant over one hour; informational alert when anonymous token issuance or credential linking spikes 3× over baseline within 15 minutes.

#### 3.7 Testing Strategy

* **Unit Tests:** Cover tenant provisioning validators, anonymous identity issuance policies, credential linking invariants, and identity_state transitions using PHPUnit.
* **Integration Tests:** Exercise initialization bootstrap, tenant provisioning, account creation, anonymous identity issuance, credential linking/unlinking, and account user promotion flows across landlord and tenant Mongo connections. Each critical flow is verified against primary and secondary tenants to catch cross-tenant regression risk.
* **Contract Tests:** Pact-based tests for `/v1/initialize`, `/v1/anonymous/identities`, `/v1/account-users`, `/v1/account-users/{user_id}/credentials`, and `/v1/auth/token` shared with Flutter and other clients; schema snapshots stored in repo.
* **Performance Tests:** k6 scenarios simulating parallel tenant provisioning bursts (up to five concurrent) and sustained anonymous identity issuance + credential linking + promotion throughput (300 RPS) to validate SLO adherence.

## 4. Cross-Module Considerations

* **Shared Libraries:** Depends on shared DTOs from the capability catalogue (module identifiers, ability slugs, credential providers) and identity token payload structures consumed by downstream services.
* **Data Ownership Boundaries:** `tenants`, `accounts`, `account_users`, and `interaction_records` are owned exclusively by this module. Anonymous identity tokens and credential links are issued and revoked only through the control plane.
* **Failure & Degradation Modes:** On provisioning failure, rollback removes partially created tenants and emits `TenantProvisionFailed`. If anonymous identity issuance fails repeatedly, tenants enter restricted mode disallowing new anonymous interactions until remediation. If credential linking fails validation, the system raises alerts and locks further credential attachments for that identity until resolved.

## 5. Implementation Notes

* **Code Structure:** Maintain PSR-12 compliance. Group controllers by capability (`InitializationController`, `TenantController`, `AccountController`, `AccountUserController`, `AnonymousIdentityController`) under `app/Http/V1/Controllers`. Domain services live in `app/Domain/FoundationControlPlane`, encapsulating provisioning, anonymous identity issuance, and identity promotion logic.
* **Configuration Management:** Store landlord DSNs and anonymized token policies in environment variables. Tenant database switching leverages Spatie Multitenancy’s `TenantDatabaseManager`; capability toggles hydrate from configuration caches warmed during boot. Partial indexes on `account_users.emails`/`phones` and compound indexes on `interaction_records` are declared via migration classes.
* **Deployment Pipeline:** CI executes static analysis, unit, integration, and contract suites before publishing Docker images. CD pipelines migrate landlord schema, iterate tenants with `php artisan tenants:migrate`, seed capability toggles, then run smoke tests for `/v1/initialize`, `/v1/tenants`, `/v1/anonymous/identities`, and `/v1/account-users`.
* **Ingress Synchronization:** Anonymous identity, tenant APIs, and authentication endpoints share the `/v1` prefix; nginx and gateway manifests mirror this path structure to avoid drift across environments.
* **Document Modeling Playbook:** Favor the native `DocumentModel` casting behavior for embedded BSON arrays/documents (e.g., `fingerprints`, `credentials`) and introduce custom casts only when normalization is essential. Apply the `MongoDB\Laravel\Eloquent\DocumentModel` trait to classes that extend Laravel's base `Model`; do not extend the trait directly. This avoids double-encoding, preserves ObjectId fidelity, and keeps multi-device fingerprint histories consistent across sessions.

## 6. Decision Log

| Decision ID | Date | Module(s) | Summary | Status | Rationale | Linked Evidence |
|-------------|------|-----------|---------|--------|-----------|-----------------|
| DEC-001 | 2025-10-19 | foundation_control_plane | Adopt identity_state lifecycle (anonymous → registered → validated) anchored on `account_users` with partial unique contact indexes. | Ratified | Aligns control plane behavior with roadmap decisions and Flutter expectations. | `foundation_documentation/system_roadmap_sections/2-delivery-framework.md` |

## 7. Appendices

* **Reference APIs:** Endpoint catalogue maintained in `foundation_documentation/system_roadmap_sections/5-foundational-api-portfolio.md` (initialize, auth token issuance, anonymous identity issuance, account onboarding).
* **Security Review Checklist:** Enforce least-privilege Sanctum abilities, require TLS for all `/v1` routes, verify hashed credential storage, and audit anonymous token policies on schedule.
* **Operational Runbooks:** Provisioning rollback guide, identity promotion troubleshooting, anonymous identity issuance checklist (see `foundation_documentation/runbooks/p0_infrastructure_bootstrap.md` for environment bootstrap steps).
| `/v1/account-users/{user_id}/credentials` | POST | Link external credential (email/password, OAuth provider) to identity. | `account-users:update` (self or admin) | `CredentialLinkPayload` | `AccountUserResource` |
| `/v1/account-users/{user_id}/credentials/{credential_id}` | DELETE | Unlink external credential from identity. | `account-users:update` (self or admin) | `n/a` | `AccountUserResource` |
