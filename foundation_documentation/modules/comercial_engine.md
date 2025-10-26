# Documentation: The Commercial Engine

**Version:** 1.0
**Date:** October 16, 2025
**Last Review Date:** October 25, 2025
**Authors:** Belluga Learning & Engineering

## 1. Overview

This document describes the architecture of two distinct but commercially related domains: the **Financial Engine** and the **Attribution Engine**. While documented together for efficiency, they operate as **separate, decoupled conceptual modules** that together manage the platform's entire commercial lifecycle.

* **The Financial Engine:** Manages the "what" and "how" of a sale. Its scope includes a flexible product catalog, advanced pricing models, contract management, invoicing, payment processing, and a full suite of financial instruments like coupons, refunds, and service credits.
* **The Attribution Engine:** Manages the "who" or "why" behind a sale. It tracks the sources of new business, such as affiliates, salespeople, and marketing campaigns, answering the question: "Who gets credit for this sale?"

The two engines are cleanly decoupled. The integration point is an `attribution` object stored as an immutable **snapshot** within the Financial Engine's `contracts` collection. This ensures that the Financial Engine has no direct dependency on the Attribution Engine's data, upholding our core architectural principles.

---

## 2. Design Principles

### Design Principles (Financial)

* **Flexible Product Catalog Model:** The engine uses a two-level catalog (`catalog_items` and `products`) to cleanly separate the definition of an item from how it is packaged and sold.
* **Prototype Configuration for Prices:** To ensure safety and efficiency, all `prices` are created using the **Prototype Configuration Pattern**. A library of reusable `price_templates` allows for the rapid creation of new commercial terms. Each template is specific to a currency and, once used, is snapshotted into a `price` document, making it a complete, self-contained record.
* **Immutable Versioning for Prices:** A `price` is considered an immutable commercial offer. To "edit" a price, the system deactivates the existing record and creates a new, versioned clone with the updated terms. This provides a perfect, auditable history of all commercial terms offered over time.
* **The Price as the Source of Truth:** A `product` can have multiple `prices`. The `prices` collection is the source of truth for all commercial terms, and a `contract` is an immutable snapshot of a specific `price` at the time of sale.
* **Event-Driven Architecture:** The engine operates independently, emitting events for significant financial state changes (e.g., `PaymentSucceeded`, `ContractStatusChanged`) to ensure eventual consistency across the platform without creating hard dependencies.

### Design Principles (Attribution)

* **Unified Source Model for Flexibility:** The engine uses a single, unified `attribution_sources` collection with a `type` discriminator to consistently manage diverse entities like affiliates, salespeople, and campaigns.
* **Decoupled Integration via Snapshotting:** To maintain strict decoupling, the `contracts` collection stores a snapshot of key attribution details at the time of sale. This ensures historical financial records remain accurate even if the original attribution source's details change later.
* **Immutable Touchpoint Logging:** The `touchpoints` collection provides a complete, immutable audit trail of every significant customer interaction, which is crucial for analytics and resolving commission disputes.

---

## 3. Cross-Cutting Concerns

This section addresses system-wide concerns that apply across the Financial and Attribution Engines.

### 3.1. Transaction Management

To ensure data integrity and atomicity, all operations that modify multiple collections must be executed within a database transaction. This is critical for complex financial workflows where a single logical action, like a sale, may involve creating or updating multiple documents (e.g., `contracts`, `invoices`, `payments`).

**Strategy:**

*   **Atomic Operations:** Any process that involves multiple writes to the database (e.g., creating a contract and its first invoice) must be wrapped in a transaction. If any step in the process fails, the entire transaction will be rolled back, preventing partial data updates and ensuring the system remains in a consistent state.
*   **Service Layer Responsibility:** The responsibility for managing transactions should reside in the service layer of theapplication. The service method orchestrating the operation (e.g., `createContract`) should begin the transaction and commit it only after all database writes have succeeded.

### 3.2. Security

Security is a paramount concern for the Commercial Engine. The following principles must be adhered to:

