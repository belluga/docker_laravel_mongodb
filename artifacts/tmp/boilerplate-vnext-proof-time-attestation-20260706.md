# Title
Boilerplate vNext Proof-Time Attestation 2026-07-08

## Scope
- Root package under test: `docker_laravel_mongodb`
- Proof date: `2026-07-08`
- Canonical branch under test: `dev`
- Carrier shape: `final-cutover + laravel-public-web-refresh`

## Root Index OIDs Under Test
- `foundation_documentation`: `60189af148624768003237535f6af22bbd98490c`
- `laravel-app`: `0a5bb112b64a759d30eab2c557edb8480d23f9e8`
- `web-app`: `4654b57f91333d16296d8edadc74a4ea727d95ef`
- `flutter-app`: `5d9ecb07c2c8d947115fa47485e4a3d482229e91`

## Nested HEADs And Clean Status
- `foundation_documentation`
  - `HEAD`: `60189af148624768003237535f6af22bbd98490c`
  - `status --short --untracked-files=all`: clean
  - `gitlink equality`: matches root index
- `web-app`
  - `HEAD`: `4654b57f91333d16296d8edadc74a4ea727d95ef`
  - `status --short --untracked-files=all`: clean
  - `gitlink equality`: matches root index
- `laravel-app`
  - `HEAD`: `0a5bb112b64a759d30eab2c557edb8480d23f9e8`
  - `status --short --untracked-files=all`: clean
  - `runtime-input note`: this is the clean backend runtime input exercised by the proof suite
- `flutter-app`
  - `HEAD`: `9aa11b2f3416231c919a9c962b55e36967fc3601`
  - `status --short --untracked-files=all`:
    - `.agent/rules/flutter-architecture-always-on.md`
    - `.agent/rules/flutter-contract-alignment-always-on.md`
    - `.agent/rules/flutter-controller-workflow-glob.md`
    - `.agent/rules/flutter-documentation-contracts-always-on.md`
    - `.agent/rules/flutter-domain-workflow-glob.md`
    - `.agent/rules/flutter-repository-workflow-glob.md`
    - `.agent/rules/flutter-route-workflow-glob.md`
    - `.agent/rules/flutter-screen-workflow-glob.md`
    - `.agent/rules/shared/core-instructions-always-on.md`
    - `.agent/rules/shared/foundation-docs-sync-model-decision.md`
    - `.agent/rules/shared/initialization-readiness-model-decision.md`
    - `.agent/rules/shared/project-mandate-always-on.md`
    - `.agent/rules/shared/realtime-delta-streams-model-decision.md`
    - `.agent/rules/shared/self-improvement-manual.md`
    - `.agent/rules/shared/session-lifecycle-model-decision.md`
    - `.agent/rules/shared/todo-driven-execution-model-decision.md`
    - `.agent/rules/shared/workflow-definition-model-decision.md`
    - `.agent/workflows/create-controller-method.md`
    - `.agent/workflows/create-domain-method.md`
    - `.agent/workflows/create-repository-method.md`
    - `.agent/workflows/create-route-method.md`
    - `.agent/workflows/create-screen-method.md`
    - `scripts`
  - `carrier note`: excluded from the attested carrier under the explicit `final-cutover + laravel-public-web-refresh` shape and the previously recorded bounded Flutter residue carve-out

## Carrier-Shape Note
- Included package shape: `final-cutover + laravel-public-web-refresh`
- Included changed surfaces:
  - root gitlink/index alignment for `foundation_documentation`
  - root gitlink/index alignment for `laravel-app`
  - refreshed attestation artifact itself
- Excluded drift confirmation:
  - `flutter-app` remained outside the attested carrier under the explicit carve-out decision above

## Commands Exercised
- `git ls-files --stage foundation_documentation laravel-app web-app flutter-app`
- `git -C foundation_documentation rev-parse HEAD`
- `git -C foundation_documentation status --short --untracked-files=all`
- `git -C web-app rev-parse HEAD`
- `git -C web-app status --short --untracked-files=all`
- `git -C laravel-app rev-parse HEAD`
- `git -C laravel-app status --short --untracked-files=all`
- `docker compose exec -T app php artisan test tests/Feature/PublicWeb/PublicWebShellRouteTest.php tests/Feature/Initialization/InitializationControllerTest.php tests/Feature/Push/PushMessageFlowTest.php tests/Feature/Favorites/FavoriteDirectReadQueryContractTest.php tests/Feature/Taxonomies/TaxonomyRegistryControllerTest.php tests/Unit/Queue/TenantAwareQueueJobsTest.php tests/Unit/Config/QueueAndLoggingConfigGuardrailTest.php`
- `bash .github/scripts/check_validation_owner_inputs.sh`
- `bash .github/scripts/verify_environment_ci.sh`
- `bash tools/tests/generic_base_detether_audit.sh`
- `bash tools/ci/run_contract.sh --profile stage-full`
- `bash tools/ci/run_contract.sh --profile main-proof`

## Results
- Laravel bounded proof suite: `95 passed (325 assertions)`
- `check_validation_owner_inputs.sh`: passed on local-input-only path
- `verify_environment_ci.sh`: passed
- `generic_base_detether_audit.sh`: passed with `OVERLAY_FREE_DETETHER_AUDIT_OK`
- `stage-full`: passed with overlay-free body `root-invariants.json + promotion-runtime-builds.json`
- `main-proof`: passed with overlay-free body `root-invariants.json + promotion-runtime-builds.json`

## Attestation Outcome
- The proof-time runtime inputs were clean for the attested carrier.
- `foundation_documentation`, `laravel-app`, and `web-app` matched the exact root gitlink OIDs under test.
- `laravel-app` was recorded as the clean backend runtime input exercised by the proof.
- The bounded Flutter residue remained explicitly excluded from the attested carrier under the approved carrier shape.
- Promotion-facing technical proof is ready for the attested carrier; any further blocker is governance or replay follow-through, not the proof itself.
