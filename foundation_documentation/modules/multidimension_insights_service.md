# Documentation: The Multidimensional Insights Service

**Version:** 1.1
**Date:** October 16, 2025
**Authors:** Belluga Learning & Engineering

## 1. Overview

The **Multidimensional Insights Service** is a specialized microservice responsible for tracking and quantifying any multi-dimensional aspect of a user's journey. It operates on models like **Skill Progression** and **Student Risk Assessment**.

As a fully external service, it is completely decoupled from the main platform. It consumes events containing public, semantic identifiers (`term_keys`) and processes them against its own internal data, maintaining a self-contained and highly scalable analytical environment.

## 2. Design Principles

### 2.1. True Decoupling via Public Contracts
This service **must not** have any knowledge of the internal database IDs of other services. It operates exclusively on public, semantic `term_keys` received in event payloads. An internal `insight_topics` collection is maintained by consuming `TaxonomyTermCreated` events, allowing the service to resolve a `term_key` to its own local primary key.

### 2.2. Purely Event-Driven
The service is a pure event consumer. It subscribes to business events from the main platform and translates them into consequences (e.g., awarding points) based on a set of `insight_rules`. It never initiates queries against other services' databases.

## 3. Detailed Collection Schemas

### 3.1. `insight_models`
* **Purpose:** Defines the dimensions and levels for a specific type of insight model.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "name": "String",
      "type": "String", // "skill", "risk"
      "dimensions": [ { "key": "string", "name": "String" } ],
      "levels": [ { "name": "String", "min_points": "Number" } ],
      "updated_at": "Date"
    }
    ```

### 3.2. `insight_topics`
* **Purpose:** The service's internal, self-contained mirror of the platform's taxonomy terms.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "term_key": "String", // The public contract key. e.g., "subject:calculus"
      "model_type": "String", // "skill", "risk"
      "name": "String", // "Calculus"
      "created_at": "Date"
    }
    ```

### 3.3. `insight_rules`
* **Purpose:** The rulebook that maps a platform trigger to a consequence for a specific topic within this service.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "account_id": "ObjectId()",
      "trigger_type": "String", // "learning_object_completion"
      "trigger_id": "ObjectId()", // The platform's internal ID for the learning object
      "topic_id": "ObjectId()", // The internal _id from this service's insight_topics collection
      "dimension_key": "String",
      "points": "Number",
      "created_at": "Date"
    }
    ```

### 3.4. `user_insight_profiles`
* **Purpose:** Stores the consolidated progress of each user for each topic.
* **Structure:**
    ```json
    {
      "_id": "ObjectId()",
      "user_id": "ObjectId()",
      "topic_id": "ObjectId()", // Refers to this service's insight_topics
      "progress_by_dimension": {
        "theory": { "points": 550, "current_level_name": "Gold" }
      },
      "updated_at": "Date"
    }
    ```