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

| Task ID | Work | Owner | Status | Tracking |
|---|---|---|---|---|
| BMI-P0-001 | Repository and collaboration foundation | Primary Maintainer | DONE | root docs + `.github/` |
| BMI-P0-002 | Initial database model | Unassigned | READY | Issue #1 |
| BMI-P0-003 | AI collection and verification contracts | Unassigned | READY | Issue #2 |
| BMI-P0-004 | Product requirements / MVP boundaries | Primary Maintainer | REVIEW | `PRD.md` v0.1 |
| BMI-P0-005 | System architecture | Primary Maintainer | REVIEW | `ARCHITECTURE.md` v0.1 |
| BMI-P0-006 | Source discovery and source registry specification | Unassigned | BLOCKED BY P0-002/P0-003 | planned |
| BMI-P0-007 | Entity resolution strategy | Unassigned | READY | Issue #3 |
| BMI-P0-008 | Human review queue UX specification | Unassigned | READY | Issue #4 |

## Decisions Locked

1. The verified database is the source of truth.
2. AI agents do not write unverified discoveries directly into published statistics.
3. PostgreSQL/Supabase is the primary structured datastore.
4. Google Drive stores project documents, raw supporting files, reports, and exports; it is not the primary relational database.
5. Multiple contributors must use Task IDs and isolated branches.
6. Raw evidence and provenance must survive extraction/review decisions.
7. Entity resolution is a first-class subsystem, not a simple name match.
8. Connector integrations must use shared normalized contracts instead of source-specific writes into verified business tables.

## Collaboration Foundation

Operational files now available:

- `AGENTS.md`
- `TASKS.md`
- `docs/TEAM-WORKFLOW.md`
- `.github/ISSUE_TEMPLATE/task.md`
- `.github/pull_request_template.md`

Google Drive also contains `06_Team-Handoffs` for non-code handoff artifacts when needed.

## Current Blockers

- Supabase project has not yet been selected/created for this project.
- Database schema draft exists but BMI-P0-002 must finalize it before production migrations.
- AI agent draft exists but BMI-P0-003 must finalize shared contracts before collector implementation.
- First real source connectors have not yet been selected and validated for access/compliance.

## Next Integration Gate

Do not start production scraping/collection code until `BMI-P0-002` and `BMI-P0-003` establish the common evidence, source-item, entity candidate, and review contracts.

## Handoff Rule

When another agent joins, assign it an unowned Task ID from `TASKS.md` or the corresponding GitHub Issue. It must not invent a new parallel architecture without first documenting why the existing architecture cannot support its task.