*   **Payment Gateway & PCI Compliance:** The system will not store raw credit card numbers or other sensitive payment credentials. All payment processing will be handled by a certified, PCI-compliant third-party payment gateway. The application will only store tokens or other non-sensitive references to payment methods.
*   **Authentication & Authorization:** All API endpoints must be protected by a robust authentication mechanism (e.g., OAuth 2.0). Access to data and operations will be governed by a Role-Based Access Control (RBAC) system. Roles and permissions must be clearly defined to enforce the principle of least privilege.
*   **Data Encryption:** All sensitive data, including personal information and financial records, must be encrypted both in transit (using TLS) and at rest (using database-level encryption).

### 3.3. Scalability

The system is designed with scalability in mind to handle growth in data volume and user traffic.

*   **Database Scaling:** The database architecture should support both vertical and horizontal scaling. For read-heavy workloads, read replicas can be added to distribute the load. For write-heavy workloads, a sharding strategy can be implemented to partition the data across multiple database instances.
*   **Caching:** A distributed caching layer (e.g., Redis) should be used to cache frequently accessed, non-volatile data, such as product catalog information and price templates. This will reduce database load and improve API response times.

### 3.4. Error Handling & Idempotency

To ensure a predictable and reliable API, the system will implement standardized error handling and support for idempotent requests.

*   **Standardized Error Responses:** The API will use a consistent format for error responses, including a unique error code, a human-readable message, and details about the specific fields in error. This allows API consumers to handle errors programmatically.
*   **Idempotency:** To prevent accidental duplicate operations (e.g., charging a customer twice), all `POST` requests that create resources will support an `Idempotency-Key` header. The server will store the result of the first request made with a given idempotency key and return that same result for any subsequent requests made with the same key.

### 3.5. Localization

The system provides a flexible, hierarchical model for handling multiple currencies and languages.

*   **Multi-Currency Strategy:** The system supports both fixed pricing for specific currencies and automatic real-time currency conversions. The behavior is determined by the following hierarchy:
    1.  **Price-Level Override:** The `conversion_behavior` field on a `price` document provides the most granular control. If set, it dictates the behavior for that specific price.
    2.  **Account-Level Default:** If `prices.conversion_behavior` is not set, the system uses the `default_conversion_behavior` from the `account_settings` collection. This provides a global default for the entire account.

*   **Conversion Behaviors:**
    *   `"fixed"`: The price is only valid for the specified `currency`. Any conversion is handled by the customer's card issuer.
    *   `"automatic"`: The system is authorized to convert the price from its base `currency` to the customer's local currency using a real-time exchange rate service.

*   **Internationalization (i18n):** All user-facing strings, such as product descriptions and error messages, should be managed through a translation library to support multiple languages.

### 3.6. Taxes

The system provides a flexible framework for handling taxes.

*   **Tax Rates:** The `tax_rates` collection serves as a central repository for all tax rates. This allows for the flexible management of different tax types (e.g., VAT, Sales Tax) and jurisdictions.
*   **Tax Calculation:** The tax calculation logic is not embedded in the database but resides in the application layer. When an invoice is generated, the application will determine the applicable taxes based on the product, the customer's location, and the rules defined in the `tax_rates` collection.
*   **Tax on Invoices:** The `invoices` collection stores the calculated tax information in two places:
    *   **`line_items.taxes`**: An array on each line item that details the specific taxes applied to that item.
    *   **`tax_summary`**: An array at the invoice level that provides a consolidated summary of all taxes on the invoice.
This approach provides a clear and auditable record of all taxes applied to each transaction.

### 3.7. Data Lifecycle and Integrity

This section outlines the system-wide policies for managing data over its lifecycle and ensuring consistency.

*   **Archiving over Deletion (Soft Deletion):** To maintain a complete and auditable history, records in the system are generally not hard-deleted. Instead, they are marked with a status flag like `is_archived: true` or `active: false`. This ensures that historical data, especially for financial records, is preserved.

*   **Tenant Data Retention:** A tenant (i.e., a seller) cannot unilaterally hard-delete their account's financial and transactional history. When a tenant account is closed, their data is archived and retained for a legally mandated period to protect the interests of their customers and to comply with financial regulations.

*   **Application-Level Integrity:** As the database does not enforce referential integrity, the application layer is responsible for validating all `ObjectId` references between collections. Before creating or updating a record, the application must ensure that any referenced documents (e.g., a `user_id` on a `contract`) exist and are valid.

### 3.8. Monetary Calculations

