# Documentation: The Learning Engine

**Version:** 1.1
**Date:** October 16, 2025
**Authors:** Belluga Learning & Engineering

## 1. Overview

The **Learning Engine** is the core module of our application, responsible for the entire architecture and delivery of the educational experience. Its function is to manage the creation, structuring, instantiation, and progress tracking of all learning content on the platform.

It was designed to be **flexible**, **reusable**, and **scalable**, allowing the platform to create everything from simple courses to complex programs where the same content can be reused in different contexts without creating conflicts.

The system operates on the fundamental distinction between **raw content** (what a lesson is), the **master structure** (how lessons are organized into a course template), and the **live instance** (the specific cohort in which a student enrolls).

---

## 2. Design Principles

### 2.1. Absolute Separation between Content and Structure
The most critical decision was to decouple content from its structure.
* **Content (`learning_objects`):** Atomic and independent "Lego blocks" (videos, quizzes). They do not know where or how they are used, ensuring maximum reusability.
* **Structure (`courses`):** The "instruction manual" that defines how the blocks fit together to form a cohesive and sellable model.

### 2.2. Prototype-Driven Creation for Reusability
The creation of complex entities like `courses` and their constituent `learning_objects` is governed by the **Prototype Configuration Pattern**. This allows administrators to define standard templates (`course_templates`, `assignment_templates`), which are then cloned to create new, fully independent entities. This promotes consistency while ensuring each entity is a safe, self-contained record.

### 2.3. Immutability of In-Progress Cohorts (The "Snapshot" Principle)
Once a cohort begins, its curricular structure (including document requirements) must not be altered by modifications to the master course or its original templates. When a `cohort` is created, it takes a deep **"snapshot"** of the master `course` structure at that moment. This copy (`structure_snapshot`) becomes the immutable "truth" for that specific cohort.

### 2.4. Contextual and Granular Progress
A student's progress (`progress_trackers`) is not measured against generic content, but against their journey within a specific cohort, linked to the `node_id` from the cohort's `structure_snapshot`.

### 2.5. Granular Interaction Tracking via Checkpoints
To increase engagement and gather fine-grained comprehension data, the system supports **Checkpoints**: lightweight, non-graded interactive elements embedded directly within a `learning_object`. User responses are captured in a dedicated, immutable `checkpoint_responses` collection, providing a rich dataset for analytics without cluttering the primary progress logs.

### 2.6. Event-Driven Architecture for Decoupling
The Learning Engine must not have knowledge of other systems. It only emits signals (events) like `LearningObjectCompleted` and `CheckpointRespondedTo` when important actions occur.

### 2.7. Derived Skill Association via Decoupling
* **Principle:** The association of skills or knowledge topics with a `course` must be **derived**, not stored directly. A course's "skill tags" are a dynamic reflection of the insight rules associated with its constituent `learning_objects`.
* **Justification:** Creating a direct reference would create a hard dependency from the Learning Engine to the Insights Service, a direct violation of our system's architecture.
* **Implementation:** The list of topics for a given course is computed at the API/application layer at runtime by querying the `insight_rules` collection in the Multidimensional Insights Service.

### 2.8. Optimized Progression Checks via `progress_summaries`
* **Principle:** To maintain a highly responsive user experience, checks for content access based on `gating_rules` must be optimized for read performance.
* **Justification:** The `progress_trackers` collection is an immutable, write-heavy log, not suitable for frequent queries required by the UI. The `progress_summaries` collection serves as a denormalized, read-optimized cache for this purpose.
* **Implementation:**
    * When a user completes a lesson, a record is created in `progress_trackers`.
    * This event triggers an update to the user's single `progress_summaries` document, adding the `node_id` to a list of completed nodes.
    * When checking a `gating_rule` of type `require_completion`, the application queries the `progress_summaries` document, not the `progress_trackers` collection.
    * For rules of type `require_quiz_pass`, the application queries the `Quizzes Engine` directly, as it is the source of truth for quiz results.

---

## 3. Detailed Collection Schemas

The following collections reside in the database of each **Tenant**.

### 3.1. `course_templates`
* **Purpose**: A library of reusable, prototypical course structures.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "name": "String",
      "description": "String",
      "template_structure": [
        {
          "node_id": "String",
          "learning_object_id": "ObjectId()",
          "order": "Number",
          "parent_node_id": "String",
          "gating_rules": [ { "type": "String", "dependency_node_id": "String" } ]
        }
      ],
      "template_document_requirements": [
          {
              "key": "string",
              "name": "string",
              "description": "string",
              "workflow_stages": [ { "key": "string", "name": "string", "status": "string", "order": "Number" } ]
          }
      ]
    }
    ```

### 3.2. `assignment_templates`
* **Purpose**: A library of reusable configurations for submittable assignments.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "name": "String",
      "template_data": {
        "prompt": "String",
        "allowed_file_types": ["String"],
        "max_attachments": "Number",
        "grading_criteria": {
            "max_points": "Number",
            "passing_threshold_percentage": "Number"
        }
      }
    }
    ```

