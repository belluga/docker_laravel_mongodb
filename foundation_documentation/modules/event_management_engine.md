# Engine Documentation: Event Management

**Version:** 1.0
**Date:** October 26, 2025
**Authors:** Belluga Learning & Engineering, Gemini Agent

## 1. Overview

This document describes the architecture for the **Event Management Engine**. This engine is responsible for the definition and management of events, the venues (`Places`) where they occur, and the foundational relationship with the ticketing system. It is designed to be a core module within the Belluga Platform Boilerplate, providing a generic and scalable framework for all product initiatives.

---

## 2. Core Entities & Schemas

### 2.1. `places`

The `places` collection is the master repository for all venues, which can be physical or virtual. It supports a powerful inheritance model allowing for global templates and account-specific customizations.

```json
{
    "_id": "ObjectId()",
    "name": "String",
    "version": "Number",
    "is_virtual": "Boolean",
    "location": {
        "address": "String",
        "city": "String",
        "state": "String",
        "postal_code": "String",
        "country": "String",
        "url": "String"
    },
    "owner_account_id": "ObjectId()",
    "lineage": {
        "parent_place_id": "ObjectId()",
        "synced_parent_version": "Number"
    },
    "layout": {
        "capacity": "Number",
        "sections": [
            {
                "name": "String",
                "capacity": "Number"
            }
        ]
    }
}
```

### 2.2. `events`

The `events` collection defines a specific event happening at one or more `Places`.

```json
{
    "_id": "ObjectId()",
    "name": "String",
    "account_id": "ObjectId()",
    "place_ids": ["ObjectId()"],
    "starts_at": "Date",
    "ends_at": "Date",
    "config": {
        "requires_qr_code": "Boolean"
    }
}
```

### 2.3. `ticket_types`

This collection manages the quotas for each category of ticket available for an event.

```json
{
    "_id": "ObjectId()",
    "event_id": "ObjectId()",
    "name": "String",
    "capacity": "Number",
    "sold_count": "Number",
    "seating_type": "String"
}
```

### 2.4. `tickets`

A `ticket` document is created only when a ticket is sold or held. It represents a unique, issued ticket.

```json
{
    "_id": "ObjectId()",
    "ticket_type_id": "ObjectId()",
    "status": "String",
    "owner_id": "ObjectId()",
    "beneficiary_info": {
        "name": "String",
        "reference_id": "String"
    },
    "attendee_info": {
        "name": "String"
    },
    "seat_info": {
        "row": "String",
        "seat_number": "String"
    },
    "held_until": "Date"
}
```

---

## 3. Key Processes & Operational Logic

### 3.1. Place Inheritance and Selective Updates

This process allows `Accounts` to use global `Place` templates and receive updates in a controlled manner.

*   **Trigger:** A background process or user action checks if a parent `Place`'s `version` is greater than a child `Place`'s `lineage.synced_parent_version`.
*   **Action:** If an update is detected, the UI will present a notification to the `Account` user.
*   **User Review:** The user can view a comparison of the changes between the parent version they last synced with and the parent's current version.
*   **Resolution:** The user can choose to apply some, all, or none of the changes to their private copy. After the review is complete, the child `Place`'s `lineage.synced_parent_version` is updated to match the parent's current `version`. This "marks the update as addressed" and prevents further notifications until the next parent update.

### 3.2. Event Creation & Ticket Type Generation

This process accelerates event setup by automating the creation of `ticket_types`.

*   **Trigger:** An `Account` user creates a new `Event` and selects one or more `Places`.
*   **Action:** The system reads the `layout.sections` from the selected `Place`(s). For each section, it generates a default `ticket_type` document in memory, pre-filling the `name` and `capacity`.
*   **User Review:** The UI presents this list of auto-generated `ticket_types`. The user can confirm, edit, delete, or manually add new `ticket_types`.
*   **Resolution:** The final, user-approved list of `ticket_types` is saved to the database when the `Event` is created.
