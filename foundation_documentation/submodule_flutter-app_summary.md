# Documentation: Submodule Summary - flutter-app
**Version:** 1.0

## 1. Analyzed Version

* **Submodule Name:** `flutter-app`
* **Commit Hash:** `25c505b64e5d01aa98d32d9af279b031075d9324`
* **Analysis Date:** `2025-10-18`

*Purpose: This document summarizes the key architectural aspects of the specified submodule version relevant to the main ecosystem.*

---

## 2. Core Dependencies & Technologies

* Flutter SDK ^3.3.0 (managed via FVM): Primary UI framework and runtime (`flutter-app/.fvm`).
* `auto_route` 10.x (+ generator): Declarative routing with code generation for strongly-typed navigation graphs.
* `get_it` 8.x + `get_it_modular_with_auto_route`: Service locator and modular composition for dependency wiring.
* `dio` 5.9.0: Planned HTTP client for Laravel API consumption.
* `flutter_secure_storage` 9.2.x: Secure local persistence for tokens and secrets on mobile platforms.
* `stream_value` 0.0.6: Lightweight reactive streams backing theming and other observable application state.
* `dynatrace_flutter_plugin` 3.323.x: Built-in APM instrumentation for performance and crash monitoring.
* `value_object_pattern`, `intl`, `flutter_html`, `video_player`: Support domain value objects, localization, rich content, and media playback.

---

## 3. Structural Patterns

* **Overall Structure:** Clean architecture-inspired layering (`application`, `domain`, `infrastructure`, `presentation`) with modular routing.
* **Key Patterns:**
  * `ApplicationContract` bootstraps platform-agnostic initialization, registers router/settings modules, and starts Dynatrace instrumentation (`flutter-app/lib/application/application_contract.dart`).
  * Modular routing defined through `ModuleSettings` and AutoRoute-generated `AppRouter`, guarded by initialization, authentication, and tenant route guards (`flutter-app/lib/application/router`).
  * Domain layer encapsulates business models with value objects (e.g., `AppData`, theme settings, schedule entities) mirroring backend domain language (`flutter-app/lib/domain`).
  * Dependency graph resolved via GetIt; modules register repositories, services, and view models per feature.
  * Theming uses `StreamValueBuilder` to reactively supply `ThemeData` sourced from `ThemeRepository`.
  * Infrastructure services expose contracts (`backend_contract.dart`, `auth_backend_contract.dart`) to abstract API implementations, enabling lifecycle-managed backends.

---

## 4. Ecosystem Configuration Points

* **Configuration Method:** Constants classes, YAML configs, and assets define runtime wiring; environment determined at runtime using URL, platform, and static defaults.
* **Key Variables/Files:**
    * `flutter-app/lib/application/configurations/belluga_constants.dart`: Computes API base URLs (`/api`, `/admin/api`) per platform and environment, sets landlord domain, schema, and Sentry settings.
    * `flutter-app/dynatrace.config.yaml`: Declares Dynatrace beacon configuration required during build.
    * `flutter-app/lib/application/router/modular_app/module_settings.dart`: Central registry mapping feature modules to AutoRoute routes and dependency initializers.
    * `flutter-app/assets/mock/`: Placeholder data for offline development and theming previews.
    * `.fvmrc` and `.fvm/flutter_sdk`: Pin Flutter toolchain version across contributors.

---

## 5. Architectural Principle Alignment

* **P-1 (Domain-First, Schema-Second):** Aligned. Domain entities and value objects reflect platform nouns (tenants, environments, theme settings), keeping application logic anchored to documented business entities.
* **P-3 (API-Centric Ecosystem):** Partially Aligned. HTTP contracts are abstracted behind backend interfaces and constants, but the concrete Laravel backend implementation remains stubbed/commented (`flutter-app/lib/infrastructure/services/laravel_backend/laravel_backend.dart`), so live API consumption is pending.
* **P-4 (Foundational, Not Minimalist):** Partially Aligned. The module scaffolding, guards, and instrumentation provide a comprehensive foundation, yet several TODOs (notes, courses, auth flows) highlight unfinished integration work.
* **P-11 (Stateless Authentication):** Aligned. Authentication design anticipates token storage in secure storage and guard-based route authorization, consistent with Sanctum bearer tokens.

---

## 6. Key Integration Points / API Surface (If Applicable)

* **API Prefix/Base:** `BellugaConstants.api.baseUrl` → `https://{tenant-domain}/api`; landlord administration uses `BellugaConstants.api.adminUrl` (`/admin/api`).
* **Primary Endpoints/Modules:** Router modules (`auth_module`, `dashboard_module`, `initialization_module`, `schedule_module`, `lms_module`, `profile_module`) align with backend domains and determine which backend contracts must be satisfied.
* **Authentication Method:** Planned Sanctum bearer token exchanges via `AuthRepository` and backend contracts; secure storage retains tokens per device.

---

## 7. Notes & Observations

* The Laravel backend service is currently commented out; implementing it (or a mock adapter) is essential before end-to-end API flows can be validated.
* Guards rely on initialization state and tenant context; ensure initialization flow populates `AppData` prior to routing into tenant-specific modules.
* Environment constants default to `"stage"`; document how this ties back to deployment pipeline and whether runtime overrides (e.g., via query params) are required.
* Dynatrace instrumentation (`main.dart`) starts before running the app but still prints debug logs; wrap logging behind environment checks when moving to production.
* Consider centralizing enum/value-object definitions with backend schema docs to keep validation rules synchronized across layers.
