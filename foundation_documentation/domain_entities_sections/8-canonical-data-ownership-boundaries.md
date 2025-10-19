## 8. Canonical Data Ownership Boundaries

- Tenants own configuration manifests, capability activation states, and cross-module governance directives.
- Accounts own localized policies, membership rosters, requirement sets, and context-specific asset libraries.
- Identity Actors own authentication credentials, consent preferences, device trusts, and personal profile data.
- Identity State (Anonymous) retains ephemeral personalization state, attribution breadcrumbs, and consent decisions until the associated account user promotes to `identity_state = verified`.
- Capability Modules own domain schemas, API contracts, event vocabularies, background workloads, and observability assets associated with their entities.
- Interaction Records, Contracts, and Insight Profiles own the immutable ledgers required for auditing, analytics, billing, and lifecycle automation across anonymous and authenticated journeys.

