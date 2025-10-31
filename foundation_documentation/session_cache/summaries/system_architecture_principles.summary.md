# Summary: system_architecture_principles.md
**Generated:** 2025-10-19T14:06:00-04:00
**Source Hash:** 4F430A7DCE5657D7A6C2C06EC4639D68A92CEAE18197EC356C7DD3EAF129F478

## Core Philosophy
- Architecture is domain-led (P-1), document-oriented on MongoDB (P-2), and API-first via Laravel services (P-3).
- Documents must reflect the ideal foundational state (P-4), not MVP shortcuts.

## Data Principles
- Unified Data Modeling: embed 1:few relationships, reference 1:many, design for cross-service aggregations (P-5).
- Maintain single sources of truth with deliberate caching (P-6).
- Historical records (transactions, payments) are immutable; corrections use compensating actions (P-7).
- Laravel enforces explicit schemas with named enums and validation before implementation (P-8).
- IDs: primary `_id` (ObjectId); references named `<entity>_id` (P-9).

## API & Service Design
- Business logic lives in domain services; controllers perform orchestration only (P-10).
- Authentication is stateless, token-based (P-11).
- RESTful resource naming with versioned prefixes and HTTP verbs (P-12).
- API enforces comprehensive validation; client-side checks are UX only (P-13).

## Security Principles
- Enforce least privilege via RBAC (P-14).
- Separate user and partner identities, even if the same person holds both (P-15).
- Treat PII as sensitive: encrypt at rest, limit exposure by default, audit all access (P-16).
