# Summary: domain_entities.md
**Generated:** 2025-10-19T14:08:00-04:00
**Source Hash:** 4F01E23C1A06BF0BCC425E417155367E46DF3BAEB3872B17682EF653CABE4F7F

## Purpose
- Canonical vocabulary for Belluga boilerplate; entities span governance, experience delivery, learning, commerce, and intelligence.
- Every module specification must anchor to these definitions (principle P-1).

## Governance Entities
- **Tenant:** Isolated environment controlling branding, capability manifests, and data planes.
- **Account:** Scoped subdivision within a tenant with localized policies and rosters.
- **Identity Actor:** Authenticated user or service; maintains credentials, abilities, consent, audits.
- **Anonymous Session:** Pre-auth visitor context with fingerprint, locale, and consent trail.
- **Capability Module:** Reusable domain package delivering schemas, APIs, jobs, observability contracts.
- **Interaction Record:** Immutable ledger of critical events for analytics, billing, lifecycle automation.

## Experience & Engagement
- **Experience Offering, Event Listing, Venue Node:** Public catalog, scheduled instances, and location anchors.
- **Guide Persona / Experience Guide / Experience Host:** AI itinerary strategists, human guides, venue operators.
- **Artist Profile, Fan Identity, Fan Membership Tier:** Artist operations and community entitlements with data portability.
- **Invitation Thread:** Canonical invitation and RSVP construct.
- **Content Hub:** Storytelling aggregations linking experiences and curriculum content.

## Learning Entities
- **Learning Object, Structure Snapshot, Enrollment, Progress Checkpoint:** Core learning constructs managing curricula, state snapshots, learner progression, and assessments.
- **Cohort, Instructor Profile, Requirement Track, Student Document, Document Conversation, Asset:** Collaboration, compliance, and media support artifacts.

## Commerce Entities
- **Catalog Item, Product Package, Price Template/Offer:** Productization and pricing hierarchy.
- **Contract, Invoice, Payment Intent/Transaction, Usage Record, Refund, Credit Note (+ Application):** Financial commitments and ledgering.
- **Promotion Instrument, Attribution Source/Touchpoint:** Incentive and revenue attribution mechanics.

## Intelligence & Taxonomy
- **Taxonomy Group/Term:** Semantic classification backbone.
- **Insight Model/Topic/Rule, User Insight Profile:** Analytics and personalization structures.
- **Knowledge Asset:** Curated operational playbooks and references.

## Collaboration & Ownership Highlights
- Enumerates key relationships (Tenant↔Capability Module, Contracts↔Product Packages, Taxonomy Term↔Insight Rule).
- Defines ownership boundaries across tenants, accounts, identity actors, anonymous sessions, capability modules, and ledgers.