### 3.3. `learning_objects`
* **Purpose:** The central, tenant-wide library of all atomic and reusable learning content.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "owner_account_id": "ObjectId()",
      "is_global": "Boolean",
      "title": "String",
      "description": "String",
      "thumbnail_url": "String",
      "teacher_ids": ["ObjectId()"],
      "type": "String",
      "assets": [
        {
          "asset_id": "String",
          "file_name": "String",
          "description": "String",
          "file_url": "String",
          "file_type": "String",
          "file_size_bytes": "Number"
        }
      ],
      "content": {},
      "submission_config": {
        "source_template_id": "ObjectId()",
        "is_submittable": "Boolean",
        "prompt": "String",
        "allowed_file_types": ["String"],
        "max_attachments": "Number",
        "grading_criteria": {
            "max_points": "Number",
            "passing_threshold_percentage": "Number"
        }
      },
      "quiz_config": {
        "is_quiz": "Boolean",
        "quiz_id": "ObjectId()"
      },
      "created_at": "Date",
      "updated_at": "Date"
    }
    ```
* **Content Field Example (for `type: "video"`)**:
    ```json
    "content": {
      "provider": "vimeo",
      "video_id": "123456789",
      "duration_seconds": 1250,
      "subtitles": [
        {
          "language": "en-US",
          "label": "English",
          "url": "https://.../subs_en.vtt"
        }
      ],
      "checkpoints": [
        {
            "key": "intro_check_1",
            "timestamp_seconds": 120,
            "type": "multiple_choice",
            "prompt": "What was the main topic of this section?",
            "options": [
                { "key": "a", "text": "Topic A" },
                { "key": "b", "text": "Topic B" }
            ],
            "correct_option_key": "a"
        }
      ]
    }
    ```

### 3.4. `courses`
* **Purpose:** The "master template" of a course, scoped to a specific Account. It defines the standard curriculum and commercial information.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "source_template_id": "ObjectId()",
      "name": "String",
      "description": "String",
      "structure": [
        {
          "node_id": "String",
          "learning_object_id": "ObjectId()",
          "order": "Number",
          "parent_node_id": "String",
          "gating_rules": [
            {
              "type": "String",
              "dependency_node_id": "String"
            }
          ]
        }
      ],
      "document_requirements": [
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
      ],
      "created_at": "Date",
      "updated_at": "Date"
    }
    ```

### 3.5. `cohorts`
* **Purpose:** The "live" instance of a course offered by a specific Account, with start and end dates. This is the class in which students enroll.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "course_id": "ObjectId()",
      "name": "String",
      "start_date": "Date",
      "end_date": "Date",
      "status": "String",
      "structure_snapshot": [
        {
          "node_id": "String",
          "learning_object_id": "ObjectId()",
          "order": "Number",
          "parent_node_id": "String",
          "gating_rules": [
            {
              "type": "String",
              "dependency_node_id": "String"
            }
          ]
        }
      ],
      "created_at": "Date",
      "updated_at": "Date"
    }
    ```

### 3.6. `enrollments`
* **Purpose:** The central record that links a `user` to a `cohort`. It serves as the "Status Hub," providing a real-time, high-level summary of a student's standing in non-educational domains.
* **Justification for the "Status Hub" Model:** The `status` object contains keys representing different business domains. This design choice creates a read-optimized record for a student's journey. State changes are managed via events.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "user_id": "ObjectId()",
      "cohort_id": "ObjectId()",
      "contract_id": "ObjectId()",
      "status": {
        "financial": "String",
        "educational": "String",
        "access": "String",
        "documentation": "String"
      },
      "enrollment_policy": {
        "trial": {
          "type": "String",
          "duration_days": "Number"
        },
        "cancellation_grace_period": {
          "type": "String",
          "duration_days": "Number"
        }
      },
      "enrolled_at": "Date"
    }
    ```
* **Justification for the "Status Hub" Model:** The `status` object contains keys representing different business domains. This design choice creates a read-optimized record for a student's journey. State changes are managed via events. This architectural pattern is also used in the `progress_summaries` collection to provide a real-time, performant view of a student's learning progress.
* **Status Definitions:**
    * **`financial` statuses:** `"pending_activation"`, `"in_good_standing"`, `"payment_overdue"`, `"paused"`, `"in_legal_dispute"`, `"fulfilled"`, `"cancelled"`.
    * **`educational` statuses:** `"not_started"`, `"in_progress"`, `"completed"`.
    * **`access` statuses:** `"granted"`, `"frozen"`, `"suspended"`, `"revoked"`.
    * **`documentation` statuses:** `"not_required"`, `"pending_submission"`, `"pending_review"`, `"changes_requested"`, `"approved"`.