To ensure financial accuracy, all fields representing monetary values use the `Decimal128` data type. All arithmetic operations on these values must be performed using a high-precision math library that supports this data type. Standard floating-point arithmetic must not be used, as it can introduce rounding errors.

---

## 4. Detailed Collection Schemas

### 4.1. Financial Engine Collections

The following collections reside in the database of each **Tenant**.

#### `account_settings`

* **Purpose**: Stores account-wide settings and configurations.
* **Structure**:
    ```json
    {
        "_id": "ObjectId()",
        "account_id": "ObjectId()",
        "currency_settings": {
            "default_conversion_behavior": "String"
        }
    }
    ```
* **Field Definitions:**
    * `currency_settings.default_conversion_behavior`: `"fixed"`, `"automatic"`.

#### `catalog_items`

* **Purpose**: The master list of every individual, atomic item the school can sell.
* **Structure**:
    ```json
    {
        "_id": "ObjectId()",
        "account_id": "ObjectId()",
        "name": "String",
        "type": "String",
        "tax_category": "String",
        "active": "Boolean",
        "thumbnail_url": "String",
        "media_gallery": [
            {
                "url": "String",
                "type": "String",
                "description": "String"
            }
        ],
        "details": {}
    }
    ```

* **Details Schema for `type: "physical_good"`**:
    ```json
    {
        "requires_shipping": "Boolean",
        "weight": {
            "value": "Decimal128",
            "unit": "String"
        },
        "dimensions": {
            "length": "Decimal128",
            "width": "Decimal128",
            "height": "Decimal128",
            "unit": "String"
        }
    }
    ```

* **Details Schema for `type: "course_bundle"`**:
    ```json
    {
        "course_ids": ["ObjectId()"]
    }
    ```

* **Details Schema for `type: "service"`**:

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

#### `products`

* **Purpose**: A sellable package or bundle composed of items from the master catalog.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "name": "String",
      "description": "String",
      "active": "Boolean",
      "thumbnail_url": "String",
      "media_gallery": [
        {
            "url": "String",
            "type": "String",
            "description": "String"
        }
      ],
      "items": [
        {
            "item_id": "ObjectId()",
            "quantity": "Number"
        }
      ]
    }
    ```

#### `price_templates`

* **Purpose**: A library of reusable, prototypical commercial terms that can be used to create new `prices`.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "name": "String",
      "is_archived": "Boolean",
      "currency": "String",
      "template_data": {
        "description": "String",
        "billing_model": "String",
        "billing_timing": "String",
        "billing_cycle": { "interval": "String", "interval_count": "Number" },
        "trial": { "type": "String", "duration_days": "Number" },
        "cancelation_policy": {
            "fee_type": "String",
            "grace_period": { "duration_days": "Number" }
        },
        "enrollment_fee": { "amount": "Decimal128", "name": "String" },
        "pricing_phases": [
          { "duration_in_cycles": "Number", "amount_per_cycle": "Decimal128" }
        ],
        "metered_components": [
          { "item_name": "String", "unit_name": "String", "price_per_unit": "Decimal128" }
        ]
      }
    }
    ```

#### `prices`

