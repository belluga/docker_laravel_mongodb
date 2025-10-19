```markdown
# Documentation: Submodule Summary - flutter-app
**Version:** 1.1

## 1. Analyzed Version

* **Submodule Name:** `flutter-app`
* **Commit Hash:** `25c505b64e5d01aa98d32d9af279b031075d9324`
* **Analysis Date:** `2025-10-19`

*Purpose: Capture the current Flutter client architecture so roadmap, backend contracts, and future contributors work from an accurate baseline.*

---

## 2. Core Dependencies & Technologies

* Flutter SDK ^3.3 with Material theming and Flutter Web support.
* `auto_route` 10.x + generator – Declarative router with codegen (`app_router.dart` / `.gr.dart`).
* `get_it` 8.x + `get_it_modular_with_auto_route` – Service locator plus module lifecycle management.
* `dio` 5.9 – Planned HTTP client (actual Laravel backend adapter currently commented out).
* `flutter_secure_storage` 9.x – Persists auth tokens.
* `stream_value` – Lightweight reactive state containers used by repositories.
* `dynatrace_flutter_plugin`, `package_info_plus`, `platform_device_id_plus` – Telemetry and device context.
* UI stack includes `flutter_svg`, `video_player`, `flutter_html`, `visibility_detector`.

---

## 3. Structural Patterns

* **Layered Directory Layout:**
  * `application/` – Cross-platform `ApplicationContract`, router configuration, modular module registry, platform-specific bootstrap (`application_web`, `application_mobile`).
  * `domain/` – Value objects, aggregates (e.g., `UserBelluga`, theme settings), repository contracts, controllers.
  * `infrastructure/` – Repositories implementing domain contracts using service adapters; layered DAL with `mock_backend`, `laravel_backend` (stubbed), and local caches.
  * `presentation/` – Feature-specific screens split by landlord vs tenant contexts, plus common widgets.
* **Modular App Composition:** `ModuleSettings` loads discrete modules (`InitializationModule`, `DashboardModule`, `LmsModule`, `ScheduleModule`, etc.). Each module registers dependencies via GetIt and defines its own routes.
* **Routing Guards:** `TenantRouteGuard`, `AuthRouteGuard`, `IsInitializedGuard` coordinate navigation gating by checking repositories/controllers.
* **State Management:** Repositories expose `StreamValue` observers. UI consumes them via `StreamValueBuilder`; theme updates flow from `ThemeRepository`.
* **Platform Bootstrapping:** `Application` exports either web or mobile contract; mobile variant sets orientation, while web variant (in `application_web.dart`) extends behaviors for web plugins.

---

## 4. Ecosystem Configuration Points

* `pubspec.yaml` – Declares required packages, optional local path dependency (`get_it_modular_with_auto_route`), and asset bundles (`assets/images`, `assets/mock`).
* `lib/application/configurations` – Shared constants (`BellugaConstants` placeholder), widget keys, scroll behavior override, DTO label maps.
* `lib/infrastructure/services/dal` – Defines DTOs, local cache contracts, and mock backends feeding presentation mocks.
* `lib/infrastructure/services/laravel_backend/laravel_backend.dart` – Placeholder for real HTTP integration; currently commented scaffolding demonstrates intended request/response structure.
* `lib/application/router/app_router.dart` – Declarative route graph; `app_router.gr.dart` is generated via `build_runner`.

---

## 5. Architectural Principle Alignment

* **P-1 (Domain-First, Schema-Second):** Partially aligned. Domain layer models (courses, schedule, notes) exist, but they ingest mock JSON; real DTO parsing remains to be wired to backend schemas.
* **P-3 (API-Centric Ecosystem):** Partially aligned. REST client scaffolding is prepared (`LaravelBackend`, repository contracts), yet all production calls are commented out or routed to mock providers.
* **P-4 (Foundational, Not Minimalist):** Partially aligned. Multi-module routing, theme orchestration, and Landlord/Tenant UX shells exist, but integration points (initialization flow, auth, catalog) still depend on mock data.
* **Client Architecture Principles (GetIt modules, guards, responsive UI):** Aligned with planned blueprint; modules already separated by capability.

---

## 6. Key Integration Points / Screens

* **Initialization Flow:** `InitializationModule` routes (`/init`, `/`) and registers controllers for landlord and tenant home screens; guards ensure tenant context before entering main surfaces.
* **Authentication:** `AuthRepository` stores tokens in secure storage and calls `AuthBackendContract`. Actual Laravel backend adapter is stubbed; mock backend returns canned users.
* **Tenant Experiences:** Under `presentation/screens/tenants` – catalog (`lms`), notes, profile, schedule modules with controllers mapping repository outputs to widgets.
* **Landlord Experience:** `presentation/screens/landlord/home_landlord` offers placeholder dashboards leveraging the same modular routing system.
* **Theme & Branding:** `ThemeRepository` streams theme data into `MaterialApp.router`, supporting runtime theme swaps once initialization provides branding colors.

---

## 7. Notes & Observations

* **Backend Gap:** The intended `LaravelBackend` implementation is entirely commented out; repositories rely on `mock_backend` classes. Live API wiring, error handling, and headers need completion before production usage.
* **Guard Logic:** `TenantRouteGuard` and friends assume repositories are initialized; ensure repositories run `init()` early (current `ApplicationContract.init()` calls `super.init()` after base setup).
* **Testing Coverage:** No integration or widget tests target the modular routing or repository logic yet; only default Flutter test scaffolding exists.
* **Asset Management:** Branding/theme assets are expected under `assets/mock/` and `assets/images/`; pipeline for ingesting landlord-provided themes should connect to initialization manifest.
* **Build Tooling:** `flutter_launcher_icons` and `flutter_native_splash` configs are included but not fully parameterized; running the generators will require additional configuration.
```
