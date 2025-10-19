## 5. Foundational API Portfolio
| Domain | Endpoint | Description | API Status | Notes |
| --- | --- | --- | --- | --- |
| Foundation Control Plane | POST /admin/api/v1/tenants | Provision tenant, bootstrap manifest, and seed landlord credentials. | Defined | Emits `TenantProvisioned` and audit trail entries. |
| Foundation Control Plane | GET /admin/api/v1/tenants/{tenant_id} | Retrieve tenant profile, manifests, and operational status snapshot. | Defined | Requires `Landlord:PlatformAdmin` ability. |
| Foundation Control Plane | POST /admin/api/v1/tenants/{tenant_id}/accounts | Create tenant account with localized policies and ability templates. | Defined | Validates uniqueness of `account_code` per tenant. |
| Foundation Control Plane | PUT /admin/api/v1/tenants/{tenant_id}/capabilities | Publish capability manifest state for the tenant. | Defined | Versioned manifest diff returned on success. |
| Foundation Control Plane | PUT /api/v1/accounts/{account_slug}/abilities | Apply account ability template assignments and overrides. | Defined | Tenant configuration admins only; emits `AbilityTemplateApplied`. |
| Initialization | GET /v1/initialize | Deliver tenant manifest, capability toggles, theming, and telemetry configuration. | Defined | Consumed by Flutter bootstrap and other clients. |
| Anonymous Experience | GET /v1/public/catalog | List public offerings, courses, or content with localization and pagination. | Defined | Supports anonymous device context and geo filters. |
| Anonymous Experience | POST /v1/public/sessions | Register anonymous session with device fingerprint, consent flags, and locale. | Defined | Issues anonymous token for rate limiting and telemetry correlation. |
| Identity | POST /v1/auth/token | Issue access and refresh tokens with ability assignments for authenticated actors. | Defined | Requires MFA challenge metadata when configured. |
| Identity | POST /v1/auth/token/refresh | Rotate expiring tokens, persisting device trust state and revocation entries. | Defined | Honors anonymous-to-authenticated promotion flags. |
| Identity | POST /v1/auth/logout | Terminate access across devices, emitting audit events. | Defined | Supports anonymous context conversion cleanup. |
| Catalog | POST /admin/api/v1/catalog/items | Author catalog entities (offerings, courses, products) with scheduling and pricing metadata. | Defined | Tenant-scoped; enforces capability activation checks. |
| Learning | POST /api/v1/learning/enrollments | Enroll identity actors or anonymous visitors (trial mode) into curricula. | Defined | Supports conversion of anonymous sessions into identities. |
| Learning | POST /admin/api/v1/learning/courses/{course_id}/drip-policies | Capture or revise the drip configuration attached to a course. | Defined | Applies template-based release strategies and initialization overrides. |
| Learning | POST /api/v1/learning/cohorts/{cohort_id}/drip-schedule/preview | Simulate the cohort schedule for planning communications and QA. | Defined | Returns resolved release timestamps per snapshot node. |
| Learning | GET /api/v1/learning/enrollments/{enrollment_id}/drip | Deliver the learner-facing drip state, including upcoming releases. | Defined | Honors role-based access; derived from `enrollment_drip_states`. |
| Learning | POST /api/v1/learning/enrollments/{enrollment_id}/drip/recalculate | Rebuild the learner drip state after manual adjustments. | Defined | Triggers asynchronous recalculation respecting gating and overrides. |
| Checkout | POST /api/v1/checkout/intents | Create payment intent with cart snapshot, pricing adjustments, and compliance flags. | Defined | Accepts optional anonymous session identifier. |
| Analytics | GET /admin/api/v1/reports/activity | Provide aggregated interaction metrics across anonymous and authenticated flows. | Defined | Offers filterable views by module, tenant, account. |
| Artists Empowerment | POST /v1/artists | Register artist profiles and trigger verification workflow. | Defined | Creates artist records and enqueues verification tasks. |
| Artists Empowerment | POST /v1/artists/{artist_id}/formations | Attach formation blueprints to an artist. | Defined | Supports semantic versioning for formations. |
| Artists Empowerment | POST /v1/artists/{artist_id}/rider-packs | Publish rider requirements tied to specific formations. | Defined | Emits `ArtistRiderPublished` event for hosts. |
| Artists Empowerment | POST /v1/artists/{artist_id}/availability | Publish availability windows for artist formations. | Defined | Drives discovery scheduling caches. |
| Artists Empowerment | POST /v1/artists/{artist_id}/fanbase/members | Register or import a fan identity with consent artifacts. | Defined | Artists retain direct ownership of fan data. |
| Artists Empowerment | POST /v1/artists/{artist_id}/fanbase/memberships | Author membership tiers and entitlements for fan communities. | Defined | Surfaces monetization structure for Commercial engine. |
| Artists Empowerment | POST /v1/artists/{artist_id}/fanbase/campaigns | Schedule direct engagement campaigns to targeted fan cohorts. | Defined | Coordinates notification service dispatch with consent checks. |
| Artists Empowerment | POST /v1/artist-performance-requests | Submit booking requests linking hosts and artist formations. | Defined | Initiates negotiation and contract workflows. |
| Artists Empowerment | PUT /v1/artists/{artist_id}/fanbase/members/{fan_id}/preferences | Update fan consent and channel preferences. | Defined | Syncs with consent registry and suppresses unauthorized campaigns. |
| Artists Empowerment | GET /v1/guarappari/artists | Deliver showcase-ready artist payloads to Guar[APP]ari surfaces. | Defined | Read-only projection; prevents data duplication. |
| Invitation Threads | POST /v1/invitations | Create invitation threads with dispatch plans. | Defined | Canonical invitation authoring endpoint. |
| Invitation Threads | POST /v1/invitations/{invitation_id}/invitees | Append invitees or referrals to existing threads. | Defined | Extends threads without duplication. |
| Invitation Threads | POST /v1/invitations/{invitation_id}/dispatch | Trigger or resume dispatch for scheduled nodes. | Defined | Orchestrates multi-channel delivery. |
| Invitation Threads | POST /v1/invitations/{invitation_id}/rsvp | Record RSVP outcomes tied to invitation tokens. | Defined | Feeds analytics and capacity planning. |
| Invitation Threads | GET /v1/invitations/{invitation_id}/analytics | Retrieve engagement metrics. | Defined | Supports campaign optimization. |
| Invitation Threads | GET /v1/guarappari/invitations | Provide Guar[APP]ari invitation projections. | Defined | Read-only projection for client consumption. |

**Field Definitions**
- `API Status`: `Defined` - Contract documented in module specs; `Mocked` - Sandbox responses available; `Implemented` - Backend logic delivered; `Tested & Ready` - Automated and manual validation complete.

