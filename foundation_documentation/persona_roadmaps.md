# Persona Roadmaps

_This document captures project-specific milestones and priorities for each active persona. Update the relevant section whenever a method adds/removes scope that impacts that persona._

## Flutter Engineer
- **School Mock App E2E Build:** Produce the full mock experience in Flutter, including modules that go beyond boilerplate scope (classrooms, schedules, messaging, etc.). Treat boilerplate-capable portions as candidates for future extraction but keep the mock self-contained until assessment.
- **Contract Logging:** While building the mock, log every domain/entity/endpoint assumption so Laravel can evaluate which pieces belong in the boilerplate vs. child packages/services.
- **Tenant Utility Menu Surface:** Deliver the light-themed menu screen wired to the Theme `ColorScheme`, document capability mappings, and keep the tiles aligned with module contracts before exposing new routes.
- **Notes Exploration Screen:** Build the cascading-filter notes explorer with breadcrumb sections, shared note cards, and timestamp-driven video playback per the Learning Engine blueprint.

## Laravel Engineer
- **Mock App Assessment Prep:** Partner with Flutter to review the mock’s module/endpoint inventory. Identify which responsibilities must land in the boilerplate (tenant/account primitives, auth, generic scheduling) versus feature-specific packages or microservices.
- **Boilerplate Wiring Plan:** After the assessment, plan how Laravel will expose the finalized boilerplate responsibilities and integration hooks for the remaining modules.

## DevOps / Docker Engineer
- TODO: Record container, CI/CD, and environment goals.

## CTO / Tech Lead Advisor
- **Mock-to-Boilerplate Decision Framework:** Define the evaluation criteria for the School Mock App review (reuse potential, scalability, tenant fit). Coordinate the decision meeting and update system documentation/methods accordingly.
- **Child Project Alignment:** Once non-boilerplate scope is identified, charter the appropriate child projects (microservice, package, school-specific repo) and ensure their mandates are recorded.
