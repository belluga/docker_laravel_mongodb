


# Documentation: Domain Entities
**Version:** 1.1

## 1. Introduction

This document enumerates the Core Business Entities (CBEs) that shape the Belluga Platform Boilerplate. The entities span platform governance, experience delivery, learning, commerce, and intelligence capabilities. They provide the canonical vocabulary that every downstream product (Guar[APP]ari, Learning Portal, Checkout, and future initiatives) inherits when the boilerplate is activated. Each entity aligns with `system_architecture_principles.md` (Principle P-1) and anchors the module specifications maintained in `foundation_documentation/modules/`.

---

## 2. Platform Governance Entities

- **Tenant**: Independent product environment with its own branding, data plane, capability activation matrix, and operational guardrails. Every dataset described in module documentation is scoped to a tenant.
- **Account**: Logical subdivision inside a tenant that localizes policies, rosters, and configuration for a specific audience (partner workspace, learning cohort, storefront). Accounts inherit global governance while expressing context-specific rules.
- **Identity Actor**: Authenticated human or service identity operating within tenant or account context. Identity actors own authentication credentials, ability assignments, consent decisions, and audit trails.
- **Anonymous Session**: Unauthenticated visitor context tracked through device fingerprint, locale, consent flags, and personalization seeds. Anonymous sessions power open catalog access, trials, and attribution flows until promotion to an identity actor.
- **Capability Module**: Reusable domain package (Identity, Anonymous Experience, Catalog, Learning, Checkout, Intelligence, etc.) that exposes hardened APIs, schemas, background jobs, and observability contracts. Tenants enable modules via configuration manifests.
- **Interaction Record**: Immutable ledger capturing significant activity (bookings, enrollments, purchases, completions, telemetry milestones) regardless of authentication state. Interaction records bridge analytics, billing, and lifecycle automation.

---

## 3. Experience and Engagement Entities

- **Experience Offering**: Public-facing description of a service, event, or curated itinerary presented to anonymous and authenticated audiences. Offerings expose availability, pricing signals, taxonomy tags, and the roster of guides, hosts, and artists involved.
- **Guide Persona**: Digital or AI itinerary strategist that generates self-guided journeys, content playlists, and contextual advice. Guide personas personalize recommendations, maintain conversational memory, and hand off into human-led flows when an experience requires a live specialist.
- **Experience Guide**: Human professional who delivers live or concierge-style experiences (city tours, themed excursions, bespoke tastings). Experience guides store licensing credentials, service regions, availability calendars, compensation terms, and direct relationships to the offerings and event listings they fulfill.
- **Experience Host**: Venue-based operator (restaurants, bars, galleries, partner spaces) responsible for curating hospitality-driven experiences. Hosts manage operating hours, seating or capacity policies, menu or package catalogs, staffing rosters, and partnership agreements that anchor on specific offerings.
- **Artist Profile**: Individual or collective performer attached to events (musicians, chefs-in-residence, mixologists, guest speakers). Artist profiles capture genres, rider requirements, booking windows, compensation structures, and collaborative history across hosts and guides.
- **Fan Identity**: Artist-owned relationship record that captures fan consent artifacts, preferred engagement channels, membership status, and personalization tags while guaranteeing data portability for the fan.
- **Fan Membership Tier**: Structured entitlement layer that defines benefits, pricing models, and access rules for fan communities, linking directly to monetization instruments and engagement campaigns.
- **Event Listing**: Time-bound manifestation of an experience, including schedule slots, capacity, location metadata, and associated offering snapshot. Listings enumerate the assigned experience guide, hosting venue, and participating artists to power scheduling, logistics, and marketing surfaces.
- **Venue Node**: Geospatial anchor that aggregates map coordinates, accessibility details, media, and contact points for venues referenced across agendas, offerings, and logistics. Venue nodes link to experience hosts to differentiate permanent locations from pop-up installations.
- **Content Hub**: Aggregated storytelling unit (articles, collections, thematic guides) that connects experiences, products, and learning modules to support discovery journeys.
- **Invitation Thread**: Social engagement construct that links initiator, invitees, target offering or event, RSVP states, and propagation telemetry used by viral growth mechanics.