* **Purpose**: Defines the specific commercial terms for selling a `product`. Each document is a self-contained, immutable record created from a `price_template`.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "product_id": "ObjectId()",
      "source_template_id": "ObjectId()",
      "version": "Number",
      "previous_version_id": "ObjectId()",
      "active": "Boolean",
      "is_default": "Boolean",
      "currency": "String",
      "conversion_behavior": "String | null",
      "description": "String",
      "billing_model": "String",
      "billing_timing": "String",
      "billing_cycle": { "interval": "String", "interval_count": "Number" },
      "trial": { "type": "String", "duration_days": "Number" },
      "cancelation_policy": {
            "fee_type": "String",
            "grace_period": { "duration_days": "Number" }
      },
      "enrollment_fee": { "amount": "Decimal128", "name": "String" },
      "pricing_phases": [
        { "duration_in_cycles": "Number", "amount_per_cycle": "Decimal128" }
      ],
      "metered_components": [
        { "item_name": "String", "unit_name": "String", "price_per_unit": "Decimal128" }
      ]
    }
    ```

#### `contracts`

* **Purpose**: An immutable snapshot of a `price` at the time of sale, linking a user to a commercial agreement.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "user_id": "ObjectId()",
      "price_snapshot": {
        "price_id": "ObjectId()",
        "product_id": "ObjectId()",
        "source_template_id": "ObjectId()",
        "version": "Number",
        "currency": "String",
        "conversion_behavior": "String | null",
        "description": "String",
        "billing_model": "String",
        "billing_timing": "String",
        "billing_cycle": { "interval": "String", "interval_count": "Number" },
        "trial": { "type": "String", "duration_days": "Number" },
        "cancelation_policy": {
              "fee_type": "String",
              "grace_period": { "duration_days": "Number" }
        },
        "enrollment_fee": { "amount": "Decimal128", "name": "String" },
        "pricing_phases": [
          { "duration_in_cycles": "Number", "amount_per_cycle": "Decimal128" }
        ],
        "metered_components": [
          { "item_name": "String", "unit_name": "String", "price_per_unit": "Decimal128" }
        ]
      },
      "conversion_details": {
        "from_currency": "String",
        "to_currency": "String",
        "exchange_rate": "Decimal128",
        "original_amount": "Decimal128",
        "converted_at": "Date"
      },
      "revision_number": "Number",
      "amendment_history":  [
        {
          "amendment_id": "ObjectId()",
          "changed_at": "Date",
          "changed_by_user_id": "ObjectId()",
          "reason": "String",
          "previous_values": "Map<String, Any>",
          "new_values": "Map<String, Any>"
        }
      ],
      "status": "String",
      "status_history": [ { "status": "String", "changed_at": "Date" } ],
      "financial_summary": {
        "currency": "String",
        "total_paid": "Decimal128",
        "outstanding_balance": "Decimal128"
      },
      "attribution": {
        "source_type": "String",
        "source_id": "ObjectId()",
        "snapshot_details": { "name": "String", "commission_rate_percentage": "Decimal128" }
      },
      "created_at": "Date",
      "updated_at": "Date"
    }
    ```

#### `invoices`

* **Purpose**: An individual, payable bill generated under a contract.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "contract_id": "ObjectId()",
      "user_id": "ObjectId()",
      "line_items": [ { "description": "String", "amount": "Decimal128", "type": "String", "bundle_components": [ { "catalog_item_id": "ObjectId()", "quantity": "Number" } ], "taxes": [ { "tax_rate_id": "ObjectId()", "amount": "Decimal128" } ] } ],
      "currency": "String",
      "total": "Decimal128",
      "tax_summary": [ { "tax_rate_id": "ObjectId()", "total_amount": "Decimal128" } ],
      "status": "String",
      "due_at": "Date",
      "dunning_status": { "status": "String", "next_attempt_at": "Date" },
      "dunning_history": [
        {
          "attempted_at": "Date",
          "status": "String",
          "payment_gateway_response": "Map<String, Any>"
        }
      ],
      "replaced_by_invoice_id": "ObjectId()",
      "created_at": "Date"
    }
    ```

#### `payments`

* **Purpose**: An immutable log of a payment attempt against an invoice.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "invoice_id": "ObjectId()",
      "currency": "String",
      "amount": "Decimal128",
      "status": "String",
      "payment_method": { "type": "String", "details": {} },
      "gateway_installments": { "count": "Number" },
      "processed_at": "Date"
    }
    ```

* **Details Schema for `payment_method.type: "credit_card"`**:
    ```json
    {
        "brand": "String",
        "last4": "String",
        "expiration_month": "String",
        "expiration_year": "String"
    }
    ```

#### `coupons`
* **Purpose**: Defines rules for promotional codes that can be applied to contracts or invoices.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "code": "String",
      "discount": {
        "type": "String",
        "percentage_value": "Decimal128",
        "fixed_amounts": [
          { "currency": "String", "amount": "Decimal128" }
        ]
      },
      "is_active": "Boolean",
      "validity_rules": {
        "start_date": "Date",
        "end_date": "Date",
        "max_uses": "Number",
        "current_uses": "Number"
      },
      "created_at": "Date"
    }
    ```

#### `usage_records`
* **Purpose**: An immutable log of all metered usage events to be billed.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "contract_id": "ObjectId()",
      "item_name": "String",
      "quantity": "Number",
      "invoice_id": "ObjectId()",
      "timestamp": "Date"
    }
    ```

