# Title
Boilerplate vNext Proof-Time Attestation Refresh 2026-07-12

## Scope
- Root package under test: `docker_laravel_mongodb`
- Proof date: `2026-07-12`
- Reviewed root reconcile HEAD: `80bc4c2f720db956b1d7f7ee217a23432b3f6238`
- Authoritative branch under test: `reconcile/boilerplate-vnext-final-cutover-20260708`
- Root-pinned owner baseline under test: `foundation_documentation@5cc3b8d47cbccbe2032e237b6477146e6791e0cf`
- Newer owner-repo review baseline held outside this attested current-pin carrier: `foundation_documentation/main@448555ac52f93d8342e1ecb75054a81a6d535631`
- Carrier shape: `final-cutover + current-pin clean attestation`

## Root Index OIDs Under Test
- `foundation_documentation`: `5cc3b8d47cbccbe2032e237b6477146e6791e0cf`
- `laravel-app`: `0a5bb112b64a759d30eab2c557edb8480d23f9e8`
- `web-app`: `4654b57f91333d16296d8edadc74a4ea727d95ef`
- `flutter-app`: `5d9ecb07c2c8d947115fa47485e4a3d482229e91`

## Attested Clean Runtime Inputs
- `foundation_documentation`
  - `HEAD`: `5cc3b8d47cbccbe2032e237b6477146e6791e0cf`
  - `status --short --untracked-files=all`: clean
  - `gitlink equality`: matches the exact root index OID under test
- `web-app`
  - `HEAD`: `4654b57f91333d16296d8edadc74a4ea727d95ef`
  - `status --short --untracked-files=all`: clean
  - `gitlink equality`: matches the exact root index OID under test
- `laravel-app`
  - `HEAD`: `0a5bb112b64a759d30eab2c557edb8480d23f9e8`
  - `status --short --untracked-files=all`: clean
  - `runtime-input note`: this is the exact clean backend runtime input exercised by the proof
- `flutter-app`
  - excluded from the attested carrier under the explicit delivered-proof carve-out for `ST-04` / `ST-02`
  - parked local residue included tracked delivered-proof drift plus helper residue under `.agent/**` and `scripts`
- Root helper dirt parked out of the attested carrier:
  - `artifacts/tmp/boilerplate-vnext-proof-time-attestation-20260706.md`
  - `artifacts/tmp/boilerplate-vnext-proof-time-attestation-refresh-template-20260706.md`
  - `.playwright-mcp/**`

## Reversible Attestation Preparation
- Root helper dirt was parked with `git stash push -u -m "final-cutover-root-attestation-park-20260712" -- ...`
- `foundation_documentation` local doc/TODO dirt was parked with `git -C foundation_documentation stash push -u -m "final-cutover-foundation-attestation-park-20260712"`
- `foundation_documentation` was checked back to the already-pinned owner baseline `5cc3b8d47cbccbe2032e237b6477146e6791e0cf`
- `flutter-app` delivered-proof drift plus helper residue was parked with `git -C flutter-app stash push -u -m "final-cutover-flutter-attestation-park-20260712"`
- Cleanliness was verified before proof across root plus `foundation_documentation`, `laravel-app`, `web-app`, and `flutter-app`

## Commands Exercised
- `git rev-parse --abbrev-ref HEAD`
- `git rev-parse HEAD`
- `git status --short --untracked-files=all`
- `git -C foundation_documentation status --short --untracked-files=all`
- `git -C laravel-app status --short --untracked-files=all`
- `git -C web-app status --short --untracked-files=all`
- `git -C flutter-app status --short --untracked-files=all`
- `git ls-files --stage foundation_documentation laravel-app web-app flutter-app`
- `APP_ENV=local COMPOSE_PROFILES=local-db docker compose up -d --build`
- `APP_ENV=local COMPOSE_PROFILES=local-db MONGO_HOST_PORT=27018 docker compose up -d --build`
- `MONGO_HOST_PORT=27018 docker compose ps`
- `bash .github/scripts/check_validation_owner_inputs.sh`
- `bash .github/scripts/verify_environment_ci.sh`
- `bash tools/tests/generic_base_detether_audit.sh`
- `bash tools/ci/run_contract.sh --profile stage-full`
- `bash tools/ci/run_contract.sh --profile main-proof`
- `docker compose exec -T app php artisan test tests/Feature/PublicWeb/PublicWebShellRouteTest.php tests/Feature/Initialization/InitializationControllerTest.php tests/Feature/Push/PushMessageFlowTest.php tests/Feature/Favorites/FavoriteDirectReadQueryContractTest.php tests/Feature/Taxonomies/TaxonomyRegistryControllerTest.php tests/Unit/Queue/TenantAwareQueueJobsTest.php tests/Unit/Config/QueueAndLoggingConfigGuardrailTest.php`

## Results
- `git rev-parse --abbrev-ref HEAD`: `reconcile/boilerplate-vnext-final-cutover-20260708`
- `git rev-parse HEAD`: `80bc4c2f720db956b1d7f7ee217a23432b3f6238`
- Initial canonical local-db bring-up on host port `27017`: blocked with `Bind for 0.0.0.0:27017 failed: port is already allocated`
- Supported local-db retry on `MONGO_HOST_PORT=27018`: passed; `docker compose ps` showed `app` healthy, `mongo` healthy, and `nginx`, `worker`, plus `scheduler` up
- `check_validation_owner_inputs.sh`: passed with `OK: local downstream Laravel/web inputs are materialized.`
- `verify_environment_ci.sh`: passed with `OK: local downstream Laravel/web inputs are materialized.` and `OK: root CI/runtime invariants passed.`
- `generic_base_detether_audit.sh`: passed with `OVERLAY_FREE_DETETHER_AUDIT_OK`
- `stage-full`: passed with `root-invariant-guard`, `generic-base-detether-audit`, and `promotion-runtime-builds-stage` all passing
- `main-proof`: passed with `root-invariant-guard`, `generic-base-detether-audit`, and `promotion-runtime-builds-stage` all passing
- Laravel bounded proof suite: `95 passed (325 assertions)`

## Attestation Outcome
- The approved narrower current-pin path succeeded against the already-pinned owner baseline `foundation_documentation@5cc3b8d47cbccbe2032e237b6477146e6791e0cf`.
- `foundation_documentation` and `web-app` matched the exact root gitlink OIDs under test.
- `laravel-app` was recorded as the clean backend runtime input exercised by the proof.
- Belluga Now downstream parity was preserved during the proof run by leaving the live downstream stack on host port `27017` and using the supported boilerplate override `MONGO_HOST_PORT=27018`.
- Any future move from the current root pin to the newer owner baseline `448555ac52f93d8342e1ecb75054a81a6d535631` still requires the separate broader owner-pin approval path plus a fresh attestation on that repin.