### 3.7. `progress_trackers`
* **Purpose:** An immutable, event-like log of a student's granular interactions with each item in their cohort's structure. The creation or update of a tracker document is the primary trigger for recalculating the `progress_summaries` record.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "enrollment_id": "ObjectId()",
      "user_id": "ObjectId()",
      "node_id": "String",
      "learning_object_id": "ObjectId()",
      "status": "String",
      "progress_details": {},// Polymorphic object for granular progress (e.g., { "time_watched_seconds": 245 })
      "completed_at": "Date",
      "updated_at": "Date"
    }
    ```
* **Field Definitions:**
    * `status`: `"not_started"`, `"in_progress"`, `"completed"`.

### 3.8. `progress_summaries`
* **Purpose:** A denormalized, read-optimized document that provides a real-time, comprehensive summary of a user's progress and behavioral engagement within a specific enrollment. This collection is the primary source for all performance dashboards, progress bars, and personalized feedback features in the UI.
* **Justification for the Extended Model:** This collection evolves from a simple completion tracker to a rich analytics hub. By summarizing data from various raw sources, it provides a single, high-performance record per enrollment. This avoids complex queries at runtime and enables proactive, data-driven features. The calculation of analytical fields is handled by a separate, decoupled **Insights Engine** which consumes platform-wide events and emits its own summary events, ensuring the Learning Engine remains focused and the overall system remains scalable.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "user_id": "ObjectId()",
      "enrollment_id": "ObjectId()",

      // --- Core Progress Metrics ---
      "total_nodes": "Number",
      "completed_nodes": "Number",
      "completion_percentage": "Number",
      "last_accessed_node_id": "String",
      "next_node_id": "String",

      // --- Engagement & Recency Metrics ---
      "first_activity_at": "Date",
      "last_activity_at": "Date",
      "total_active_days": "Number",
      "total_time_spent_seconds": "Number",
      "time_spent_details_seconds": {}, // e.g., { "video": 3600, "audio": 1800 }
      "engagement_streaks_in_days": {
        "current": "Number",
        "longest": "Number"
      },

      // --- Pacing & Momentum Metrics ---
      "pace_status": "String", // "ahead", "on_track", "behind", "not_started"
      "expected_completion_percentage": "Number",
      "completion_velocity_per_week": "Number",

      // --- Performance Indicators (Populated by other engines) ---
      "average_grade_percentage": "Number",
      "on_time_submission_rate": "Number",
      "total_assignments": "Number",
      "completed_assignments": "Number",

      // --- AI-Driven Learning Profile (Populated by Insights Engine) ---
      "learning_profile": {
        "risk_assessment": {
          "overall_level": "String", // "Low", "Medium", "High", "Critical"
          "overall_score": "Number",
          "details": {
            "engagement_risk": { "level": "String", "score": "Number" },
            "pacing_risk": { "level": "String", "score": "Number" },
            "performance_risk": { "level": "String", "score": "Number" }
          }
        },
        "learning_style_profile": {
            "primary_style": "String", // e.g., "Visual Learner"
            "details": {
                "video_consumption": { "level": "String", "score": "Number" },
                "project_based_work": { "level": "String", "score": "Number" },
                "text_based_reading": { "level": "String", "score": "Number" }
            }
        }
      },
      "updated_at": "Date"
    }
    ```

### 3.9. `assets`
* **Purpose**: The canonical, tenant-wide library for all media files (videos, PDFs, images).
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "owner_account_id": "ObjectId()",
      "file_name": "String",
      "description": "String",
      "file_url": "String",
      "file_type": "String",
      "file_size_bytes": "Number",
      "created_at": "Date"
    }
    ```

### 3.10. `checkpoint_responses`
* **Purpose**: An immutable log of a user's response to a single interactive Checkpoint within a `learning_object`.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "user_id": "ObjectId()",
      "enrollment_id": "ObjectId()",
      "node_id": "String",
      "learning_object_id": "ObjectId()",
      "checkpoint_key": "String",
      "user_response": {
          "selected_option_key": "String"
      },
      "is_correct": "Boolean",
      "responded_at": "Date"
    }
    ```

---

## 4. Conclusion
The **Learning Engine** is designed to be the robust pillar of our platform. The clear separation of responsibilities between its collections and full compliance with our system's multi-tenancy architecture ensures that we can scale our course offerings, manage cohorts securely, and, most importantly, expand the system with new modules in a clean and decoupled manner.