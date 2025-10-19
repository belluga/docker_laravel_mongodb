# Documentation: Invitation Threads Service
**Version:** 1.0
**Date:** October 18, 2025
**Authors:** Belluga Architecture Guild

## 1. Overview

This document defines the foundational architecture for the Invitation Threads Service, the microservice responsible for orchestrating invitation-led engagement across the Belluga ecosystem. It provides the authoritative lifecycle for invitations, RSVP capture, viral propagation metrics, and cross-channel delivery controls that power both Belluga flagship experiences and Guar[APP]ari’s discovery flows without data duplication.

## 2. Module Index

| Module ID | Module Name | Primary Responsibility | Status | Owner |
|-----------|-------------|------------------------|--------|-------|
| MOD-012 | Invitation Threads Service | Manage invitation creation, propagation, RSVP handling, and analytics across channels. | Planned | Platform Experience |

## 3. Module Specification Template

### MOD-012: Invitation Threads Service

* **Purpose Statement:** Establish the canonical, multi-channel invitation engine that enables artists, venues, and fans to invite audiences to Belluga experiences (including Guar[APP]ari events) with coherent lifecycle tracking, analytics, and consent-aware delivery.
* **Core Entities:** Invitation Thread, Invitation Node, Invitee Profile, RSVP Record, Distribution Campaign, Propagation Metric Snapshot.
* **Key Workflows:** Invitation authoring, template personalization, multi-channel dispatch, RSVP capture, reminder automation, referral propagation, analytics aggregation, data export requests.
* **External Dependencies:** Identity and Consent modules, Artists Empowerment Service, Experience Host capabilities, Notification service (email/SMS/push/WhatsApp), Commercial engine (for paid upgrades), Analytics pipeline, Guar[APP]ari client integration layer.
* **Service-Level Objectives:** P95 API latency < 200 ms for read/write operations; dispatch queue latency < 60 seconds; RSVP processing < 2 seconds; propagation analytics available within 5 minutes; monthly availability 99.9%.

#### 3.1 Domain Rules

* **Invariants:** Each invitation thread is immutable history; mutations append new nodes without altering previous states. Invitees must have explicit consent artifacts before communication. All RSVP updates are idempotent and traceable. Guar[APP]ari views only consume read models published by this service and never persist invitation copies.
* **Validation Rules:** Invitation threads require a host entity (artist, venue, or tenant account). Each invitation node must declare channel, template, and scheduled dispatch time. Invitee profiles must include at least one validated communication channel when dispatch is requested. RSVP submissions must match invitation tokens and cannot be reassigned. Reminder automation respects frequency capping and consent rules.
* **Authorization Requirements:** Only roles `artist.manager`, `host.curator`, or `platform.invitation_admin` may author invitations. Fans under role `fan.member` may initiate peer invites if granted by the artist’s tier settings. Guar[APP]ari ingestion services with role `guarappari.agent` may read invitation projections but cannot mutate them. Consent registry actors may revoke invitee channels via webhook integration.

#### 3.2 API Endpoint Definitions

| Endpoint | Method | Description | Required Role | Request Schema | Response Schema |
|----------|--------|-------------|---------------|----------------|-----------------|
| `/v1/invitations` | POST | Create an invitation thread with initial invitees and dispatch plan. | `artist.manager` | `InvitationThreadCreateRequest` | `InvitationThreadResponse` |
| `/v1/invitations/{invitation_id}/invitees` | POST | Append invitees or referral seeds to an existing thread. | `artist.manager` | `InvitationInviteeBatchRequest` | `InvitationThreadResponse` |
| `/v1/invitations/{invitation_id}/dispatch` | POST | Trigger dispatch for a scheduled invitation node. | `artist.manager` | `InvitationDispatchRequest` | `InvitationDispatchResponse` |
| `/v1/invitations/{invitation_id}/rsvp` | POST | Submit an RSVP for a specific invite token. | `fan.member` | `InvitationRsvpRequest` | `InvitationRsvpResponse` |
| `/v1/invitations/{invitation_id}/analytics` | GET | Retrieve invitation performance metrics. | `artist.manager` | `InvitationAnalyticsQuery` | `InvitationAnalyticsResponse` |
| `/v1/guarappari/invitations` | GET | Provide Guar[APP]ari with invitation projections linked to public events. | `guarappari.agent` | `GuarappariInvitationQuery` | `GuarappariInvitationResponse` |

