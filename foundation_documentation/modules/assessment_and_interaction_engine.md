# Documentation: The Assessment & Interaction Engine

**Version:** 1.0
**Date:** October 16, 2025
**Authors:** Belluga Learning & Engineering

## 1. Overview

This document describes the architecture of three distinct but related domains that govern how students are assessed and how they interact with learning content. While described together for documentation efficiency, these operate as **separate conceptual modules** that are cleanly decoupled from each other and the broader system.

* **The Quizzes Engine:** Manages formal, objective-based assessments like multiple-choice tests and exams. It handles question banks, automated grading, and complex test configurations.
* **The Submissions Engine:** Manages the lifecycle of formal, subjective assignments that require manual review, such as essays, projects, and portfolios.
* **The Annotations Engine:** Manages informal, private user interactions with content, such as personal notes, highlights, and bookmarks.

All three engines adhere strictly to the platform's core architectural principles, operating as self-contained services that communicate via events.

---

## 2. Design Principles

### Design Principles (Quizzes)

* **Reusability via a Hierarchical Question Bank:** The engine separates the creation of `questions` from their use in a `quiz`. Questions are stored in a central, account-scoped library for efficient reuse.
* **Prototype Configuration for Quizzes:** To ensure academic consistency and efficiency, `quizzes` are created using the **Prototype Configuration Pattern**. A library of `quiz_templates` (e.g., "Weekly Check," "Final Exam") provides standard configurations that are snapshotted into a new `quiz` document, making it a self-contained record.
* **Immutable Attempt Records for Auditability:** When a user begins a quiz, a **snapshot** of the questions is taken to ensure the historical integrity of the attempt record, even if the original questions are later edited.
* **Event-Driven for Decoupled Integration:** The engine emits events like `QuizAttemptCompleted`, allowing external services (like the Multidimensional Insights Service) to consume outcomes without a hard dependency.

### Design Principles (Submissions)

* **Decoupling Submission from Review:** The `assignment_submissions` collection is kept separate from the `submission_reviews` collection. This decouples the student's work from the evaluator's feedback, architecturally enabling future features like multi-reviewer workflows.
* **Event-Driven for Maximum Decoupling:** The engine is a significant event producer, firing events like `SubmissionReceived` and `SubmissionGraded` to notify other systems of state changes without creating dependencies.

### Design Principles (Annotations)

* **Context-Aware Anchoring:** An annotation is never linked to a generic `learning_object`. Instead, it is always anchored to a specific user's `enrollment` and the immutable `node_id` within the cohort's `structure_snapshot`, ensuring its context remains valid over time.
* **Polymorphic `reference_point` for Extensibility:** The `reference_point` field is a polymorphic object whose structure is determined by the content type being annotated (e.g., a video timestamp or a text selection). This design allows the engine to support new content types in the future without schema changes.

---

## 3. Detailed Collection Schemas

### Quizzes Engine Collections

The following collections reside in the database of each **Tenant**.

#### `quiz_templates`

* **Purpose**: A library of reusable, prototypical configurations for quizzes.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "name": "String",
      "template_data": {
        "attempts": {
            "mode": "String",
            "value": "Number"
        },
        "time_limit_seconds": "Number",
        "shuffle_questions": "Boolean",
        "shuffle_options": "Boolean",
        "passing_criteria": {
            "type": "String",
            "value": "Number"
        },
        "feedback_mode": "String"
      }
    }
    ```

#### `questions`

* **Purpose**: The master, account-level library of all individual questions.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "term_ids": ["ObjectId()"],
      "prompt": "String",
      "type": "String",
      "details": {},
      "created_at": "Date",
      "updated_at": "Date"
    }
    ```
* **Field Definitions:**
    * `type`: `"multiple_choice"`, `"true_false"`, `"fill_in_the_blank"`, `"matching"`, `"sorting"`, `"essay"`.

#### `quizzes`

