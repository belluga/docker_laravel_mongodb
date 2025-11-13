# Documentation: P0 Core MongoDB Collections
**Version:** 1.0

## 1. Overview

This reference codifies the canonical MongoDB collections required to deliver Phase P0 (Boilerplate Genesis). The schemas complement the `foundation_control_plane` module specification and establish explicit validation rules, indexes, and retention expectations. Each collection definition includes the JSON Schema fragment enforced at the Laravel application layer and the operational constraints that sustain long-term data integrity.

## 2. Collection Catalogue

| Collection | Database Scope | Purpose | Primary Source of Truth |
|------------|----------------|---------|-------------------------|
| `tenants` | Landlord database | Stores tenant configuration, capability toggles, and anonymous access policies. | Foundation Control Plane |
| `accounts` | Tenant database | Segments tenant context into workspace/group constructs with default abilities. | Foundation Control Plane |
| `account_users` | Tenant database | Persists identity actors, anonymous fingerprints, and promotion audit history. | Foundation Control Plane |
| `interaction_records` | Tenant database | Provides immutable ledger of anonymous and verified activity for audit and telemetry. | Foundation Control Plane |
| `merged_account_snapshots` | Tenant database | Archives anonymous identity artifacts after consolidation into a verified account. | Foundation Control Plane |
| `identity_merge_audits` | Tenant database | Captures consolidated identity outcomes with aggregated timelines and operator provenance. | Foundation Control Plane |

## 3. Schema Definitions

### 3.1 `tenants`

**Validation Schema (excerpt)**

```json
{
  "bsonType": "object",
  "required": ["name", "slug", "database_name", "status", "capabilities", "anonymous_access_policy", "created_by", "created_at", "updated_at"],
  "properties": {
    "name": { "bsonType": "string", "minLength": 3, "maxLength": 120 },
    "slug": { "bsonType": "string", "pattern": "^[a-z0-9-]{3,32}$" },
    "database_name": { "bsonType": "string", "pattern": "^tenant_[a-z0-9]{3,32}$" },
    "status": { "enum": ["active", "suspended"] },
    "branding": {
      "bsonType": "object",
      "properties": {
        "primary_color": { "bsonType": "string", "pattern": "^#[0-9A-Fa-f]{6}$" },
        "secondary_color": { "bsonType": "string", "pattern": "^#[0-9A-Fa-f]{6}$" },
        "logo_url": { "bsonType": "string" }
      }
    },
    "capabilities": {
      "bsonType": "array",
      "minItems": 1,
      "items": {
        "bsonType": "object",
        "required": ["module_id", "enabled", "schema_version"],
        "properties": {
          "module_id": { "bsonType": "string" },
          "enabled": { "bsonType": "bool" },
          "schema_version": { "bsonType": "string", "pattern": "^v[0-9]+$" }
        }
      }
    },
    "anonymous_access_policy": {
      "bsonType": "object",
      "required": ["token_ttl_minutes", "abilities"],
      "properties": {
        "token_ttl_minutes": { "bsonType": "int", "minimum": 5, "maximum": 1440 },
        "abilities": {
          "bsonType": "array",
          "items": { "bsonType": "string" }
        },
        "rate_limits": {
          "bsonType": "object",
          "properties": {
            "requests_per_minute": { "bsonType": "int" },
            "burst": { "bsonType": "int" }
          }
        }
      }
    },
    "created_by": { "bsonType": "objectId" }
  }
}
```

**Indexes**
- `{ slug: 1 }` (unique) – ensures deterministic routing and database naming.
- `{ capabilities.module_id: 1 }` – accelerates module toggle resolution during identity issuance.

**Retention**
- Records persist indefinitely. Soft suspension is modeled via `status = suspended`; tenants are never physically deleted.

### 3.2 `accounts`

**Validation Schema (excerpt)**

