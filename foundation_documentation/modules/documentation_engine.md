# Documentation: The Documentation Engine

**Version:** 1.0
**Date:** October 16, 2025
**Authors:** Belluga Learning & Engineering

## 1. Overview

The **Documentation Engine** is a specialized module responsible for managing the lifecycle of student-submitted documents required for course certification. It handles the definition of reusable sets of document requirements, the storage of submitted files, a formal review process, and a dedicated communication channel.

By operating as a decoupled engine, it centralizes all document-related concerns, ensuring that other modules, like the Learning Engine, remain unburdened by the complexities of file management and validation.

## 2. Design Principles

This module fully complies with the `system_architecture_principles.md` document.

### 2.1. Reusability via the Prototype Configuration Pattern
To maximize reusability and simplify administration, document requirements are defined in a central library of prototypes called **`document_requirement_sets`**. As established in our core architectural principles, a `course` in the Learning Engine is created by taking an immutable snapshot of a chosen prototype. This decouples the course from the prototype, ensuring a stable and predictable set of requirements for students throughout their enrollment.

### 2.2. Configurable Workflows via Stage Mapping
The review process is not based on a fixed set of statuses. Administrators can define a series of custom "stages" for each document requirement within a prototype. Each custom stage is mapped to a canonical system `status` (e.g., `PENDING`, `SUCCESS`). This allows for varied internal workflows while ensuring that the aggregated status reported to the `enrollments` "Status Hub" remains consistent and machine-readable.

### 2.3. Segregated Audit and Communication Trails
The engine maintains two distinct historical records for maximum clarity:
* **`review_history` (in `student_documents`)**: A formal audit log of all *stage transitions*.
* **`document_conversations` collection**: A dedicated log for all informal, two-way messages between students and reviewers.

### 2.4. Event-Driven Status Aggregation
The engine manages the detailed status of each individual document. Upon any stage change, it emits an event. A listener service consumes these events, re-evaluates the student's overall documentation status, and populates the aggregate `status.documentation` field in the `enrollments` "Status Hub."

## 3. Detailed Collection Schemas

The following collections reside in the database of each **Tenant**.

### 3.1. `document_requirement_sets`
* **Purpose**: Stores a library of reusable prototypes for document requirements, scoped to an `Account`. This is the master collection for defining what needs to be submitted.
* **Structure**:
    ```json
    {
        "_id": "ObjectId()",
        "account_id": "ObjectId()",
        "name": "String",
        "description": "String",
        "required_documents": [
            {
                "key": "string",
                "name": "string",
                "description": "string",
                "workflow_stages": [
                    {
                        "key": "string",
                        "name": "string",
                        "status": "string",
                        "order": "Number"
                    }
                ]
            }
        ]
    }
    ```
* **Field Definitions:**
    * `workflow_stages.status`: The canonical system status that this stage maps to.
        * `"PENDING"`: The document is awaiting action or has been submitted and is under review.
        * `"SUCCESS"`: The document has been approved and fulfills its requirement.
        * `"ACTION_REQUIRED"`: The document has been reviewed and requires changes or resubmission from the user.

### 3.2. `student_documents`
* **Purpose**: Stores a specific user's submission for a single document requirement, tracking its lifecycle through the custom workflow defined in the course snapshot.
* **Structure**:
    ```json
    {
        "_id": "ObjectId()",
        "account_id": "ObjectId()",
        "user_id": "ObjectId()",
        "enrollment_id": "ObjectId()",
        "document_key": "String",
        "current_stage_key": "String",
        "files": [
            {
                "version_id": "ObjectId()",
                "url": "String",
                "name": "String",
                "uploaded_at": "Date"
            }
        ],
        "review_history": [
            {
                "reviewer_id": "ObjectId()",
                "reviewed_at": "Date",
                "from_stage_key": "String",
                "to_stage_key": "String",
                "notes": "String",
                "reviewed_files_version_id": "ObjectId()"
            }
        ],
        "created_at": "Date",
        "updated_at": "Date"
    }
    ```

### 3.3. `document_conversations`
* **Purpose**: An immutable log of messages related to a specific `student_document`.
* **Structure**:
    ```json
    {
        "_id": "ObjectId()",
        "account_id": "ObjectId()",
        "student_document_id": "ObjectId()",
        "user_id": "ObjectId()",
        "message": "String",
        "created_at": "Date"
    }
    ```