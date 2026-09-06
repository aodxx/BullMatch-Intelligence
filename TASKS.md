# Task Registry

This file is the high-level project map. GitHub Issues/PRs track execution.

## Phase 0 — Foundation & Architecture — COMPLETE

### BMI-P0-001 — Repository & Collaboration Foundation
Owner: Primary Maintainer
Status: DONE

### BMI-P0-002 — Database Schema v0.1
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #1 / PR #5

### BMI-P0-003 — AI Agent & Verification Contracts
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #2 / PR #6

### BMI-P0-004 — PRD v0.2
Owner: Primary Maintainer
Status: DONE

### BMI-P0-005 — Architecture v0.2
Owner: Primary Maintainer
Status: DONE

### BMI-P0-006 — Source Registry & Connector Contract
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #7 / PR #8

### BMI-P0-007 — Entity Resolution Strategy
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #3 / PR #9

### BMI-P0-008 — Review Queue UX Specification
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #4 / PR #12

### BMI-P0-009 — Shared Supabase Tenancy Adaptation
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #10 / PR #11

### BMI-P0-010 — Phase 0 Sign-off
Owner: Primary Maintainer
Status: DONE
Tracking: Issue #13 / PR #14

---

## Phase 1 — Core Verified Database

### BMI-P1-001 — Shared Supabase Bootstrap
Owner: Primary Maintainer
Status: REVIEW
Tracking: Issue #15

Completed:
- selected/rechecked shared host `aodxx's Project`
- created `bullmatch` and `bullmatch_private` schemas through migration
- created `bullmatch.app_users` linked to shared `auth.users`
- enabled RLS on membership table
- authenticated users can read only their own membership row through RLS
- authenticated browser role has no direct membership write privileges
- `anon`/`authenticated` have no usage on `bullmatch_private`
- future default privileges are private-by-default and service-role accessible
- isolation checks passed
- Supabase Security Advisor passed with no findings
- Supabase Performance Advisor passed with no findings
- migration version recorded: `20260906052726`

Key files:
- `supabase/migrations/20260906052726_bootstrap_bullmatch_shared_tenancy.sql`
- `supabase/tests/p1_001_shared_tenancy_isolation.sql`
- `supabase/P1-001-VERIFICATION.md`

### BMI-P1-002 — Core Database Migrations
Status: READY AFTER P1-001 MERGE

Scope:
- owners/camps/bulls/venues/events + aliases in `bullmatch`
- matches/participants/results in `bullmatch`
- review cases/actions including concurrency/idempotency fields
- source/evidence/agent/candidate/provenance/runtime tables in `bullmatch_private`
- indexes and integrity helpers
- explicit grants/RLS policies
- migration/isolation/integrity tests
- advisors after DDL

### BMI-P1-003 — Seed / Reference Data
Status: BLOCKED BY P1-002

### BMI-P1-004 — Admin Authentication & Roles
Status: BLOCKED BY P1-001/P1-002

### BMI-P1-005 — Bull/Camp/Owner/Venue CRUD
Status: BLOCKED BY P1-002/P1-004

### BMI-P1-006 — Manual Match Entry & Verification
Status: BLOCKED BY P1-002/P1-004

### BMI-P1-007 — Bull Profile & Basic Statistics
Status: BLOCKED BY P1-005/P1-006

### BMI-P1-008 — Review Backend Foundation
Status: BLOCKED BY P1-002/P1-004

Scope:
- review case APIs/domain operations
- idempotent review commands
- optimistic concurrency
- evidence access
- merge/split preview foundation

---

## Phase 2 — First Automated Collection Pipeline

Planned sequence:
- select first permitted source
- implement connector
- raw source item/evidence persistence
- AI structured extraction
- entity matching
- duplicate detection
- verification/review routing
- scheduled daily run
- operator report

## Phase 3 — Multi-Source Expansion

- additional approved connectors
- YouTube metadata/transcripts where permitted
- discovery engine
- multi-source confidence/corroboration
- conflict detection
- daily operations reporting

## Phase 4 — Analytics

- rankings
- head-to-head
- form history
- camp/venue analysis
- historical trends
- natural-language analysis over verified data

## Assignment Rule

A contributor may claim only one READY Task ID at a time unless the primary maintainer explicitly coordinates non-overlapping work.

When a task starts:
1. record owner
2. change status to IN PROGRESS
3. create `agent/<task-id>-...` branch
4. stay inside declared scope
5. run required checks/tests
6. submit PR/handoff
