## 5. Foundational API Portfolio
| Domain | Endpoint | Description | API Status | Notes |
| --- | --- | --- | --- | --- |
| Foundation Control Plane | POST /admin/api/v1/tenants | Provision a tenant, generate default admin role template, and migrate tenant database. | Implemented | Emits audit trail; tenant slug generated from name. |
| Foundation Control Plane | GET /admin/api/v1/tenants/{tenant_slug} | Retrieve tenant profile, domains, and operational status snapshot. | Implemented | Requires Sanctum ability `tenants:read`. |
| Foundation Control Plane | PATCH /admin/api/v1/tenants/{tenant_slug} | Update tenant metadata (name, branding data, domains). | Implemented | Supports identity_state notes for default operators. |
| Foundation Control Plane | DELETE /admin/api/v1/tenants/{tenant_slug} | Soft-delete tenant and revoke active role templates. | Implemented | `tenants:delete` ability; can be restored. |
| Foundation Control Plane | POST /admin/api/v1/tenants/{tenant_slug}/restore | Restore soft-deleted tenant. | Implemented | Reinstates tenant DB connection and roles. |
| Foundation Control Plane | POST /admin/api/v1/branding/update | Upload landlord branding assets and regenerate variants. | Implemented | Uses Intervention Image; enforces Sanctum ability `tenant-branding:update`. |
| Environment | GET /environment | Retrieve landlord or tenant branding/theme configuration. | Implemented | Canonical endpoint used by clients; replaces legacy `/branding`. |
| Initialization | POST /api/v1/initialize | Bootstrap landlord, first tenant, and initial landlord admin identity; returns Sanctum token. | Implemented | Enforces single-run guard via `isInitialized` check. |
| Initialization | GET /api/v1/initialize | Report whether initialization has already run. | Implemented | Returns 403 until initialization completes. |
| Identity (Landlord) | POST /admin/api/v1/auth/login | Issue Sanctum token for landlord operator. | Implemented | Email/password credentials stored in landlord cluster. |
| Identity (Landlord) | POST /admin/api/v1/auth/logout | Revoke landlord token. | Implemented | Requires active token; clears abilities. |
| Identity (Tenant) | POST /api/v1/auth/login | Authenticate tenant/account operators and return token plus identity_state. | Implemented | Uses `account_users` collection; anonymous state until contact verified. |
| Identity (Tenant) | POST /api/v1/auth/logout | Revoke tenant/account token. | Implemented | Invalidates current device session. |
| Identity (Tenant) | POST /api/v1/auth/password_token | Issue password reset token for tenant operator. | Implemented | Persists in `password_reset_tokens`. |
| Identity (Tenant) | POST /api/v1/anonymous/identities | Issue scoped anonymous identity token for fingerprinted guests. | Implemented | Reuses fingerprint to return the same actor; policies stored in tenant `anonymous_access_policy`. |
| Account Management | POST /api/v1/accounts | Create tenant account (slug derived from name) and optional document identifier. | Implemented | Requires `accounts:create` ability. |
| Account Management | PATCH /api/v1/accounts/{account_slug} | Update account display data and settings. | Implemented | Supports partial updates; respects soft-delete state. |
| Account Membership | POST /api/v1/accounts/{account_slug}/users | Invite or add account user with initial identity_state = anonymous. | Implemented | Stores contact arrays and embedded role assignments. |
| Account Membership | PATCH /api/v1/accounts/{account_slug}/users/{user_id} | Update account user profile, credentials, or role embeddings. | Implemented | Verification promotes identity_state to `verified`. |
| Account Role Templates | POST /api/v1/accounts/{account_slug}/roles | Create account role template with scoped permissions. | Implemented | Slug duplicates allowed per Spatie sluggable config. |
| Account Role Templates | PATCH /api/v1/accounts/{account_slug}/roles/{role_id} | Update role template metadata/permissions. | Implemented | Supports soft delete and restore endpoints. |
| Tenant Domains | POST /api/v1/domains | Register tenant domains for routing. | Implemented | Accepts list of domains; stored in landlord cluster. |
| Tenant Domains | DELETE /api/v1/domains/{domain_id} | Remove tenant domain mapping. | Implemented | Soft delete with restore/force-delete variants. |
| Open Experience Access | GET /api/v1/public/catalog | Deliver public catalog with identity_state = anonymous allowances. | Planned | Will rely on Identity module promotion flow; not yet implemented. |
| Open Experience Access | POST /api/v1/public/catalog/favorites | Capture anonymous-state preference signal. | Planned | Requires anonymous-state token issuance (future). |

**Field Definitions**
- `API Status`: `Defined` - Contract documented in module specs; `Mocked` - Sandbox responses available; `Implemented` - Backend logic delivered; `Tested & Ready` - Automated and manual validation complete.