* **Purpose**: Defines a specific test, its set of questions, and its operational rules. It is a self-contained record created from a `quiz_template`.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "source_template_id": "ObjectId()",
      "name": "String",
      "description": "String",
      "questions_config": {
        "selection_type": "String",
        "fixed_question_ids": ["ObjectId()"],
        "random_pool_rules": [
          {
            "term_id": "ObjectId()",
            "number_to_pull": "Number"
          }
        ]
      },
      "config": {
        "attempts": {
            "mode": "String",
            "value": "Number"
        },
        "time_limit_seconds": "Number",
        "shuffle_questions": "Boolean",
        "shuffle_options": "Boolean",
        "passing_criteria": {
            "type": "String",
            "value": "Number"
        },
        "feedback_mode": "String"
      },
      "created_at": "Date",
      "updated_at": "Date"
    }
    ```
* **Field Definitions:**
    * `questions_config.selection_type`: `"fixed"` (uses the `fixed_question_ids` array), `"random_pool"` (uses the `random_pool_rules`).
    * `config.attempts.mode`: `"custom"`, `"unlimited"`.
    * `config.passing_criteria.type`: `"percentage"`, `"points"`.
    * `feedback_mode`: `"deferred"` (feedback is shown only after the quiz is completed), `"immediate"` (feedback is shown after each question).

#### `quiz_attempts`

* **Purpose**: An immutable record of a single user's attempt to complete a quiz.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "enrollment_id": "ObjectId()",
      "user_id": "ObjectId()",
      "node_id": "String",
      "quiz_id": "ObjectId()",
      "status": "String",
      "started_at": "Date",
      "completed_at": "Date",
      "answers": [
        {
          "question_id": "ObjectId()",
          "question_snapshot": {},
          "user_answer": {},
          "is_correct": "Boolean"
        }
      ],
      "result": {
        "score": "Number",
        "is_passing": "Boolean"
      }
    }
    ```
* **Field Definitions:**
    * `status`: `"in_progress"`, `"completed"`, `"pending_manual_grade"`.

#### `quiz_attempt_allowances`

* **Purpose**: Provides a mechanism to grant specific users additional attempts for a quiz.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "user_id": "ObjectId()",
      "enrollment_id": "ObjectId()",
      "quiz_id": "ObjectId()",
      "extra_attempts_granted": "Number",
      "granted_by_user_id": "ObjectId()",
      "created_at": "Date"
    }
    ```

### Submissions Engine Collections

The following collections reside in the database of each **Tenant**.

#### `assignment_submissions`

* **Purpose**: Tracks the lifecycle of a user's submission for a specific assignment.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "enrollment_id": "ObjectId()",
      "user_id": "ObjectId()",
      "node_id": "String",
      "learning_object_id": "ObjectId()",
      "status": "String",
      "submitted_at": "Date",
      "content": {
        "text_entry": "String",
        "file_attachments": [
            {
                "url": "String",
                "name": "String",
                "file_type": "String"
            }
        ],
        "link_submissions": [
            {
                "url": "String",
                "label": "String",
                "description": "String"
            }
        ]
      }
    }
    ```
* **Field Definitions:**
    * `status`: `"pending_review"`, `"under_review"`, `"graded"`, `"needs_revision"`.

#### `submission_reviews`

* **Purpose**: Stores an evaluator's feedback and grade for a specific submission.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "submission_id": "ObjectId()",
      "reviewer_id": "ObjectId()",
      "grade": {
        "value": "Number",
        "max_value": "Number",
        "is_passing": "Boolean"
      },
      "feedback": "String",
      "reviewed_at": "Date"
    }
    ```

### Annotations Engine Collections

The following collection resides in the database of each **Tenant**.

#### `annotations`

* **Purpose:** Stores a user's private notes, highlights, and bookmarks linked to a specific node in their cohort.
* **Structure**:
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "user_id": "ObjectId()",
      "enrollment_id": "ObjectId()",
      "node_id": "String",
      "learning_object_id": "ObjectId()",
      "type": "String",
      "reference_point": {},
      "content": {},
      "created_at": "Date",
      "updated_at": "Date"
    }
    ```
* **Field Definitions:**
    * `type`: `"note"`, `"highlight"`, `"bookmark"`.