```json
{
  "bsonType": "object",
  "required": ["tenant_id", "name", "slug", "default_abilities", "created_at", "updated_at"],
  "properties": {
    "tenant_id": { "bsonType": "objectId" },
    "name": { "bsonType": "string", "minLength": 3, "maxLength": 120 },
    "slug": { "bsonType": "string", "pattern": "^[a-z0-9-]{3,32}$" },
    "default_abilities": {
      "bsonType": "array",
      "items": { "bsonType": "string" }
    },
    "capabilities": {
      "bsonType": "array",
      "items": {
        "bsonType": "object",
        "required": ["module_id", "enabled"],
        "properties": {
          "module_id": { "bsonType": "string" },
          "enabled": { "bsonType": "bool" }
        }
      }
    },
    "settings": { "bsonType": "object" }
  }
}
```

**Indexes**
- `{ tenant_id: 1, slug: 1 }` (unique) – prevents duplicate slugs within a tenant.
- `{ tenant_id: 1, default_abilities: 1 }` – supports ability inheritance queries.

**Retention**
- Accounts persist while tenants remain active. Suspensions apply via `settings.status`.

### 3.3 `account_users`

**Validation Schema (excerpt)**

```json
{
  "bsonType": "object",
  "required": ["tenant_id", "identity_state", "first_seen_at", "fingerprints", "consents", "created_at", "updated_at"],
  "properties": {
    "tenant_id": { "bsonType": "objectId" },
    "display_name": { "bsonType": "string" },
    "emails": {
      "bsonType": "array",
      "items": { "bsonType": "string", "pattern": "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$" }
    },
    "phones": {
      "bsonType": "array",
      "items": { "bsonType": "string" }
    },
    "identity_state": { "enum": ["anonymous", "registered", "validated"] },
    "first_seen_at": { "bsonType": "date" },
    "registered_at": { "bsonType": ["date", "null"] },
    "fingerprints": {
      "bsonType": "array",
      "items": {
        "bsonType": "object",
        "required": ["hash", "first_seen_at"],
        "properties": {
          "hash": { "bsonType": "string", "pattern": "^[a-f0-9]{64}$" },
          "first_seen_at": { "bsonType": "date" },
          "last_seen_at": { "bsonType": "date" },
          "user_agent": { "bsonType": "string" },
          "locale": { "bsonType": "string" },
          "metadata": { "bsonType": "object" }
        }
      }
    },
    "consents": {
      "bsonType": "object",
      "properties": {
        "terms_version": { "bsonType": "string" },
        "marketing_opt_in": { "bsonType": "bool" },
        "updated_at": { "bsonType": "date" }
      }
    },
    "credentials": {
      "bsonType": "array",
      "items": {
        "bsonType": "object",
        "required": ["provider", "subject", "linked_at"],
        "properties": {
          "provider": { "bsonType": "string" },
          "subject": { "bsonType": "string" },
          "secret_hash": { "bsonType": "string" },
          "linked_at": { "bsonType": "date" },
          "last_used_at": { "bsonType": "date" }
        }
      }
    },
    "promotion_audit": {
      "bsonType": "array",
      "items": {
        "bsonType": "object",
        "required": ["from_state", "to_state", "promoted_at"],
        "properties": {
        "from_state": { "enum": ["anonymous", "registered", "validated"] },
        "to_state": { "enum": ["anonymous", "registered", "validated"] },
          "promoted_at": { "bsonType": "date" },
          "operator_id": { "bsonType": "objectId" }
        }
      }
    }
  }
}
```

**Indexes**
- `{ tenant_id: 1, "emails": 1 }` (partial unique, `emails` exists).
- `{ tenant_id: 1, "phones": 1 }` (partial unique, `phones` exists).
- `{ tenant_id: 1, identity_state: 1 }` – accelerates lifecycle reporting across anonymous, registered, and validated states.
- `{ tenant_id: 1, "credentials.provider": 1, "credentials.subject": 1 }` (unique) – allows multiple credentials per provider on one identity while keeping each external subject exclusive to a single identity.

**Retention**
- Identities persist indefinitely. Deactivation is modeled by removing ability assignments while retaining promotion audit history. Anonymous entries promoted into registered/validated identities are removed from this collection after their full document snapshot is captured in `merged_account_snapshots`.
Promotion audit entries embedded within `account_users` capture only lifecycle transitions (`anonymous` -> `registered` -> `validated`); merge attestations reside in the dedicated `identity_merge_audits` ledger.
`first_seen_at` is immutable once recorded, representing the earliest footprint across anonymous and registered states. `registered_at` marks the first transition into `identity_state = registered` and is populated from the corresponding promotion audit entry; it remains `null` for anonymous identities.

