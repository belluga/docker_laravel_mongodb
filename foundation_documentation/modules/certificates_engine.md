# Documentation: The Certificates Engine

**Version:** 1.0
**Date:** October 16, 2025
**Authors:** Belluga Learning & Engineering

## 1. Overview

The **Certificates Engine** is a specialized module designed to manage the entire lifecycle of student credentials. Its responsibilities include the definition of certificate templates, management of third-party issuing partners, automated and manual issuance of certificates, and providing a public mechanism for verification.

The engine is designed to support both formal certifications, typically issued upon course completion, and micro-credentials, which can be awarded for achieving smaller milestones, such as completing a specific set of interactive **Checkpoints**. It operates as a self-contained module in full compliance with the platform's event-driven architecture.

---

## 2. Design Principles

This module fully complies with the `system_architecture_principles.md` document.

### 2.1. Reusability via the Prototype Configuration Pattern
The creation of certificates is governed by the **Prototype Configuration Pattern**. Administrators define a library of reusable `certificate_templates`, which specify the visual design, content, issuing partner, and issuance triggers. When a certificate is awarded, the system creates an immutable `certificate` document by taking a deep **snapshot** of the template, ensuring each credential is a permanent, self-contained historical record.

### 2.2. Decoupled Issuance Triggers
The engine is designed to be a pure event consumer. It does not poll other systems for student progress. Instead, it subscribes to platform-wide events (e.g., `EnrollmentCompleted`, `CheckpointMilestoneReached`) and evaluates them against the `issuance_trigger` rules defined in `certificate_templates`. This ensures the engine remains fully decoupled from the business logic of other modules like the Learning Engine.

### 2.3. Formalized Partner Management
The relationship with external, third-party certification bodies is formalized through the `certificate_issuers` collection. This tenant-level collection serves as the single source of truth for all issuing partners, decoupling partner data from the certificate templates themselves and allowing for centralized management of these key relationships.

### 2.4. Publicly Verifiable Credentials
Every issued `certificate` contains a unique, non-sequential `verification_key`. This design anticipates the need for a public-facing verification portal where the authenticity of a credential can be confirmed without requiring a user to log in, thus increasing the value and trustworthiness of the certificates issued by the platform.

---

## 3. Detailed Collection Schemas

The following collections reside in the database of each **Tenant**.

### 3.1. `certificate_issuers`
* **Purpose**: The canonical, tenant-wide library of all internal and external partners who can issue certificates.
* **Scope**: Tenant-level data (no `account_id`).
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "name": "String",
      "description": "String",
      "logo_url": "String",
      "website_url": "String",
      "contact_info": {
        "email": "String",
        "phone": "String"
      },
      "created_at": "Date",
      "updated_at": "Date"
    }
    ```

### 3.2. `certificate_templates`
* **Purpose**: A library of reusable, prototypical certificate designs and rules, scoped to an `Account`.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "name": "String",
      "description": "String",
      "issuer_id": "ObjectId()",
      "issuance_trigger": {
        "type": "String",
        "course_id": "ObjectId()",
        "required_checkpoint_keys": ["String"]
      },
      "layout_config": {
        "background_image_url": "String",
        "logo_position": "String",
        "signature_image_url": "String",
        "primary_color": "String"
      },
      "content_fields": {
        "title": "String",
        "body_template": "String",
        "show_issue_date": "Boolean",
        "show_grade": "Boolean"
      },
      "created_at": "Date",
      "updated_at": "Date"
    }
    ```
* **Field Definitions**:
    * `issuance_trigger.type`:
        * `"on_course_completion"`: Issues the certificate when the specified `course_id` is completed.
        * `"on_checkpoint_completion"`: Issues when all checkpoints listed in `required_checkpoint_keys` are successfully completed by a user.
        * `"manual"`: The certificate can only be issued via a direct administrative action.

### 3.3. `certificates`
* **Purpose**: An immutable, self-contained record of a specific certificate that has been issued to a user.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "user_id": "ObjectId()",
      "enrollment_id": "ObjectId()",
      "source_template_id": "ObjectId()",
      "verification_key": "String",
      "status": "String",
      "issued_at": "Date",
      "revoked_at": "Date",
      "revocation_reason": "String",
      "template_snapshot": {
        "name": "String",
        "issuer_name": "String",
        "issuer_logo_url": "String",
        "layout_config": {},
        "content_fields": {}
      },
      "personalized_data": {
        "student_name": "String",
        "course_name": "String",
        "final_grade_percentage": "Number"
      },
      "created_at": "Date"
    }
    ```
* **Field Definitions**:
    * `status`: `"issued"`, `"revoked"`.