## 2. Delivery Framework

### 2.1 Phase Cadence
| Phase Code | Phase Name | Focus | Exit Criteria | Dependencies | Lifecycle Status |
| --- | --- | --- | --- | --- | --- |
| P0 | Boilerplate Genesis | Establish multi-tenant landlord/tenant scaffolding, anonymous context handling, and core capability manifests. | Tenant provisioning contracts, anonymous session schema, identity abilities catalog, infrastructure automation runbooks authored. | None | In Design |
| P1 | Capability Baseline | Define reusable modules (Identity, Anonymous Experience, Catalog, Learning, Checkout) with documented APIs and data schemas. | Module documents authored, request/response DTOs finalized, module activation configs delivered. | P0 | Not Started |
| P2 | Experience Orchestration | Align Flutter integration, public discovery flows, and authenticated workspaces with module contracts. | Initialization, anonymous browsing, enrollment, and authenticated dashboards functioning against mocked services. | P1 | Not Started |
| P3 | Commerce and Compliance | Deliver financial flows, consent management, audit trails, and operational tooling applicable to all products. | Checkout ledger schema, payment intent APIs, consent registry, audit pipelines documented and validated. | P2 | Not Started |
| P4 | Intelligence and Growth | Introduce analytics, personalization, AI assistants, and lifecycle automation across modules. | Analytics module specification, recommendation contracts, growth automation playbooks authored. | P3 | Not Started |

**Field Definitions**
- `Lifecycle Status`: `Not Started` - Discovery pending; `In Design` - Architecture authorship underway; `In Build` - Engineering execution active; `In Validation` - QA and stakeholder review; `Operational` - Phase outcomes deployed and monitored.

### 2.2 Capability Streams
- **Foundation Control Plane:** Tenant provisioning, account segmentation, role/ability taxonomy, configuration manifests.
- **Experience Delivery:** Anonymous discovery, authenticated dashboards, module-specific UI contracts for catalog, learning, checkout.
- **Commerce and Compliance:** Transactions, payments, refund mechanics, consent lifecycle, audit and logging.
- **Intelligence:** Analytics pipelines, AI assistants, growth automation, personalization engines.

