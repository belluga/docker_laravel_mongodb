# Documentation: The Ticketing Engine

**Version:** 1.0
**Date:** October 25, 2025
**Authors:** Belluga Learning & Engineering

## 1. Overview

This document describes the architecture of the **Ticketing Engine**. This module's sole responsibility is the real-time inventory management of tickets for events. It manages venues, seating maps, events, and the status of every individual seat (`available`, `held`, `sold`).

It is designed to be a complimentary module to the **Commercial Engine**, which handles all financial transactions related to ticket sales.

---

## 2. Design Principles

*   **Decoupled from Commerce:** The Ticketing Engine knows nothing about prices, contracts, or invoices. It only manages inventory. The sale of a ticket is handled by the Commercial Engine.
*   **Optimistic Locking with Holds:** To prevent double-booking during high-traffic sales, the engine uses a system of short-lived, temporary holds on seats. A seat is not marked as sold until the Commercial Engine confirms a successful payment.

---

## 3. Detailed Collection Schemas

### 3.1. Ticketing Engine Collections

The following collections reside in the database of each **Tenant**.

#### `venues`

* **Purpose**: A master list of all physical locations and venues where events can be held.
* **Structure**:
    ```json
    {
        "_id": "ObjectId()",
        "account_id": "ObjectId()",
        "name": "String",
        "address": {
            "street": "String",
            "city": "String",
            "state": "String",
            "postal_code": "String",
            "country": "String"
        },
        "seating_maps": [
            {
                "name": "String",
                "layout": [
                    {
                        "row": "String",
                        "seats": [
                            {
                                "number": "String",
                                "type": "String"
                            }
                        ]
                    }
                ]
            }
        ]
    }
    ```

#### `events`

* **Purpose**: Represents a specific event happening at a specific venue.
* **Structure**:
    ```json
    {
        "_id": "ObjectId()",
        "account_id": "ObjectId()",
        "name": "String",
        "description": "String",
        "venue_id": "ObjectId()",
        "starts_at": "Date",
        "ends_at": "Date"
    }
    ```

#### `ticket_inventory`
* **Purpose**: Tracks the status of every seat for every event to manage real-time inventory.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "event_id": "ObjectId()",
      "row": "String",
      "seat_number": "String",
      "status": "String",
      "contract_id": "ObjectId()",
      "held_by": "String",
      "held_until": "Date"
    }
    ```
