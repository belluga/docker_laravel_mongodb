## 7. Entity Collaboration Landscape

1. **Tenant <-> Capability Module:** Tenants activate capability modules through configuration manifests that enumerate required schemas, APIs, package versions, and observability dashboards. Deactivation preserves historical interaction records for compliance.
2. **Account <-> Identity Actor:** Accounts assign identity actors to scoped roles and abilities, aligning with RBAC policies while inheriting tenant-wide authentication, consent, and audit standards.
3. **Identity State (Anonymous) <-> Experience Offering:** Anonymous-state account users interact with public APIs to browse offerings, register interest, and feed attribution touchpoints, remaining compliant with consent and rate-limiting rules.
4. **Enrollment <-> Learning Object:** Enrollments consume learning objects through structure snapshots, generating progress trackers, checkpoint responses, and assessment artifacts governed by cohort state.
5. **Contract <-> Product Package:** Contracts bind product packages to immutable price offers, enabling invoices, payment transactions, refunds, usage records, and attribution snapshots without mutating the original catalog definitions.
6. **Taxonomy Term <-> Insight Rule:** Taxonomy terms provide stable semantic keys consumed by insight rules, enabling the Multidimensional Insights Service to evaluate events and emit progression signals without direct database coupling.

---

