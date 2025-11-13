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

### 2.9. Drip Schedules with Template + Snapshot Fidelity
* **Principle:** Time-based content releases must originate from template-level declarations and materialize as immutable cohort snapshots so identical courses can operate with distinct drip experiences.
* **Justification:** Administrators often need the same curriculum to unlock either from each learner's enrollment moment or from a fixed program kickoff. Capturing the rule at the template layer while freezing cohort schedules preserves repeatability and honors the snapshot mandate.
* **Implementation:** Each course template may attach a `drip_policy_template` that declares initialization strategy and relative release offsets. When a cohort is instantiated, the template clones into a `cohort_drip_schedule`. Each enrollment resolves its own initialization timestamp—based on the strategy—and references the cohort schedule when evaluating access.

### 2.10. Paused Enrollment Recovery
* **Principle:** Long pauses (e.g., six months) must preserve learner continuity without breaking the contractual cohort experience or releasing content prematurely.
* **Justification:** Learners may defer progression for extended periods due to life events. The system must freeze upcoming releases while allowing already-unlocked material to remain accessible and provide deterministic resumption rules aligned with the selected drip policy.
* **Implementation:** When an enrollment transitions to an `access` status of `"frozen"` or `"suspended"`, the Learning Engine records a pause window inside the enrollment drip state and halts release evaluation. Upon resumption, the engine applies the policy's `pause_behavior`: shifting remaining releases forward by the accumulated pause duration, unlocking all pending items immediately, or leaving the original schedule intact. The recalculated schedule is persisted and audited so downstream surfaces (progress summaries, personalization, notifications) realign automatically.

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
      ],
      "drip_policy_templates": [
        {
          "policy_key": "String",
          "display_name": "String",
          "status": "String",
          "initialization_strategy": {
            "type": "String",
            "fixed_start_at": "Date",
            "timezone": "String"
          },
          "pause_behavior": {
            "mode": "String",
            "grace_days": "Number",
            "max_pause_days": "Number"
          },
          "release_sequences": [
            {
              "template_node_id": "String",
              "offset_days": "Number",
              "offset_hours": "Number",
              "release_time": "String",
              "release_window_hours": "Number"
            }
          ],
          "overrides": [
            {
              "audience_segment_key": "String",
              "template_node_id": "String",
              "offset_days": "Number",
              "offset_hours": "Number"
            }
          ],
          "created_at": "Date",
          "updated_at": "Date"
        }
      ]
    }
    ```
* **Field Definitions:**
    * `drip_policy_templates[].status`: `"draft"`, `"published"`, `"retired"`.
    * `drip_policy_templates[].initialization_strategy.type`: `"follow_enrollment"`, `"fixed_start"`.
    * `drip_policy_templates[].pause_behavior.mode`: `"shift_schedule"`, `"no_change"`.
        * `"shift_schedule"` adds the total paused duration to pending release timestamps, ensuring pacing resumes as designed.
        * `"no_change"` resumes evaluation against the original timestamps; items whose `release_at` is now in the past publish immediately on resume, while future-dated releases stay locked until their planned time.
    * `drip_policy_templates[].release_sequences[].release_time`: ISO-8601 local time string (`"HH:mm"` using the policy timezone) applied when offsets resolve to a day boundary.

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
* **Commercial Positioning:** Courses are never marketed or sold directly; they exist as reusable blueprints that become sellable offerings only after a cohort is instantiated against them and paired with contractual pricing.
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
      "drip_configuration": {
        "policy_key": "String",
        "initialization_strategy_override": {
          "type": "String",
          "fixed_start_at": "Date",
          "timezone": "String"
        }
      },
      "created_at": "Date",
      "updated_at": "Date"
    }
    ```
* **Field Definitions:**
    * `drip_configuration.initialization_strategy_override.type`: `"inherit"`, `"follow_enrollment"`, `"fixed_start"`. `"inherit"` applies the strategy defined on the referenced template policy.

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
      "drip_schedule_snapshot": {
        "policy_key": "String",
        "initialization_strategy": {
          "type": "String",
          "cohort_initialization_at": "Date",
          "timezone": "String"
        },
        "schedule_items": [
          {
            "snapshot_node_id": "String",
            "offset_days": "Number",
            "offset_hours": "Number",
            "release_time": "String",
            "release_window_hours": "Number"
          }
        ]
      },
      "created_at": "Date",
      "updated_at": "Date"
    }
    ```
* **Field Definitions:**
    * `status`: `"draft"`, `"published"`, `"in_progress"`, `"completed"`, `"archived"`.
    * `drip_schedule_snapshot.initialization_strategy.type`: `"follow_enrollment"`, `"fixed_start"`.
    * `drip_schedule_snapshot.schedule_items[].release_time`: ISO-8601 local time string evaluated against the schedule timezone when offsets reach a calendar day.

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
      "initialization_at": "Date",
      "drip_state_id": "ObjectId()",
      "enrolled_at": "Date"
    }
    ```
