## 6. Intelligence, Taxonomy, and Knowledge Entities

- **Taxonomy Group**: Declarative container describing semantic categories (skill, difficulty, theme) that organize terms across modules.
- **Taxonomy Term**: Canonical classification entry scoped to a tenant with immutable `term_key`, optional hierarchy, and human-readable metadata consumed by downstream services.
- **Insight Model**: Definition of analytical dimensions, scoring scales, and thresholds for capabilities like skill progression or risk assessment within the Multidimensional Insights Service.
- **Insight Topic**: Service-local mirror of a taxonomy term tracking which topics participate in specific insight models.
- **Insight Rule**: Declarative mapping between platform triggers (events, identifiers) and point allocations or state transitions applied within an insight model.
- **User Insight Profile**: Aggregated analytics record maintaining per-topic progress, dimensional scores, and computed levels that feed personalization, risk alerts, and reporting.
- **Knowledge Asset**: Curated reference material (playbooks, checklists, best practices) authored by the Documentation Engine or partner modules to support operational excellence and compliance.

---

