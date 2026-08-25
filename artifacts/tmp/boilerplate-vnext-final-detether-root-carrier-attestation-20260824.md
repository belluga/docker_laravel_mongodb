# Final Detether Root Carrier Attestation

- Governing TODO: `foundation_documentation/todos/completed/TODO-boilerplate-vnext-final-detether-cutover-and-promotion.md`
- Root branch: `reconcile/boilerplate-vnext-final-cutover-20260708`
- Root commit under attestation: `e92c56e65f7317254ea12103627f1e53247b1d9a`
- Captured: `2026-08-24`

## Exact Root Gitlinks And Proof-Time Local Heads
| Path | Root gitlink OID | Proof-time local HEAD | Equality | Classification |
| --- | --- | --- | --- | --- |
| `foundation_documentation` | `d54818956b4fb54accfce20a25f6370bf555bd7d` | `8b9ece582841f91eadf1d2b39a765754cff0f181` | `no` | reference freshness only; not runtime/source promotion proof |
| `flutter-app` | `c9fbacfb3cf5c46ea5086ac7118d22b10338fbf8` | `908dba3b74274ca601758bd11de202c0f10d8395` | `no` | clean source-promotion candidate recorded for Docker follow-through |
| `laravel-app` | `a0124b0dbdd8e1254ebe4b2986f1640f49f3d48c` | `aba9fd3c3108472634e78396ea060f024a2e53e8` | `no` | backend runtime source input exercised by proof-time Docker builds |
| `web-app` | `af309c13e9b560e12e1f2b471bda47e78c8ba86a` | `af309c13e9b560e12e1f2b471bda47e78c8ba86a` | `yes` | derived static web input under root gitlink |

## Post-Proof Documentation Closeout
- `foundation_documentation` closeout commit: `3a2e60d68bd4e21af7ac9dae362c267319aa6cc5`.
- Classification: docs/reference-only publication after the proof-time broad gates.
- Invalidation decision: no product-code, runtime, build/publish, compose, CI-contract, or source-promotion surface changed; current `stage-full` and `main-proof` reports remain valid for root commit `e92c56e65f7317254ea12103627f1e53247b1d9a`.
- Root gitlink policy: no manual repin; root gitlinks remain pipeline-owned.

## Tracked-Status Attestation
- Root tracked status: clean before artifact publication; untracked `.delphi-locks/laravel-tests-safe.lock` and the two new report JSON files were local execution artifacts.
- `foundation_documentation` tracked status: clean at `8b9ece5`; pre-existing untracked `artifacts/tmp/**` and `todos/ephemeral/**` remain outside this runtime proof.
- `laravel-app` full status: clean at `aba9fd3`.
- `flutter-app` full status: clean at `908dba3`.
- `web-app` full status: clean at `af309c1`.

## Runtime Boundary
- `docker compose config --quiet`: passed.
- Direct compose services: app and mongo healthy; worker, scheduler, nginx, and cloudflared running.
- `docker-compose.validation-belluga.yml`: absent.
- `project/belluga-validation/**`: zero files.
- `stage-full`: passed; report `artifacts/tmp/boilerplate-vnext-final-detether-stage-full-20260824.json`, SHA-256 `18c62bbdaecd003eeb0f995b696ade4d88460367f91c5d3420ed1d12ea48c0e0`.
- `main-proof`: passed; report `artifacts/tmp/boilerplate-vnext-final-detether-main-proof-20260824.json`, SHA-256 `09d4db39eb605c189ef19b1f7aaa827b46a5e7cbd80c4548d0aa7188b2e69ebb`.

This artifact proves the current root carrier, local runtime inputs, and broad root contracts. It does not claim that `dev -> stage` or `stage -> main` promotion has run.