#### `refunds`
* **Purpose**: An immutable log for cash refunds issued against a payment.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "payment_id": "ObjectId()",
      "invoice_id": "ObjectId()",
      "currency": "String",
      "amount": "Decimal128",
      "reason": "String",
      "status": "String",
      "processed_at": "Date"
    }
    ```

#### `credit_notes`
* **Purpose**: Manages the state of non-cash service credits for a user.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "user_id": "ObjectId()",
      "currency": "String",
      "total_amount": "Decimal128",
      "remaining_balance": "Decimal128",
      "reason": "String",
      "status": "String",
      "created_at": "Date"
    }
    ```

#### `credit_note_applications`
* **Purpose**: An immutable audit trail for how credits are applied to invoices.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "credit_note_id": "ObjectId()",
      "invoice_id": "ObjectId()",
      "currency": "String",
      "amount_applied": "Decimal128",
      "applied_at": "Date"
    }
    ```

#### `tax_rates`
* **Purpose**: A central repository for all applicable tax rates.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "name": "String",
      "description": "String",
      "rate_percentage": "Decimal128",
      "type": "String",
      "jurisdiction": {
        "country": "String",
        "state": "String",
        "city": "String"
      },
      "is_active": "Boolean",
      "created_at": "Date"
    }
    ```

### 4.2. Attribution Engine Collections

---

## 5. Core Financial Processes

This section describes the dynamic, automated processes that govern the lifecycle of financial objects within the Commercial Engine.

### 5.1. Subscription and Invoicing Lifecycle

This process outlines how recurring invoices are generated for different types of subscription contracts.

1.  **Contract Creation & Initial Invoice:** When any subscription `contract` is created, the system immediately generates the first `invoice` for the initial billing cycle.

2.  **Invoice Generation by Billing Model:**
    *   **For `fixed_installments` contracts:** All future invoices for the entire term of the contract are created at the same time as the first invoice. These future-dated invoices are given a `status` of `"scheduled"`.
    *   **For `standard_subscription` contracts:** Invoices are generated one at a time by a scheduled background job (see below).

3.  **Scheduled Job for Subscriptions:** A scheduled, idempotent background job (e.g., a cron job running daily) is responsible for managing the lifecycle of all active subscriptions. It performs two key functions:
    *   **Activates Scheduled Invoices:** It scans for `invoices` with a `status` of `"scheduled"` and updates their status to `"pending"` when the billing cycle they represent is approaching (e.g., 7 days away).
    *   **Generates Recurring Invoices:** For active `standard_subscription` contracts, it generates a new `invoice` for the next billing cycle when it is approaching.

4.  **Contract Status:** The scheduled job is also responsible for updating the `contracts.status` based on the status of its invoices and payments, ensuring the contract accurately reflects its current state (e.g., transitioning to `"payment_overdue"` if an invoice is not paid on time).

### 5.2. Dunning and Collections Process

This process describes how the system automatically manages overdue invoices and attempts to recover payment.

1.  **Dunning Trigger:** A scheduled job periodically scans for `invoices` where the `status` is `"overdue"`.

2.  **Dunning Schedule:** The system will follow a configurable dunning schedule, which defines the number and frequency of payment retry attempts and customer notifications. For example: `[1 day, 3 days, 5 days]` after the due date.

3.  **Retry Attempts:** At each step in the dunning schedule, the system will:
    *   Attempt to process a `payment` against the overdue `invoice` using the customer's default payment method.
    *   Log the outcome of the attempt in the `invoices.dunning_history`.
    *   Update the `invoices.dunning_status` with the next retry attempt date.
    *   Optionally, send a notification to the customer (e.g., "Payment Failed").

4.  **Process Conclusion:**
    *   **If a payment succeeds:** The `invoice.status` is updated to `"paid"`, the `contracts.status` is updated to `"active"`, and the dunning process for that invoice ends.
    *   **If all retry attempts fail:** The dunning process ends. The `invoice` remains `"overdue"`, and the `contracts.status` may be transitioned to `"lapsed"` or another terminal state, based on business rules.

### 5.3. Metered Billing Process

This process outlines how usage-based charges are aggregated and billed.

1.  **Usage Logging:** The application continuously logs `usage_records` for each contract as metered components are consumed.

2.  **Billing Cycle Trigger:** At the end of each billing cycle for a contract with metered components, a billing job is triggered.