**Success Example (`/v1/invitations`):**
```json
{
  "invitation_id": "6510b8c72e0bb20012d12345",
  "status": "scheduled",
  "next_dispatch_at": "2025-10-25T18:00:00Z"
}
```

**Error Example (`/v1/invitations/{invitation_id}/dispatch`):**
```json
{
  "error_code": "consent_violation",
  "message": "Invitee +15551234567 withdrew SMS consent. Update invitee channels before dispatch."
}
```

Rate limiting: 120 invitation authoring operations per minute per artist; RSVP endpoints 500/min; analytics queries 30/min. All endpoints emit audit events with actor, channel, and invite identifiers.

#### 3.3 Data Schemas

##### Collection: `invitation_threads`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Thread identifier. | Yes | |
| `tenant_id` | ObjectId | Tenant scope. | Yes | |
| `host_entity` | Document | Reference to artist, venue, or account initiating invite. | Yes | Contains entity type and id. |
| `context` | Document | Linked experience offering or event listing snapshot. | Yes | |
| `status` | String | Thread lifecycle state. | Yes | Enum below. |
| `visibility` | String | Invitation visibility tier. | Yes | Enum below. |
| `channels` | Array<String> | Channels enabled for this thread. | Yes | Enum below. |
| `source` | String | Origin surface (`artist_portal`, `guarappari`, `api`). | Yes | |
| `metadata` | Document | Custom fields for tracking (campaign tags, segmentation keys). | No | |
| `created_by` | ObjectId | Actor initiating thread. | Yes | |
| `created_at` | Date | Timestamp. | Yes | |
| `updated_at` | Date | Timestamp. | Yes | |

**Field Definitions**

* `status`: `draft`, `scheduled`, `dispatching`, `completed`, `canceled`.
* `visibility`: `private`, `invite_only`, `public`.
* `channels`: `email`, `sms`, `push`, `whatsapp`, `in_app`, `link_share`.

##### Collection: `invitation_nodes`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Node identifier. | Yes | |
| `invitation_id` | ObjectId | Parent thread. | Yes | |
| `sequence` | Number | Dispatch order. | Yes | |
| `channel` | String | Delivery channel. | Yes | Enum below. |
| `template_id` | ObjectId | Content template reference. | Yes | |
| `scheduled_for` | Date | Planned dispatch time. | Yes | |
| `dispatched_at` | Date | Actual dispatch time. | No | |
| `status` | String | Node status. | Yes | Enum below. |
| `audience_segment` | Document | Segment filters for this node. | No | |
| `created_at` | Date | Timestamp. | Yes | |
| `updated_at` | Date | Timestamp. | Yes | |

**Field Definitions**

* `channel`: `email`, `sms`, `push`, `whatsapp`, `in_app`, `link_share`.
* `status`: `pending`, `dispatched`, `partially_dispatched`, `failed`, `canceled`.

##### Collection: `invitation_invitees`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Invitee identifier. | Yes | |
| `invitation_id` | ObjectId | Parent thread. | Yes | |
| `invitee_profile` | Document | Contact data (name, email, phone). | Yes | |
| `consent_artifacts` | Array<Document> | Consent records with purpose, channel, timestamp. | Yes | At least one when dispatching. |
| `token` | String | Unique RSVP token. | Yes | |
| `status` | String | Invitee status. | Yes | Enum below. |
| `channels` | Array<String> | Allowed channels. | Yes | Enum below. |
| `referred_by` | ObjectId | Optional invitee id that referred this contact. | No | |
| `metadata` | Document | Custom fields (seat count, notes). | No | |
| `created_at` | Date | Timestamp. | Yes | |
| `updated_at` | Date | Timestamp. | Yes | |

