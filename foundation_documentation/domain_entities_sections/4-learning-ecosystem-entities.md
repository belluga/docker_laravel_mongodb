## 4. Learning Ecosystem Entities

- **Course Template**: Prototype configuration describing canonical curriculum structure, required documentation, and assessment strategy. Templates act as the immutable source for cloning new course blueprints.
- **Course Blueprint**: Sellable master structure derived from a template, defining ordered modules, gating rules, learning object placements, and associated requirement sets before cohort instantiation.
- **Cohort**: Live instance of a course blueprint bound to schedule, facilitators, enrollment limits, and branded communications. Cohorts persist a structure snapshot to preserve historical integrity.
- **Structure Snapshot**: Immutable tree captured at cohort creation, containing node identifiers, sequencing, and requirement metadata required to evaluate progress gates and assessments.
- **Drip Schedule Blueprint**: Declarative release map bound to a course template that expresses how nodes unlock over time relative to an initialization rule and pause behavior. Blueprints clone into cohort-specific schedules without mutating the master template while honoring policy-specific pause and resumption modes.
- **Enrollment**: Relationship between an identity actor and a cohort (including anonymous-state account users during trials). Enrollments centralize status hubs, capability access, and links to progress, assessment, and documentation records.
- **Learning Object**: Atomic educational asset (video, reading, activity, assessment placeholder) with polymorphic payload definitions and checkpoint configuration. Objects remain agnostic of placement and reuse across blueprints.
- **Progress Tracker**: Append-only log of per-enrollment node progression capturing timestamps, completion state, and granular metrics emitted by the learning engine.
- **Progress Summary**: Denormalized analytics document aggregating completion percentage, engagement streaks, pacing status, learning profile insights, and cross-engine indicators for rapid UI access.
- **Checkpoint Response**: Immutable record of lightweight interactive elements embedded within learning objects, storing responses, correctness, and behavioral telemetry.
- **Assignment Submission**: Student-provided artifact for subjective assignments, capturing content payload, delivery channel, timestamps, and state machine progression.
- **Submission Review**: Evaluator feedback document linked to an assignment submission, encapsulating grading rubric outcomes, comments, and review audit history.
- **Quiz Template**: Prototype describing attempts, timing, question pools, feedback strategy, and passing rules. Serves as the scaffold for individual quizzes.
- **Quiz**: Immutable assessment assembled from a quiz template with frozen question snapshots, scoring policies, and availability windows.
- **Quiz Attempt**: Historical log of a participant's interaction with a quiz, including answer snapshots, scoring outcomes, completion timestamps, and manual grading flags.
- **Quiz Attempt Allowance**: Adjustment record granting additional attempts or overrides for specific participants while maintaining auditability.
- **Annotation**: Private learner artifact (notes, highlights, bookmarks) anchored to enrollment and node identifiers, preserving context across sessions.
- **Document Requirement Set**: Prototype library of required documents and workflow stages reused across courses and cohorts, mapped to canonical statuses.
- **Student Document**: Lifecycle record of a learner's submission for a specific document requirement, including versioned file uploads, stage transitions, and reviewer notes.
- **Document Conversation**: Communication thread associated with a student document, capturing informal guidance and clarifications exchanged between reviewer and learner.
- **Asset**: Tenant-wide library entry for media objects (video, audio, image, document) referenced by learning, experience, and commerce modules with ownership metadata and storage descriptors.

---

