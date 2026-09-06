# Team Workflow

BullMatch Intelligence is intentionally structured so several AI agents or developers can contribute without overwriting one another.

## Roles

### Project Owner
Defines business intent and approves major product direction.

### Primary Maintainer
Owns architecture coherence, task allocation, integration order, and release readiness.

### Contributors / AI Agents
Implement explicitly assigned Task IDs inside isolated branches.

### Reviewer
Reviews scope, architecture impact, data integrity, tests, and handoff completeness.

One person/agent may hold more than one role, but task ownership rules still apply.

## Standard Workflow

1. Read `PROJECT_STATUS.md` and `TASKS.md`.
2. Select a READY unowned Task ID.
3. Record ownership before implementation.
4. Create branch `agent/<task-id>-<short-description>`.
5. Work only inside declared scope.
6. Run relevant tests/build/validation.
7. Update documentation if behavior or architecture changed.
8. Open a PR using the repository template.
9. Reviewer checks collisions, dependencies, migrations, and acceptance criteria.
10. Merge only after the task handoff is complete.
11. Update `PROJECT_STATUS.md` and task state.

## Collision Rules

### Shared control files

The following files are integration-sensitive:

- `PROJECT_STATUS.md`
- `TASKS.md`
- `PRD.md`
- `ARCHITECTURE.md`
- `AGENTS.md`
- database migration files

Only one active task should own a significant rewrite of the same shared section at a time.

### Code ownership by area

As implementation grows, task scopes should favor separate areas:

- `apps/web/` — web UI
- `agents/connectors/` — collection connectors
- `agents/extraction/` — structured extraction
- `agents/resolution/` — entity resolution
- `agents/verification/` — confidence/conflict logic
- `supabase/migrations/` — database migrations
- `packages/contracts/` — shared schemas/contracts

Changes to shared contracts require explicit dependency notes because they may affect many teams.

## Task Claim Format

When starting a task, record:

```text
Task: BMI-P0-002
Owner: <agent/developer>
Status: IN PROGRESS
Branch: agent/bmi-p0-002-database-schema
Files/Areas: docs/DATABASE-SCHEMA.md, supabase/
Dependencies: BMI-P0-004
```

## Handoff Format

Every handoff must contain:

```text
Task ID:
Summary:
Files changed:
Database/migration impact:
API/contract impact:
Tests/checks performed:
Known limitations:
Open questions:
Recommended next task:
```

## Architecture Decision Rule

Contributors must not independently introduce a competing framework, database, auth provider, scheduling system, or AI pipeline architecture.

If a change to an architectural decision is necessary:

1. document the current constraint
2. explain the proposed alternative
3. list migration cost and affected tasks
4. obtain maintainer decision before implementation

This prevents parallel agents from creating incompatible systems.

## Database Migration Coordination

Only one migration task should modify the same table/relationship set at a time.

Migration PRs must state:
- migration order
- backward compatibility impact
- destructive operations, if any
- rollback/repair approach

No destructive data operation is acceptable merely to make development easier.

## Source Connector Coordination

Each source connector should have a separate Task ID and isolated implementation where possible.

All connectors must emit a shared normalized ingestion envelope rather than writing custom structures directly into business tables.

The shared ingestion contract will contain, at minimum:
- source identifier
- source item identifier/URL
- retrieved timestamp
- published timestamp when known
- raw evidence reference
- normalized text/metadata
- connector name/version
- ingestion status

## AI Agent Coordination

AI agents are pipeline workers, not independent databases.

They communicate through versioned contracts and persisted states. An extraction agent may propose structured entities, but it must not directly publish statistics.

## Status Values

Task status:
- PLANNED
- READY
- IN PROGRESS
- BLOCKED
- REVIEW
- DONE
- CANCELLED

Data status:
- DISCOVERED
- EXTRACTED
- UNVERIFIED
- REVIEW_REQUIRED
- VERIFIED
- CONFLICT
- REJECTED
- PUBLISHED

## Rule for Additional Teams

When a new team joins, do not give it a broad instruction such as “help build the project.” Give it one specific READY Task ID, its allowed files/areas, dependencies, expected deliverable, and definition of done.

That is the main mechanism that keeps multiple agents from duplicating or overwriting work.