**Field Definitions**

* `status`: `pending`, `sent`, `opened`, `responded`, `declined`, `bounced`.
* `channels`: `email`, `sms`, `push`, `whatsapp`, `in_app`, `link_share`.

##### Collection: `invitation_rsvps`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | RSVP identifier. | Yes | |
| `invitation_id` | ObjectId | Parent thread. | Yes | |
| `invitee_id` | ObjectId | Invitee responding. | Yes | |
| `response` | String | RSVP response. | Yes | Enum below. |
| `guest_count` | Number | Additional guests. | No | |
| `notes` | String | Optional notes. | No | |
| `occurred_at` | Date | Timestamp. | Yes | |
| `channel` | String | Channel used for response. | Yes | |
| `audit` | Document | IP, user agent, and verification data. | Yes | |
| `created_at` | Date | Timestamp. | Yes | |

**Field Definitions**

* `response`: `going`, `maybe`, `declined`, `waitlisted`.
* `channel`: `web`, `mobile`, `sms`, `whatsapp`, `call_center`.

##### Collection: `invitation_metrics`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Metric snapshot id. | Yes | |
| `invitation_id` | ObjectId | Parent thread. | Yes | |
| `time_bucket` | Date | Aggregation bucket (hourly). | Yes | |
| `sent_count` | Number | Total sent invites. | Yes | |
| `open_count` | Number | Total opens. | Yes | |
| `rsvp_count` | Number | Total RSVPs. | Yes | |
| `share_count` | Number | Shares initiated. | Yes | |
| `conversion_count` | Number | Completed actions (purchases, bookings). | No | |
| `channel_breakdown` | Document | Per-channel metrics. | Yes | |
| `created_at` | Date | Timestamp. | Yes | |

##### Collection: `invitation_projections`

**Schema Definition**

| Field | Type | Description | Required | Notes |
|-------|------|-------------|----------|-------|
| `_id` | ObjectId | Projection id. | Yes | |
| `invitation_id` | ObjectId | Source thread. | Yes | |
| `target_surface` | String | Consumer surface (`guarappari`, `artist_portal`, `public_share`). | Yes | |
| `payload` | Document | Denormalized snapshot for target. | Yes | |
| `hash` | String | Content hash for cache validation. | Yes | |
| `generated_at` | Date | Timestamp. | Yes | |

#### 3.4 Event & Messaging Contracts

* **Outbound Events:**
  * `InvitationThreadCreated`: Published when a thread is authored.
  * `InvitationDispatchRequested`: Triggered when dispatch is queued for a node.
  * `InvitationRSVPRecorded`: Emits RSVP payload for analytics, capacity planners, and Commercial engine.
  * `InvitationProjectionUpdated`: Provides payload hash updates for Guar[APP]ari and other consumers.
* **Inbound Events:**
  * `ConsentRevoked`: From consent registry; suppresses channels for related invitees.
  * `ExperienceUpdated`: From Experience Host module; refreshes invitation context snapshots.
  * `PurchaseCompleted`: From Commercial engine; may upgrade invitation visibility to public.
* **Queue/Topic Configuration:** Kafka topics per tenant namespace (`invitations.thread`, `invitations.dispatch`, `invitations.rsvp`, `invitations.projection`); partition by `invitation_id`; retention 30 days with compaction for projections.

#### 3.5 Background Jobs & Schedulers

* Dispatch scheduler runs every minute to enqueue nodes whose `scheduled_for` time has arrived.
* Reminder automation job evaluates pending RSVPs and respects consent-based throttling.
* Projection generator updates `invitation_projections` at most every 2 minutes per thread for Guar[APP]ari.
* Analytics aggregator compiles hourly metric snapshots and publishes to analytics pipeline.
* Data retention job archives invitations older than configurable thresholds, preserving analytics aggregates.

#### 3.6 Observability & Instrumentation