* **Justification for the "Status Hub" Model:** The `status` object contains keys representing different business domains. This design choice creates a read-optimized record for a student's journey. State changes are managed via events. This architectural pattern is also used in the `progress_summaries` collection to provide a real-time, performant view of a student's learning progress.
* **Pause Semantics:** Transitioning `status.access` to `"frozen"` or `"suspended"` records a pause window on the associated `enrollment_drip_states` document and suspends new releases until the learner returns.
* **Status Definitions:**
    * **`financial` statuses:** `"pending_activation"`, `"in_good_standing"`, `"payment_overdue"`, `"paused"`, `"in_legal_dispute"`, `"fulfilled"`, `"cancelled"`.
    * **`educational` statuses:** `"not_started"`, `"in_progress"`, `"completed"`.
    * **`access` statuses:** `"granted"`, `"frozen"`, `"suspended"`, `"revoked"`.
    * **`documentation` statuses:** `"not_required"`, `"pending_submission"`, `"pending_review"`, `"changes_requested"`, `"approved"`.
* **Initialization Behavior:** `initialization_at` persists the resolved course start for the enrollment, derived from the cohort snapshot strategy (enrollment-relative or fixed date). The `drip_state_id` references the `enrollment_drip_states` collection described below.

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

### 3.9. `enrollment_drip_states`
* **Purpose:** Maintain each learner's resolved drip schedule, guaranteeing accurate release timestamps regardless of enrollment timing or policy changes.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "cohort_id": "ObjectId()",
      "enrollment_id": "ObjectId()",
      "initialization_at": "Date",
      "schedule_items": [
        {
          "snapshot_node_id": "String",
          "release_at": "Date",
          "release_status": "String",
          "released_at": "Date",
          "lock_reason": "String",
          "release_adjustment_seconds": "Number"
        }
      ],
      "pause_windows": [
        {
          "started_at": "Date",
          "resumed_at": "Date",
          "duration_seconds": "Number"
        }
      ],
      "total_paused_seconds": "Number",
      "pause_behavior_mode": "String",
      "next_release_at": "Date",
      "last_evaluated_at": "Date",
      "created_at": "Date",
      "updated_at": "Date"
    }
    ```
* **Field Definitions:**
    * `schedule_items[].release_status`: `"pending"`, `"released"`, `"skipped"`.
    * `lock_reason`: Optional descriptor when a release is intentionally delayed (e.g., `"blocked_by_gating_rule"`, `"manual_hold"`, `"paused_enrollment"`).
    * `pause_behavior_mode`: Mirrors the resolved policy behavior at the time of enrollment initialization.
* **Release Evaluation:** A dedicated scheduler (`drip-release-tick`) executes every 15 minutes per tenant, resolving pending items whose `release_at` has elapsed, adjusting timestamps in accordance with accumulated `total_paused_seconds`, and emitting `DripContentReleased` events for downstream personalization. `pause_behavior_mode` may be `"shift_schedule"` or `"no_change"` depending on the originating policy.

### 3.10. `assets`
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

### 3.11. `checkpoint_responses`
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

## 4. API Endpoint Definitions

| Endpoint | Method | Description | Required Role | Request Schema | Response Schema |
|----------|--------|-------------|---------------|----------------|-----------------|
| `/admin/api/v1/learning/courses/{course_id}/drip-policies` | POST | Author a drip policy instance for the course, binding to a template policy key and optional initialization override. | `learning.admin` | `CourseDripPolicyRequest` | `CourseDripPolicyResponse` |
| `/admin/api/v1/learning/courses/{course_id}/drip-policies/{policy_key}` | PUT | Replace the release offsets, status, or initialization strategy for an existing course policy. | `learning.admin` | `CourseDripPolicyRequest` | `CourseDripPolicyResponse` |
| `/api/v1/learning/cohorts/{cohort_id}/drip-schedule/preview` | POST | Resolve the cohort snapshot schedule given a prospective initialization timestamp to support launch planning. | `learning.manager` | `DripSchedulePreviewRequest` | `DripSchedulePreviewResponse` |
| `/api/v1/learning/enrollments/{enrollment_id}/drip` | GET | Retrieve the learner's drip state, including upcoming releases and release history. | `learning.participant` (self) or `learning.coach` | N/A | `EnrollmentDripStateResource` |
| `/api/v1/learning/enrollments/{enrollment_id}/drip/recalculate` | POST | Force recalculation of the enrollment drip state after manual overrides or reinstatements. | `learning.coach` | `EnrollmentDripRecalculateRequest` | `EnrollmentDripStateResource` |

* **CourseDripPolicyRequest:** Wraps `policy_key`, `status`, optional initialization override, and the array of `release_sequences` aligning with `drip_policy_templates`.
* **DripSchedulePreviewRequest:** Accepts a candidate `initialization_at` and optional audience segment to evaluate overrides.
* **EnrollmentDripStateResource:** Mirrors `enrollment_drip_states`, omitting internal audit fields while exposing `upcoming` and `released` projections tailored for the UI.

## 5. Conclusion
The **Learning Engine** is designed to be the robust pillar of our platform. The clear separation of responsibilities between its collections and full compliance with our system's multi-tenancy architecture ensures that we can scale our course offerings, manage cohorts securely, and, most importantly, expand the system with new modules in a clean and decoupled manner.