### 3.4 `merged_account_snapshots`

**Validation Schema (excerpt)**

```json
{
  "bsonType": "object",
  "required": ["tenant_id", "source_user_id", "merged_into", "identity_state", "snapshot", "merged_at"],
  "properties": {
    "tenant_id": { "bsonType": "objectId" },
    "source_user_id": { "bsonType": "objectId" },
    "merged_into": { "bsonType": "objectId" },
    "identity_state": { "enum": ["anonymous", "registered", "validated"] },
    "snapshot": { "bsonType": "object" },
    "merged_at": { "bsonType": "date" },
    "operator_id": { "bsonType": "objectId" },
    "reason": { "bsonType": "string" }
  }
}
```

`snapshot` stores the complete `account_users` document (fingerprints, consents, credentials, metadata) exactly as it existed before consolidation. `reason` defaults to `"merged"` but can support additional archival scenarios.

**Indexes**
- `{ tenant_id: 1, source_user_id: 1 }` (unique) – prevents duplicate snapshots for the same anonymous identity.
- `{ tenant_id: 1, merged_into: 1, merged_at: -1 }` – optimizes forensic investigation by canonical user and time window.

**Retention**
- Append-only. Retained per governance policy (default: indefinite) to support audits and incident response. Any purge must be coordinated with compliance stakeholders.

### 3.5 `identity_merge_audits`

**Validation Schema (excerpt)**

```json
{
  "bsonType": "object",
  "required": ["tenant_id", "canonical_user_id", "merged_source_ids", "consolidated_at", "timeline", "sources", "target_identity_state"],
  "properties": {
    "tenant_id": { "bsonType": "objectId" },
    "canonical_user_id": { "bsonType": "objectId" },
    "merged_source_ids": {
      "bsonType": "array",
      "minItems": 1,
      "items": { "bsonType": "objectId" }
    },
    "consolidated_at": { "bsonType": "date" },
    "operator": {
      "bsonType": "object",
      "properties": {
        "id": { "bsonType": "objectId" },
        "reason": { "bsonType": "string" }
      }
    },
    "timeline": {
      "bsonType": "object",
      "properties": {
        "first_seen_at": { "bsonType": "date" },
        "last_seen_at": { "bsonType": "date" }
      }
    },
    "sources": {
      "bsonType": "array",
      "minItems": 1,
      "items": {
        "bsonType": "object",
        "required": ["source_user_id", "merged_at"],
        "properties": {
          "source_user_id": { "bsonType": "objectId" },
          "snapshot_id": { "bsonType": "objectId" },
          "merged_at": { "bsonType": "date" },
          "first_seen_at": { "bsonType": "date" },
          "last_seen_at": { "bsonType": "date" },
          "promotion_audit": {
            "bsonType": "array",
            "items": { "bsonType": "object" }
          }
        }
      }
    },
    "target_promotion_audit_before_merge": {
      "bsonType": "array",
      "items": { "bsonType": "object" }
    },
    "target_identity_state": { "enum": ["anonymous", "registered", "validated"] }
  }
}
```

`timeline.first_seen_at` records the earliest encounter timestamp observed across the canonical identity and all merged sources, while `timeline.last_seen_at` captures the most recent engagement prior to consolidation. `sources[].promotion_audit` preserves the historical lifecycle entries attached to each source identity before its removal from the live `account_users` collection.

**Indexes**
- `{ tenant_id: 1, canonical_user_id: 1, consolidated_at: -1 }` - enables rapid retrieval of consolidation events for a canonical identity.
- `{ tenant_id: 1, merged_source_ids: 1 }` - supports reverse lookups when investigating a retired source identity.
- `{ tenant_id: 1, "sources.source_user_id": 1 }` - aligns forensic queries that follow the lineage of a specific anonymous identity.

**Retention**
- Append-only ledger retained indefinitely. Each entry references the archival `merged_account_snapshots` document (via `sources[].snapshot_id`) to guarantee forensic completeness without reintroducing deleted anonymous records to the active identity surface.

### 3.6 `interaction_records`

**Validation Schema (excerpt)**