* **Logs:** Structured logs with `invitation_id`, `node_id`, `invitee_id`, `channel`, `actor_id`, `action_type`.
* **Metrics:**
  * Counters: `invitations_created_total`, `invitation_dispatch_total`, `invitation_rsvp_total`, `invitation_projection_total`.
  * Gauges: `pending_invitation_dispatch`, `pending_rsvp_responses`.
  * Histograms: `invitation_dispatch_latency_seconds`, `rsvp_processing_latency_seconds`, `projection_generation_latency_seconds`.
* **Tracing:** Trace API and dispatch pipelines; propagate `tenant_id`, `invitation_id`, `channel`; include spans for consent checks, delivery provider calls, and projection generation.
* **Alerts:** Trigger on dispatch failure rate > 5% over 15 minutes, RSVP backlog > 500 items, projection latency > 5 minutes, consent revocation queue backlog > 100 events.

#### 3.7 Testing Strategy

* **Unit Tests:** Validate consent enforcement, token generation, RSVP idempotency, projection hashing.
* **Integration Tests:** Execute end-to-end invitation creation through dispatch with in-memory MongoDB and mocked notification services; verify Guar[APP]ari projections match source data.
* **Contract Tests:** Pact tests for `/v1/invitations`, `/v1/invitations/{id}/rsvp`, `/v1/guarappari/invitations`, and `InvitationProjectionUpdated` events.
* **Performance Tests:** Load tests simulating 5k concurrent invitation dispatches and 10k RSVP submissions per hour; soak tests for long-running projection jobs.

## 4. Cross-Module Considerations

* **Shared Libraries:** Employ shared DTOs for invitee profiles, consent artifacts, and event listings; align with notification templates and analytics schemas.
* **Data Ownership Boundaries:** Invitation Threads Service is the single source of truth for invitations and RSVPs. Notification service handles delivery but stores no canonical state. Guar[APP]ari consumes projections without persisting original invitation data.
* **Failure & Degradation Modes:** Defer dispatch to retry queues if notification providers are degraded; provide read-only projections from last successful snapshot if projection job fails; pause referral expansion when consent registry is unavailable.

## 5. Implementation Notes

* **Code Structure:** Laravel-based service under `app/Services/Invitations`, API controllers in `app/Http/Api/v1/Invitations`, dispatch orchestrators under `app/Jobs/Invitations`, DocumentModels in `app/Models/Tenants/Invitations`.
* **Configuration Management:** Environment variables `INVITATION_DISPATCH_QUEUE`, `INVITATION_REMINDER_CRON`, `INVITATION_TEMPLATE_BUCKET`, `INVITATION_PROJECTION_TOPIC`, `INVITATION_WEBHOOK_SECRET`. Secrets managed via landlord configuration; templates stored in tenant-isolated object storage.
* **Deployment Pipeline:** CI stages run lint, unit, integration, contract, and security scans; CD leverages blue/green deployment with feature flags for new channels; MongoDB schema validators updated with zero downtime.

## 6. Decision Log

| Decision ID | Date | Module(s) | Summary | Status | Rationale | Linked Evidence |
|-------------|------|-----------|---------|--------|-----------|-----------------|
| DEC-012-001 | 2025-10-18 | Invitation Threads Service | Centralize all invitation lifecycle logic in a dedicated microservice. | Proposed | Prevents duplication across Belluga applications and Guar[APP]ari. | N/A |
| DEC-012-002 | 2025-10-18 | Invitation Threads Service, Guar[APP]ari | Serve Guar[APP]ari via projection endpoints instead of direct database access. | Proposed | Guarantees read-only consumption and consistent payloads. | N/A |

## 7. Appendices

* **Reference APIs:** Artists Empowerment (artist profiles), Experience Host (event listings), Commercial engine (paid upgrades), Notification service delivery APIs, Consent registry webhook definitions, Guar[APP]ari ingestion guide.
* **Security Review Checklist:** Enforce RBAC on invitation authoring; encrypt invitee PII at rest; log access to invitee data; handle consent revocations within SLA; provide audit-ready RSVP records.
* **Operational Runbooks:** Dispatch failure troubleshooting, notification provider outage response, projection backlog remediation, data export fulfillment, abuse detection for viral invites.
