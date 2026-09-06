# AGENTS.md — Collaboration Rules

This file is mandatory reading for every AI agent and developer working in this repository.

## 1. Authority

- The project owner defines product intent.
- The primary maintainer coordinates architecture, task allocation, integration, and release readiness.
- Contributors implement only assigned Task IDs unless explicitly asked to review or unblock another task.

## 2. Before Starting Any Work

Every contributor must:

1. Read `README.md`.
2. Read `PROJECT_STATUS.md`.
3. Read `TASKS.md`.
4. Read `docs/TEAM-WORKFLOW.md`.
5. Confirm the Task ID is not already owned by another contributor.
6. Identify files expected to change before editing.

Do not start untracked work.

## 3. Task IDs

Format:

`BMI-P<phase>-<number>`

Examples:

- `BMI-P0-001` — project architecture
- `BMI-P0-002` — database schema
- `BMI-P1-001` — first source connector

A Task ID has exactly one active owner at a time.

## 4. Branch Rules

Contributors must work on a dedicated branch:

`agent/<task-id>-short-description`

Example:

`agent/bmi-p0-002-database-schema`

Do not push contributor work directly to `main` unless the primary maintainer explicitly authorizes it.

## 5. File Ownership and Collision Prevention

Before changing a shared file such as `PRD.md`, `ARCHITECTURE.md`, `PROJECT_STATUS.md`, or database migrations:

- Check active tasks first.
- Avoid editing the same shared file from two branches simultaneously.
- If the change crosses another task boundary, document the dependency and stop before conflicting work.

No contributor may silently rewrite another contributor's work.

## 6. Required Handoff

Each completed task must state:

- Task ID
- What changed
- Files changed
- Tests/checks run
- Known limitations
- Follow-up tasks
- Migration or configuration impact

The PR body is the canonical handoff record.

## 7. Pull Request Rules

A PR should contain one logical Task ID whenever possible.

PR title format:

`[BMI-P0-002] Define initial database schema`

Before merge:

- scope matches the Task ID
- no unrelated refactors
- docs updated when architecture or behavior changes
- tests/build checks pass when code exists
- migrations are reversible or clearly documented
- secrets are never committed

## 8. Data Integrity Rules

AI-collected information is not automatically trusted.

Never bypass the required data states:

`DISCOVERED -> EXTRACTED -> UNVERIFIED/REVIEW_REQUIRED -> VERIFIED -> PUBLISHED`

Conflicts must be preserved as `CONFLICT`; do not choose a winner merely to complete ingestion.

Never delete source evidence just because an extraction was rejected.

## 9. Entity Resolution Rules

Do not merge two bulls, camps, venues, owners, or events solely because their names are similar.

Any uncertain identity match must remain a candidate with a confidence score and review status.

Verified aliases may be used to improve future matching.

## 10. Source Compliance

Each connector must respect the source platform's permissions, APIs, rate limits, and applicable terms.

A connector must record source URL/identifier, retrieval timestamp, extraction version, and evidence reference where available.

## 11. Database Rules

- PostgreSQL/Supabase is the primary structured datastore.
- Use migrations for schema changes.
- Do not edit production schema manually without a migration record.
- Use stable IDs instead of names as foreign keys.
- Match-time attributes such as weight and age must be stored as historical snapshots when known.

## 12. Secrets

Never commit:

- API keys
- Supabase service-role keys
- tokens
- passwords
- private credentials

Use environment variables and repository/platform secret stores.

## 13. Definition of Done

A task is not complete merely because code was written.

It is complete only when implementation, relevant tests, documentation, handoff, and status updates agree.
