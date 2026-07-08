# Title
Boilerplate vNext Proof-Time Attestation Refresh 2026-07-08

## Scope
- Root package under test: `docker_laravel_mongodb`
- Proof date: `2026-07-08`
- Authoritative branch under test: `reconcile/boilerplate-vnext-final-cutover-20260708`
- Packet-carrier authority: `foundation_documentation/main@5cc3b8d47cbccbe2032e237b6477146e6791e0cf`
- Refreshed owner-repo candidate pin recorded in the approval packet: `foundation_documentation@245605cffb25598fbb01d5ed08f516b5cb46f0f3`
- Carrier shape: `final-cutover + laravel-public-web-refresh`

## Root Index OIDs Under Test
- `foundation_documentation`: `5cc3b8d47cbccbe2032e237b6477146e6791e0cf`
- `laravel-app`: `0a5bb112b64a759d30eab2c557edb8480d23f9e8`
- `web-app`: `4654b57f91333d16296d8edadc74a4ea727d95ef`
- `flutter-app`: `5d9ecb07c2c8d947115fa47485e4a3d482229e91`

## Nested HEADs And Clean Status
- `foundation_documentation`
  - `HEAD`: `5cc3b8d47cbccbe2032e237b6477146e6791e0cf`
  - `status --short --untracked-files=all`: clean
  - `gitlink equality`: matches root index
- `web-app`
  - `HEAD`: `4654b57f91333d16296d8edadc74a4ea727d95ef`
  - `status --short --untracked-files=all`: clean
  - `gitlink equality`: matches root index
- `laravel-app`
  - `HEAD`: `0a5bb112b64a759d30eab2c557edb8480d23f9e8`
  - `status --short --untracked-files=all`: clean
  - `runtime-input note`: this is the exact clean backend runtime input exercised by the proof

## Carrier-Shape Note
- Included package shape: `final-cutover + laravel-public-web-refresh`
- Included changed surfaces:
  - root gitlink/index alignment for `foundation_documentation`
  - refreshed proof-time attestation artifact itself
- Excluded drift confirmation:
  - `flutter-app`: absent from the attested carrier under the explicit carve-out decision recorded in the final-cutover packet set
- Root workspace helper artifacts excluded from the carrier:
  - `.playwright-mcp/`
  - `artifacts/tmp/boilerplate-vnext-proof-time-attestation-refresh-template-20260706.md`
  - `flutter-runtime-home.png`

## Commands Exercised
- `git rev-parse --abbrev-ref HEAD`
- `git rev-parse HEAD`
- `git ls-files --stage foundation_documentation laravel-app web-app flutter-app`
- `git -C foundation_documentation log --oneline --decorate -n 5`
- `git -C foundation_documentation branch --contains 245605cffb25598fbb01d5ed08f516b5cb46f0f3`
- `git update-index --cacheinfo 160000 5cc3b8d47cbccbe2032e237b6477146e6791e0cf foundation_documentation`
- `bash .github/scripts/check_validation_owner_inputs.sh`
- `bash .github/scripts/verify_environment_ci.sh`
- `bash tools/tests/generic_base_detether_audit.sh`
- `bash tools/ci/run_contract.sh --profile stage-full`
- `bash tools/ci/run_contract.sh --profile main-proof`
- `docker compose exec -T app php artisan test tests/Feature/PublicWeb/PublicWebShellRouteTest.php tests/Feature/Initialization/InitializationControllerTest.php tests/Feature/Push/PushMessageFlowTest.php tests/Feature/Favorites/FavoriteDirectReadQueryContractTest.php tests/Feature/Taxonomies/TaxonomyRegistryControllerTest.php tests/Unit/Queue/TenantAwareQueueJobsTest.php tests/Unit/Config/QueueAndLoggingConfigGuardrailTest.php`

## Results
- `git rev-parse --abbrev-ref HEAD`: `reconcile/boilerplate-vnext-final-cutover-20260708`
- `git rev-parse HEAD`: `b4a91e133a3dbeab6cc0e0582a4782f5aa518cc5`
- `check_validation_owner_inputs.sh`: passed with `OK: local downstream Laravel/web inputs are materialized.`
- `verify_environment_ci.sh`: passed with `OK: local downstream Laravel/web inputs are materialized.` and `OK: root CI/runtime invariants passed.`
- `generic_base_detether_audit.sh`: passed with `OVERLAY_FREE_DETETHER_AUDIT_OK`
- `stage-full`: passed with `root-invariant-guard`, `generic-base-detether-audit`, and `promotion-runtime-builds-stage` all passing
- `main-proof`: passed with `root-invariant-guard`, `generic-base-detether-audit`, and `promotion-runtime-builds-stage` all passing
- Laravel bounded proof suite: `95 passed (325 assertions)`

## Attestation Outcome
- The proof-time runtime inputs were clean for the attested carrier.
- `foundation_documentation` and `web-app` matched the exact root gitlink OIDs under test.
- `laravel-app` was recorded as the clean backend runtime input exercised by the proof.
- The attested carrier is ready for replay follow-through from the principal reconcile state.
