## 4. Capability Module Activation Matrix
| Module | Description | Primary Entities | Phase | Lifecycle Status |
| --- | --- | --- | --- | --- |
| Identity | Role, ability, and authentication services for human and machine actors, distributed as Laravel/Flutter packages. | Tenant, Account, Identity Actor | P1 | Not Started |
| Anonymous Experience | Public content delivery, device fingerprinting, progressive profiling, rate limiting via reusable middleware and UI widgets. | Anonymous Context, Interaction Record | P1 | Not Started |
| Catalog | Structured representation of offerings, courses, and content assets delivered through shared backend/frontend libraries. | Capability Module, Interaction Record | P1 | Not Started |
| Learning | Learner enrollment, curriculum management, assessment tracking with pluggable services and presentation kits. | Account, Identity Actor, Interaction Record | P1 | Not Started |
| Artists Empowerment | Artist lifecycle, fanbase ownership, rider management, and performance collaboration tooling. | Artist Profile, Fan Identity, Fan Membership Tier | P2 | In Design |
| Invitation Threads | Canonical invitation orchestration, RSVP tracking, and viral propagation analytics. | Invitation Thread, Invitation Node, Invitee Profile | P2 | Planned |
| Checkout | Cart orchestration, payment intents, transaction ledger wrapped in configurable gateway adapters. | Interaction Record, Identity Actor | P3 | Not Started |
| Intelligence | Analytics pipelines, recommendations, lifecycle automation exposed as optional capability libraries. | Capability Module, Interaction Record | P4 | Not Started |

**Field Definitions**
- `Lifecycle Status`: `Not Started` - Module blueprint pending; `In Design` - Architectural document in authorship; `In Build` - Engineering execution underway; `In Validation` - QA and stakeholder sign-off; `Operational` - Module deployed as reusable asset.

