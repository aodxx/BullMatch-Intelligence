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
| BMI-P0-002 | Initial database model | Primary Maintainer | DONE | Issue #1 / PR #5 |
| BMI-P0-003 | AI collection and verification contracts | Primary Maintainer | DONE | Issue #2 / PR #6 |
| BMI-P0-004 | Product requirements / MVP boundaries | Primary Maintainer | REVIEW | `PRD.md` v0.1 |
| BMI-P0-005 | System architecture | Primary Maintainer | REVIEW | `ARCHITECTURE.md` v0.1 |
| BMI-P0-006 | Source registry and connector contract | Primary Maintainer | DONE | Issue #7 / PR #8 |
| BMI-P0-007 | Entity resolution strategy | Primary Maintainer | IN PROGRESS | Issue #3 |
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
9. Database trust boundary is split between authoritative `public` application data and non-public `private` ingestion/AI/provenance data.
10. Match results are modeled separately from matches/participants so winner references do not create cyclic migration dependencies.
11. Source ingestion uses a deterministic per-source `dedupe_key` as the canonical idempotency boundary.
12. Public statistics exclude unverified, review-required, conflict, rejected, or unpublished matches by default.
13. Shared agent payloads are versioned JSON contracts under `packages/contracts/`.
14. External source content is untrusted data and cannot instruct agents to reveal secrets, bypass verification, or alter system configuration.
15. Confidence values are advisory and task-specific; conflicts are preserved instead of averaged away.
16. Source policy approval and operational health are separate states.
17. Connector runtime cursor advances only after a safe ingestion checkpoint is committed.
18. Connectors own deterministic source-native dedupe keys; AI extraction never defines source item identity.
19. Connector credentials are resolved at runtime from secret storage and are never persisted in source registry payloads.

## Completed Gates

- `BMI-P0-002` Database Schema — PR #5
- `BMI-P0-003` AI Contracts — PR #6, contract CI passed
- `BMI-P0-006` Source Registry / Connector Contract — PR #8, contract CI passed

## Current Work — Entity Resolution

`BMI-P0-007` defines how Thai names, alternate spellings, camps, owners, locations, opponents, event context, and negative signals combine to propose a canonical identity without silently merging different bulls.

## Current Blockers

- Supabase project has not yet been selected/created for this project.
- The first real production source has not yet been selected and validated for access/compliance.

## Parallel-Ready Task

`BMI-P0-008` Review Queue UX Specification remains available for another contributor and must consume the merged review/entity contracts.

## Next Integration Gate

Complete `BMI-P0-007`, then finalize the Review Queue UX and reconcile PRD/Architecture before Phase 1.

## Handoff Rule

When another agent joins, assign it an unowned Task ID from `TASKS.md` or the corresponding GitHub Issue. It must not invent a new parallel architecture without first documenting why the existing architecture cannot support its task.
