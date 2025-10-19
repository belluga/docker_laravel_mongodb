## 2. Platform Governance Entities

- **Tenant**: Independent product environment with its own branding, data plane, capability activation matrix, and operational guardrails. Every dataset described in module documentation is scoped to a tenant.
- **Account**: Logical subdivision inside a tenant that localizes policies, rosters, and configuration for a specific audience (partner workspace, learning cohort, storefront). Accounts inherit global governance while expressing context-specific rules.
- **Identity Actor**: Human participant operating within tenant or account context. Identity actors progress through `identity_state` (`anonymous`, `verified`) as they supply contact credentials and consent artifacts. They own authentication credentials, ability assignments, consent decisions, and audit trails.
- **Identity State (Anonymous)**: Pre-verified account user representation captured within the `account_users` document. Stores device fingerprint, locale, consent flags, and personalization seeds until the user verifies contact information and transitions to `identity_state = verified`.
- **Account Credential**: Non-human key material (API tokens, client secrets) issued at the account level to integrate automations or partner systems. Credentials inherit scoped abilities distinct from human identities and are rotated under the account’s governance policies.
- **Capability Module**: Reusable domain package (Identity, Open Experience Access, Catalog, Learning, Checkout, Intelligence, etc.) that exposes hardened APIs, schemas, background jobs, and observability contracts. Tenants enable modules via configuration manifests.
- **Interaction Record**: Immutable ledger capturing significant activity (bookings, enrollments, purchases, completions, telemetry milestones) regardless of authentication state. Interaction records bridge analytics, billing, and lifecycle automation.

---

