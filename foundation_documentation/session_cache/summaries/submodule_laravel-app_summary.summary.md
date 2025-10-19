# Summary: submodule_laravel-app_summary.md
**Generated:** 2025-10-19T14:09:30-04:00
**Source Hash:** 759EA7E5EA4ED5F845ACC9887EE23BE5392B9CF2C7362E5A10C9CF058EDFD4C9

## Version Snapshot
- Commit `80fff2416676f36d850fb6e1c430ec9e4ffeac1a`, analyzed 2025-10-18.
- Laravel 12 foundation with MongoDB driver, spatie multitenancy, Sanctum, DTO tooling, image manipulation, phone validation.

## Structure & Patterns
- Dual landlord vs tenant model namespaces with separate Mongo connections and migrations.
- API v1 under `app/Http/Api/v1` with versioned controllers/requests/resources; v2 scaffolding pending implementation.
- Tenant discovery via `DomainTenantFinder`; tenant switch task rebinds Mongo connections per request.
- Middleware orchestration in `bootstrap/app.php` isolates landlord, tenant, account pipelines.

## Configuration Touchpoints
- `.env` provides URIs and Sanctum settings.
- `config/database.php` and `config/multitenancy.php` wire Mongo connections, tenant finder, switch tasks.
- Route files partition landlord (`admin/api/v1`), tenant (`api/v1`), account (`api/v1/accounts/{account_slug}`), initialization entry point `/initialize`.

## Principle Alignment Highlights
- Strong alignment with P-1, P-2, P-3, P-4, P-11.
- P-10 partially aligned: service layer stubs exist but controllers still hold business logic.

## Observations
- Need to confirm storage backend for branding artifacts.
- Sanctum ability taxonomy should be centrally documented.
- Keep tenant finder host mappings synchronized with infrastructure.
- Service layer (`app/Services`) requires fleshing out to meet domain-service mandate.