```json
{
  "bsonType": "object",
  "required": ["tenant_id", "account_id", "actor_state", "interaction_type", "capability_origin", "payload", "request_context", "trace_id", "recorded_at"],
  "properties": {
    "tenant_id": { "bsonType": "objectId" },
    "account_id": { "bsonType": "objectId" },
    "actor_id": { "bsonType": "objectId" },
    "actor_state": { "enum": ["anonymous", "registered", "validated"] },
    "interaction_type": { "bsonType": "string" },
    "capability_origin": { "bsonType": "string" },
    "payload": { "bsonType": "object" },
    "request_context": {
      "bsonType": "object",
      "properties": {
        "ip": { "bsonType": "string" },
        "user_agent": { "bsonType": "string" },
        "locale": { "bsonType": "string" }
      }
    },
    "trace_id": { "bsonType": "string" },
    "recorded_at": { "bsonType": "date" }
  }
}
```

**Indexes**
- `{ tenant_id: 1, recorded_at: -1 }` – supports chronological analysis.
- `{ tenant_id: 1, interaction_type: 1, recorded_at: -1 }` – accelerates per-capability reporting.
- `{ tenant_id: 1, actor_id: 1, recorded_at: -1 }` (sparse) – enables identity activity audits.

**Retention**
- Immutable ledger retained indefinitely. Future archival policies will export snapshots to object storage; no TTL indexes are defined in P0.

## 4. Operational Safeguards

1. **Schema Registry:** Application migrations publish JSON Schema documents to a registry directory consumed by automated validation tests. Any schema evolution increments the `schema_version` within the capability catalogue.
2. **Index Drift Monitoring:** CI enforces parity between Laravel migration definitions and actual cluster indexes using `php artisan schema:assert`. Drift alerts escalate to the platform operations team.
3. **Data Residency:** All collections are tenant-scoped except `tenants`. Cross-tenant access is prohibited at the application layer; queries must include `tenant_id` filters verified by automated tests.
4. **Audit Immutability:** `interaction_records` and `promotion_audit` arrays remain append-only. Compensating transactions create new documents rather than mutating past records.

## 5. References

- `foundation_documentation/modules/foundation_control_plane.md`
- `foundation_documentation/system_roadmap_sections/phase_narratives/p0-boilerplate-genesis.md`

### 3.7 `landlord_users`

**Validation Schema (excerpt)**

`json
{
  "bsonType": "object",
  "required": ["name", "emails", "identity_state", "credentials", "created_at", "updated_at"],
  "properties": {
    "name": { "bsonType": "string", "minLength": 3, "maxLength": 120 },
    "emails": {
      "bsonType": "array",
      "items": { "bsonType": "string", "pattern": "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$" },
      "minItems": 1,
      "uniqueItems": true
    },
    "phones": {
      "bsonType": "array",
      "items": { "bsonType": "string" }
    },
    "identity_state": { "enum": ["registered", "validated"] },
    "credentials": {
      "bsonType": "array",
      "items": {
        "bsonType": "object",
        "required": ["provider", "subject", "linked_at"],
        "properties": {
          "provider": { "bsonType": "string" },
          "subject": { "bsonType": "string" },
          "secret_hash": { "bsonType": "string" },
          "metadata": { "bsonType": "object" },
          "linked_at": { "bsonType": "date" },
          "last_used_at": { "bsonType": "date" },
          "verified_at": { "bsonType": "date" }
        }
      }
    },
    "promotion_audit": {
      "bsonType": "array",
      "items": {
        "bsonType": "object",
        "required": ["from_state", "to_state", "promoted_at"],
        "properties": {
          "from_state": { "enum": ["registered", "validated"] },
          "to_state": { "enum": ["registered", "validated"] },
          "promoted_at": { "bsonType": "date" },
          "operator_id": { "bsonType": "objectId" }
        }
      }
    }
  }
}
`

**Indexes**
- { emails: 1 } (partial unique, mails exists).
- { identity_state: 1 } – supports reporting across registered and validated operators.
- { "credentials.provider": 1, "credentials.subject": 1 } (unique) – prevents a credential subject from linking to multiple landlord identities.

**Retention**
- Landlord identities persist indefinitely; promotion audits record every transition from registered to validated. Anonymous issuance is not supported for landlord operators.

