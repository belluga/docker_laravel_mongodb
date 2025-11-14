# Documentation: Tenant Menu Module
**Version:** 0.1
**Status:** In Design

## 1. Purpose
Design the tenant-facing navigation hub that consolidates every high-frequency capability (documents, finances, learning, focus tools) into a single controllable surface. The module acts as the entry point for contextual flows and therefore must mirror contracts exposed by each contributing engine before new buttons are rendered in the Flutter client.

## 2. Screen Blueprint — Tenant Utility Menu (Light Theme)

| Section | Description | System Contract |
|---------|-------------|-----------------|
| Identity Header | Shows authenticated tenant avatar, full name, and tenant label with entry points to the profile shell and logout. | `foundation_control_plane` (identity + tenant context) |
| Quick Actions List | Nine navigable tiles rendered with the Material 3 light palette. Each tile references one capability and surfaces unread/pending state as part of the label copy. | See per-item mapping below |
| Focus Mode Toggle | Local preference persisted inside the client until the learning engine exposes a formal `/focus-mode` endpoint. Default is `false`; toggle events fire an analytics event and later will call the Laravel API. | `learning_engine` (future API), `multidimension_insights_service` (telemetry) |

### Capability Mapping

| Tile Label | Capability Expectation | Backend Source |
|------------|-----------------------|----------------|
| Meus Documentos | Lists delivered agreements/comprovantes with download links. | `documentation_engine.records` |
| Documentos Pendentes | Highlights outstanding uploads/assinaturas needed for compliance. | `documentation_engine.pending_items` |
| Financeiro | Summaries invoices, cashback, and premium plan status. | `comercial_engine.billing` |
| Eventos | Direct link to the tenant agenda search (existing mock schedule service). | `event_management_engine.events` |
| Meus Cursos | List of enrolled courses/cohorts. | `learning_engine.course_instances` |
| Trilhas da Unifast | Curated fast-track journeys surfaced today. | `learning_engine.fast_tracks` |
| Anotações | Opens the notes module with the add-note modal. | `learning_engine.notes` |
| Mapa de Aprendizagem | Visual progress + taxonomy guidance. | `multidimension_insights_service.learning_map` |
| Certificados | Downloadable certificates with validation QR codes. | `certificates_engine.credentials` |
| Modo Foco (Toggle) | Client-side flag until `/focus-mode` endpoint lands; UI must send desired state to the learning engine once available. | `learning_engine.focus_mode` |

## 3. Flutter Implementation Notes
- Screen must consume `Theme.of(context).colorScheme` for every color reference to ensure runtime tenant theming.
- Menu entries live in the domain layer as `MenuEntryModel` records so the router logic can remain pure UI.
- Every tile needs a tracing identifier so analytics can attribute downstream capability launches.
- Until real endpoints exist, repositories may populate `StreamValue<List<MenuEntryModel>>` with mock data sourced from `assets/mock/menus/`.

## 4. Backend Contract TODOs
1. **Focus Mode Endpoint:** `POST /v1/learning/focus-mode` toggles learner distraction guards. Laravel to define schema + auth requirements.
2. **Document + Finance Counters:** Provide aggregated counters so the tile subtitles can reveal “2 pendências” without fetching the full list.
3. **Certificate Validation Links:** Certificates endpoint must return a QR-safe URL plus localized title/subtitle metadata.

Document updates here before wiring new buttons to avoid UI and API drift.