3.  **Aggregation:** The job queries all unbilled `usage_records` for the contract within the completed billing cycle.

4.  **Invoice Generation:**
    *   The aggregated usage is used to create new `line_items` on the invoice for that cycle. The amount for each line item is calculated based on the `price_per_unit` defined in the `contract.price_snapshot.metered_components`.
    *   These line items are added to the recurring subscription invoice for that cycle, or a new invoice is created if the billing is purely usage-based.

5.  **Marking as Billed:** Once the usage-based line items are successfully added to an invoice, the corresponding `usage_records` are updated with the `invoice_id` to mark them as billed and prevent double-billing.

### 5.4. Product-to-Invoice Mapping

This section defines how a `product`, which may be a bundle of several `catalog_items`, is represented on an `invoice`.

*   **Representation:** Each product sold under a `contract` is represented as a **single line item** on the `invoice`. The `line_item.description` is derived from the `product.name`.

*   **Bundle Details:** To provide full transparency, the `line_item` contains a `bundle_components` field. This field is an array that lists all the constituent `catalog_items` and their quantities that make up the product, ensuring that the invoice line item carries the full details of the bundle.

---

## 6. Enumerations

This section provides a centralized reference for all fields that use a fixed set of string values.

### `catalog_items`
*   `type`: `"course_bundle"`, `"physical_good"`, `"service"`
*   `media_gallery.type`: `"image"`, `"video"`

### `prices`
*   `billing_model`: `"one_time"`, `"fixed_installments"`, `"standard_subscription"`, `"accruing_subscription"`
*   `billing_cycle.interval`: `"day"`, `"week"`, `"month"`, `"year"`
*   `conversion_behavior`: `"fixed"`, `"automatic"`

### `contracts`
*   `status`: `"trialing"`, `"active"`, `"payment_overdue"`, `"paused"`, `"lapsed"`, `"in_legal_dispute"`, `"fulfilled"`, `"cancelled"`

### `invoices`
*   `status`: `"pending"`, `"partially_paid"`, `"paid"`, `"overdue"`, `"voided"`, `"replaced"`, `"scheduled"`
*   `line_items.type`: `"installment"`, `"late_fee"`, `"interest"`, `"enrollment_fee"`

### `payments`
*   `status`: `"succeeded"`, `"pending"`, `"failed"`
*   `payment_method.type`: `"credit_card"`, `"bank_transfer"`, `"cash"`, `"credit_note"`

### `coupons`
*   `discount.type`: `"percentage"`, `"fixed_amount"`

### `refunds`
*   `status`: `"succeeded"`, `"pending"`, `"failed"`

### `credit_notes`
*   `status`: `"available"`, `"fully_redeemed"`, `"voided"`

### `tax_rates`
*   `type`: `"vat"`, `"sales_tax"`

### `attribution_sources`
*   `type`: `"affiliate"`, `"salesperson"`, `"campaign"`
*   `status`: `"active"`, `"inactive"`
*   `tracking_codes.type`: `"url_parameter"`, `"coupon_code"`, `"referral_link"`

### `touchpoints`
*   `type`: `"ad_click"`, `"affiliate_link_visit"`, `"form_submission"`

The following collections reside in the database of each **Tenant**.

#### `attribution_sources`

* **Purpose:** The master catalog of all entities that can be credited for a sale.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "name": "String",
      "type": "String",
      "status": "String",
      "tracking_codes": [ { "type": "String", "value": "String" } ],
      "details": {},
      "created_at": "Date",
      "updated_at": "Date"
    }
    ```

* **Details Schema for `type: "affiliate"`**:
    ```json
    {
        "commission_rate_percentage": "Decimal128",
        "payout_terms": "String"
    }
    ```

* **Details Schema for `type: "salesperson"`**:
    ```json
    {
        "employee_id": "String"
    }
    ```

* **Details Schema for `type: "campaign"`**:
    ```json
    {
        "budget": "Decimal128",
        "currency": "String",
        "start_date": "Date",
        "end_date": "Date"
    }
    ```

#### `touchpoints`

* **Purpose:** An immutable log of all attribution-related interactions.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "source_id": "ObjectId()",
      "anonymous_visitor_id": "String",
      "type": "String",
      "context": { "ip_address": "String", "user_agent": "String" },
      "timestamp": "Date"
    }
    ```