---

## 4. Learning Ecosystem Entities

- **Course Template**: Prototype configuration describing canonical curriculum structure, required documentation, and assessment strategy. Templates act as the immutable source for cloning new course blueprints.
- **Course Blueprint**: Sellable master structure derived from a template, defining ordered modules, gating rules, learning object placements, and associated requirement sets before cohort instantiation.
- **Cohort**: Live instance of a course blueprint bound to schedule, facilitators, enrollment limits, and branded communications. Cohorts persist a structure snapshot to preserve historical integrity.
- **Structure Snapshot**: Immutable tree captured at cohort creation, containing node identifiers, sequencing, and requirement metadata required to evaluate progress gates and assessments.
- **Enrollment**: Relationship between an identity actor and a cohort (or anonymous session during trials). Enrollments centralize status hubs, capability access, and links to progress, assessment, and documentation records.
- **Learning Object**: Atomic educational asset (video, reading, activity, assessment placeholder) with polymorphic payload definitions and checkpoint configuration. Objects remain agnostic of placement and reuse across blueprints.
- **Progress Tracker**: Append-only log of per-enrollment node progression capturing timestamps, completion state, and granular metrics emitted by the learning engine.
- **Progress Summary**: Denormalized analytics document aggregating completion percentage, engagement streaks, pacing status, learning profile insights, and cross-engine indicators for rapid UI access.
- **Checkpoint Response**: Immutable record of lightweight interactive elements embedded within learning objects, storing responses, correctness, and behavioral telemetry.
- **Assignment Submission**: Student-provided artifact for subjective assignments, capturing content payload, delivery channel, timestamps, and state machine progression.
- **Submission Review**: Evaluator feedback document linked to an assignment submission, encapsulating grading rubric outcomes, comments, and review audit history.
- **Quiz Template**: Prototype describing attempts, timing, question pools, feedback strategy, and passing rules. Serves as the scaffold for individual quizzes.
- **Quiz**: Immutable assessment assembled from a quiz template with frozen question snapshots, scoring policies, and availability windows.
- **Quiz Attempt**: Historical log of a participant's interaction with a quiz, including answer snapshots, scoring outcomes, completion timestamps, and manual grading flags.
- **Quiz Attempt Allowance**: Adjustment record granting additional attempts or overrides for specific participants while maintaining auditability.
- **Annotation**: Private learner artifact (notes, highlights, bookmarks) anchored to enrollment and node identifiers, preserving context across sessions.
- **Document Requirement Set**: Prototype library of required documents and workflow stages reused across courses and cohorts, mapped to canonical statuses.
- **Student Document**: Lifecycle record of a learner's submission for a specific document requirement, including versioned file uploads, stage transitions, and reviewer notes.
- **Document Conversation**: Communication thread associated with a student document, capturing informal guidance and clarifications exchanged between reviewer and learner.
- **Asset**: Tenant-wide library entry for media objects (video, audio, image, document) referenced by learning, experience, and commerce modules with ownership metadata and storage descriptors.

---

## 5. Commerce and Revenue Entities

