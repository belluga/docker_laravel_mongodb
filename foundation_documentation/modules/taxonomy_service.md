# Documentation: The Taxonomy Service

**Version:** 1.1
**Date:** October 16, 2025
**Authors:** Belluga Learning & Engineering

## 1. Overview

The **Taxonomy Service** is a foundational, platform-wide module responsible for creating and managing a structured vocabulary for classifying all content and entities. It provides a flexible, two-level system of **Groups** and **Terms**.

By centralizing the "language" of classification, it ensures consistency and provides a stable, public contract (`term_key`) for other services to consume, enabling true, loosely coupled integration.

## 2. Design Principles

### 2.1. A Single Source of Truth for Classification
This service is the canonical source for all descriptive labels in the system. Any module that needs to classify an object must reference the terms defined here.

### 2.2. The Public Contract via `term_key`
To ensure true microservice decoupling, each term has a unique, immutable, and human-readable `term_key` (e.g., "skill:python"). This key is the public identifier used in all cross-service communication, such as event payloads. External services must not know or depend on the internal `_id` of a term.

## 3. Detailed Collection Schemas

### 3.1. `taxonomy_groups`
* **Purpose:** Defines the "categories" of tags, providing semantic context.
* **Scope:** Tenant-level data.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "name": "String", // "Skill", "Difficulty", "Subject Area"
      "description": "String",
      "created_at": "Date"
    }
    ```

### 3.2. `taxonomy_terms`
* **Purpose:** The master catalog of all individual tags, each belonging to a group and exposing a public key.
* **Scope:** Tenant-level data.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "group_id": "ObjectId()",
      "term_key": "String", // e.g., "subject:calculus". Unique per Tenant. Immutable.
      "name": "String", // "Calculus"
      "parent_term_id": "ObjectId()",
      "created_at": "Date"
    }
    ```