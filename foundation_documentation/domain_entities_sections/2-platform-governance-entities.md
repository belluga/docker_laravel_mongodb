## 2. Platform Governance Entities

- **Tenant**: Independent product environment with its own branding, data plane, capability activation matrix, and operational guardrails. Every dataset described in module documentation is scoped to a tenant.
- **Account**: Logical subdivision inside a tenant that localizes policies, rosters, and configuration for a specific audience (partner workspace, learning cohort, storefront). Accounts inherit global governance while expressing context-specific rules.
- **Identity Actor**: Authenticated human or service identity operating within tenant or account context. Identity actors own authentication credentials, ability assignments, consent decisions, and audit trails.
- **Anonymous Session**: Unauthenticated visitor context tracked through device fingerprint, locale, consent flags, and personalization seeds. Anonymous sessions power open catalog access, trials, and attribution flows until promotion to an identity actor.
- **Capability Module**: Reusable domain package (Identity, Anonymous Experience, Catalog, Learning, Checkout, Intelligence, etc.) that exposes hardened APIs, schemas, background jobs, and observability contracts. Tenants enable modules via configuration manifests.
- **Interaction Record**: Immutable ledger capturing significant activity (bookings, enrollments, purchases, completions, telemetry milestones) regardless of authentication state. Interaction records bridge analytics, billing, and lifecycle automation.

---

