# Title
Boilerplate vNext Proof-Time Attestation Refresh Template 2026-07-06

## Purpose
Use this template only after the accepted clean promotion carrier is assembled according to:
- `foundation_documentation/artifacts/tmp/boilerplate-vnext-final-cutover-clean-carrier-manifest-20260706.md`
- `foundation_documentation/artifacts/tmp/boilerplate-vnext-final-cutover-clean-carrier-reconciliation-20260706.md`
- `foundation_documentation/artifacts/tmp/TODO-boilerplate-vnext-final-detether-cutover-and-promotion.approval-packet-refreeze-20260706.md`

This template is for the refreshed proof-time attestation that must replace the historical `artifacts/tmp/boilerplate-vnext-proof-time-attestation-20260706.md` once the carrier is clean again.

## Scope
- Root package under test: `docker_laravel_mongodb`
- Proof date: `2026-07-06` or later actual execution date
- Canonical branch under test: `dev`
- Package shape under test:
  - `final-cutover-only`
  - or `final-cutover + laravel-public-web-refresh`
  - or `final-cutover + flutter-runtime-refresh`
  - or `final-cutover + laravel-public-web-refresh + flutter-runtime-refresh`

## Pre-Attestation Checklist
- [ ] Carrier matches the accepted include/exclude file set from the clean-carrier manifest.
- [ ] Any excluded `flutter-app` drift is absent from the attested workspace and is excluded only under the accepted package shape plus an explicit higher-level carve-out decision.
- [ ] `foundation_documentation` nested `HEAD` matches the root gitlink OID under test.
- [ ] `web-app` nested `HEAD` matches the root gitlink OID under test.
- [ ] `laravel-app` `HEAD` and clean status reflect the exact backend runtime input exercised by the proof.
- [ ] Companion freeze manifest and approval packet still match the accepted re-freeze carrier.

## Root Index OIDs Under Test
- `foundation_documentation`: `<git ls-files --stage foundation_documentation>`
- `laravel-app`: `<git ls-files --stage laravel-app>`
- `web-app`: `<git ls-files --stage web-app>`
- `flutter-app`: `<git ls-files --stage flutter-app>`

## Nested HEADs And Clean Status
- `foundation_documentation`
  - `HEAD`: `<git -C foundation_documentation rev-parse HEAD>`
  - `status --short --untracked-files=all`: `<clean|non-clean with exact output>`
  - `gitlink equality`: `<matches root index|does not match>`
- `web-app`
  - `HEAD`: `<git -C web-app rev-parse HEAD>`
  - `status --short --untracked-files=all`: `<clean|non-clean with exact output>`
  - `gitlink equality`: `<matches root index|does not match>`
- `laravel-app`
  - `HEAD`: `<git -C laravel-app rev-parse HEAD>`
  - `status --short --untracked-files=all`: `<clean|non-clean with exact output>`
  - `runtime-input note`: `<state whether this is the exact clean backend runtime input exercised by the proof>`

## Carrier-Shape Note
- Included package shape: `<final-cutover-only|final-cutover + laravel-public-web-refresh|final-cutover + flutter-runtime-refresh|final-cutover + laravel-public-web-refresh + flutter-runtime-refresh>`
- Included changed surfaces:
  - `<list exact in-scope files or reference the clean-carrier manifest subset used>`
- Excluded drift confirmation:
  - `flutter-app`: `<included in this proof | absent from attested carrier under explicit carve-out decision>`

## Commands Exercised
- `<docker compose exec -T app php artisan test ...>`
- `bash .github/scripts/check_validation_owner_inputs.sh`
- `bash .github/scripts/verify_environment_ci.sh`
- `bash tools/tests/generic_base_detether_audit.sh`
- `bash tools/ci/run_contract.sh --profile stage-full`
- `bash tools/ci/run_contract.sh --profile main-proof`

## Results
- Laravel bounded proof suite: `<result>`
- `check_validation_owner_inputs.sh`: `<result>`
- `verify_environment_ci.sh`: `<result>`
- `generic_base_detether_audit.sh`: `<result>`
- `stage-full`: `<result>`
- `main-proof`: `<result>`

## Attestation Outcome
- The proof-time runtime inputs were `<clean|not clean>`.
- `foundation_documentation` and `web-app` `<did|did not>` match the exact root gitlink OIDs under test.
- `laravel-app` `<was|was not>` recorded as the clean backend runtime input exercised by the proof.
- Promotion-facing technical proof is `<ready|not ready>` for the attested carrier.

## Required Evidence Commands
```bash
git ls-files --stage foundation_documentation laravel-app web-app flutter-app
git -C foundation_documentation rev-parse HEAD
git -C foundation_documentation status --short --untracked-files=all
git -C web-app rev-parse HEAD
git -C web-app status --short --untracked-files=all
git -C laravel-app rev-parse HEAD
git -C laravel-app status --short --untracked-files=all
```