- **Catalog Item**: Atomic sellable unit (course bundle, experience, physical good, service) with media gallery and descriptive attributes. Items act as building blocks for product packaging.
- **Product Package**: Commercial bundle referencing catalog items, quantity mixes, and merchandising assets, tailored for specific audiences or channels.
- **Price Template**: Prototype defining billing cadence, payment terms, proration rules, and discount structures used to generate immutable prices.
- **Price Offer**: Concrete commercial record cloned from a template capturing currency, tiers, billing cycles, usage allowances, and activation windows. Prices act as the source of truth for sales terms.
- **Contract**: Immutable snapshot of the selected price offer coupled with buyer, account, attribution, and fulfillment metadata at the moment of sale.
- **Invoice**: Billing artifact aggregating line items, tax calculations, discounts, and payment status for a specific contract or usage period.
- **Payment Intent**: Authorization request containing payable amount, payment method references, risk signals, and compliance checks prior to capture.
- **Payment Transaction**: Settled financial movement linked to an invoice or contract, storing gateway response, settlement timestamps, and reconciliation identifiers.
- **Usage Record**: Metered event documenting consumable quantities under a contract for post-paid billing or analytics.
- **Refund**: Immutable ledger of returned funds against a payment transaction including reason codes and processing state.
- **Credit Note**: Non-cash instrument granting service credits with remaining balance tracking and issuance context.
- **Credit Note Application**: Audit trail detailing how credit notes reduce invoice balances over time.
- **Promotion Instrument**: Discount or incentive mechanism (coupon, service credit, campaign code) defining eligibility rules and redemption metrics.
- **Attribution Source**: Unified catalog of affiliates, sales representatives, campaigns, and partner programs eligible for revenue credit, including tracking codes and lifecycle status.
- **Attribution Touchpoint**: Immutable record of interactions between anonymous or authenticated actors and attribution sources, supporting commission, ROI, and funnel analysis.

---

## 6. Intelligence, Taxonomy, and Knowledge Entities

- **Taxonomy Group**: Declarative container describing semantic categories (skill, difficulty, theme) that organize terms across modules.
- **Taxonomy Term**: Canonical classification entry scoped to a tenant with immutable `term_key`, optional hierarchy, and human-readable metadata consumed by downstream services.
- **Insight Model**: Definition of analytical dimensions, scoring scales, and thresholds for capabilities like skill progression or risk assessment within the Multidimensional Insights Service.
- **Insight Topic**: Service-local mirror of a taxonomy term tracking which topics participate in specific insight models.
- **Insight Rule**: Declarative mapping between platform triggers (events, identifiers) and point allocations or state transitions applied within an insight model.
- **User Insight Profile**: Aggregated analytics record maintaining per-topic progress, dimensional scores, and computed levels that feed personalization, risk alerts, and reporting.
- **Knowledge Asset**: Curated reference material (playbooks, checklists, best practices) authored by the Documentation Engine or partner modules to support operational excellence and compliance.

---

## 7. Entity Collaboration Landscape

1. **Tenant <-> Capability Module:** Tenants activate capability modules through configuration manifests that enumerate required schemas, APIs, package versions, and observability dashboards. Deactivation preserves historical interaction records for compliance.
2. **Account <-> Identity Actor:** Accounts assign identity actors to scoped roles and abilities, aligning with RBAC policies while inheriting tenant-wide authentication, consent, and audit standards.
3. **Anonymous Session <-> Experience Offering:** Anonymous sessions interact with public APIs to browse offerings, register interest, and feed attribution touchpoints, remaining compliant with consent and rate limiting rules.
4. **Enrollment <-> Learning Object:** Enrollments consume learning objects through structure snapshots, generating progress trackers, checkpoint responses, and assessment artifacts governed by cohort state.
5. **Contract <-> Product Package:** Contracts bind product packages to immutable price offers, enabling invoices, payment transactions, refunds, usage records, and attribution snapshots without mutating the original catalog definitions.
6. **Taxonomy Term <-> Insight Rule:** Taxonomy terms provide stable semantic keys consumed by insight rules, enabling the Multidimensional Insights Service to evaluate events and emit progression signals without direct database coupling.

---

## 8. Canonical Data Ownership Boundaries

- Tenants own configuration manifests, capability activation states, and cross-module governance directives.
- Accounts own localized policies, membership rosters, requirement sets, and context-specific asset libraries.
- Identity Actors own authentication credentials, consent preferences, device trusts, and personal profile data.
- Anonymous Sessions own ephemeral personalization state, attribution breadcrumbs, and consent decisions until promotion to identity actors.
- Capability Modules own domain schemas, API contracts, event vocabularies, background workloads, and observability assets associated with their entities.
- Interaction Records, Contracts, and Insight Profiles own the immutable ledgers required for auditing, analytics, billing, and lifecycle automation across anonymous and authenticated journeys.



