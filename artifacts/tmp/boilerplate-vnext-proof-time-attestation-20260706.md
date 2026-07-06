# Title
Boilerplate vNext Proof-Time Attestation 2026-07-06

## Scope
- Root package under test: `docker_laravel_mongodb`
- Proof date: `2026-07-06`
- Canonical branch under test: `dev`

## Root Index OIDs Under Test
- `foundation_documentation`: `71102ec29b1a8735a5bcc5aa945dfb88dfbfc649`
- `laravel-app`: `861730211babc12674640021f133cf87ba99237b`
- `web-app`: `4654b57f91333d16296d8edadc74a4ea727d95ef`
- `flutter-app`: `5d9ecb07c2c8d947115fa47485e4a3d482229e91`

## Nested HEADs And Clean Status
- `foundation_documentation`
  - `HEAD`: `71102ec29b1a8735a5bcc5aa945dfb88dfbfc649`
  - `status --short --untracked-files=all`: clean
  - `gitlink equality`: matches root index
- `web-app`
  - `HEAD`: `4654b57f91333d16296d8edadc74a4ea727d95ef`
  - `status --short --untracked-files=all`: clean
  - `gitlink equality`: matches root index
- `laravel-app`
  - `HEAD`: `861730211babc12674640021f133cf87ba99237b`
  - `status --short --untracked-files=all`: clean
  - `runtime-input note`: this is the clean backend runtime input exercised by the proof reruns and Laravel test suite

## Commands Exercised
- `docker compose exec -T app php artisan test tests/Feature/Initialization/InitializationControllerTest.php tests/Feature/Push/PushMessageFlowTest.php tests/Feature/Favorites/FavoriteDirectReadQueryContractTest.php tests/Feature/Taxonomies/TaxonomyRegistryControllerTest.php tests/Unit/Queue/TenantAwareQueueJobsTest.php tests/Unit/Config/QueueAndLoggingConfigGuardrailTest.php`
- `bash .github/scripts/check_validation_owner_inputs.sh`
- `bash .github/scripts/verify_environment_ci.sh`
- `bash tools/tests/generic_base_detether_audit.sh`
- `bash tools/ci/run_contract.sh --profile stage-full`
- `bash tools/ci/run_contract.sh --profile main-proof`

## Results
- Laravel bounded proof suite: `89 passed (270 assertions)`
- `check_validation_owner_inputs.sh`: passed on local-input-only path
- `verify_environment_ci.sh`: passed
- `generic_base_detether_audit.sh`: passed with `OVERLAY_FREE_DETETHER_AUDIT_OK`
- `stage-full`: passed with overlay-free body `root-invariants.json + promotion-runtime-builds.json`
- `main-proof`: passed with overlay-free body `root-invariants.json + promotion-runtime-builds.json`

## Attestation Outcome
- The proof-time runtime inputs were clean.
- `foundation_documentation` and `web-app` matched the exact root gitlink OIDs under test.
- `laravel-app` was recorded as the clean backend runtime input exercised by the proof.
- Local technical genericization/proof is complete; any remaining release gate is approval/promotion governance rather than Belluga Now runtime detethering.
