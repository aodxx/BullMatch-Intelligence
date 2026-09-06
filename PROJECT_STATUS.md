# Project Status

Last structural update: 2026-09-06

## Project

**BullMatch Intelligence**

Repository: `aodxx/BullMatch-Intelligence`

Current phase: **Phase 0 — Foundation & Architecture**

Overall status: **IN PROGRESS**

## Phase 0 Exit Criteria

Phase 0 is complete only when all of the following are approved and consistent:

- product scope and MVP are documented
- system architecture is documented
- initial PostgreSQL/Supabase schema is defined
- source/evidence lifecycle is defined
- AI agent responsibilities are defined
- entity resolution strategy is defined
- duplicate/conflict handling is defined
- human review workflow is defined
- team workflow is operational
- initial implementation backlog exists

## Active Work

| Task ID | Work | Owner | Status | Files/Area |
|---|---|---|---|---|
| BMI-P0-001 | Repository and collaboration foundation | Primary Maintainer | IN PROGRESS | root docs, `.github/` |
| BMI-P0-002 | Initial database model | Unassigned | READY | `docs/DATABASE-SCHEMA.md`, `supabase/` |
| BMI-P0-003 | AI collection and verification architecture | Unassigned | READY | `docs/AI-AGENT-SPEC.md` |
| BMI-P0-004 | Product requirements / MVP boundaries | Primary Maintainer | IN PROGRESS | `PRD.md` |
| BMI-P0-005 | System architecture | Primary Maintainer | IN PROGRESS | `ARCHITECTURE.md` |
| BMI-P0-006 | Source discovery and source registry specification | Unassigned | BLOCKED BY P0-002/P0-003 | docs/data model |

## Decisions Locked

1. The verified database is the source of truth.
2. AI agents do not write unverified discoveries directly into published statistics.
3. PostgreSQL/Supabase is the primary structured datastore.
4. Google Drive stores project documents, raw supporting files, reports, and exports; it is not the primary relational database.
5. Multiple contributors must use Task IDs and isolated branches.
6. Raw evidence and provenance must survive extraction/review decisions.
7. Entity resolution is a first-class subsystem, not a simple name match.

## Current Blockers

- Supabase project has not yet been selected/created for this project.
- Initial database schema is not yet committed.
- First real source connectors have not yet been selected and validated for access/compliance.

## Next Integration Gate

Do not start production scraping/collection code until `BMI-P0-002` and `BMI-P0-003` establish the common evidence, source-item, entity candidate, and review contracts.

## Handoff Rule

When another agent joins, assign it an unowned Task ID from `TASKS.md`. It must not invent a new parallel architecture without first documenting why the existing architecture cannot support its task.
