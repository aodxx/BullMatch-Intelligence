# BullMatch Intelligence

BullMatch Intelligence is a data intelligence platform for collecting, verifying, storing, and analyzing historical bull-match results and related evidence.

## Project Goal

Build a trustworthy historical database of bulls, camps, venues, events, and match results, supported by automated AI agents that collect information from multiple permitted sources every day.

The system is designed around one rule:

> AI may discover and propose data, but only verified data becomes the system's source of truth.

## Core Pipeline

Sources -> Collection -> Raw Evidence -> AI Extraction -> Entity Resolution -> Duplicate Detection -> Verification -> Human Review -> Verified Database -> Analytics

## Main Components

- Web application for search, profiles, match history, review, and analytics
- Supabase/PostgreSQL as the primary structured database
- AI collection and extraction agents
- Source registry and connector layer
- Evidence store and audit trail
- Verification/review workflow
- Scheduled automation using GitHub Actions initially
- Google Drive for project documents, raw supporting files, reports, and exports

## Repository Structure

```text
/
├─ README.md
├─ PRD.md
├─ ARCHITECTURE.md
├─ AGENTS.md
├─ TASKS.md
├─ PROJECT_STATUS.md
├─ docs/
│  ├─ DATABASE-SCHEMA.md
│  ├─ AI-AGENT-SPEC.md
│  └─ TEAM-WORKFLOW.md
├─ .github/
│  ├─ ISSUE_TEMPLATE/
│  │  └─ task.md
│  └─ pull_request_template.md
├─ apps/                 # application code (created in implementation phase)
├─ packages/             # shared packages (future)
├─ agents/               # AI collectors/extractors/verifiers (future)
├─ supabase/             # migrations, policies, seed data (future)
└─ scripts/              # operational scripts (future)
```

## Working Model

This repository is designed for multiple AI agents and developers working simultaneously without overwriting each other's work.

Every unit of work must have a Task ID such as `BMI-P0-001` and an explicit owner before implementation starts.

Read these files before changing the project:

1. `AGENTS.md`
2. `PROJECT_STATUS.md`
3. `TASKS.md`
4. `docs/TEAM-WORKFLOW.md`

## Current Phase

**Phase 0 — Foundation & Architecture**

No production data collector or public analytics feature should be implemented before the Phase 0 data model, source/evidence model, and review workflow are accepted.

## Google Drive

Project workspace: `BullMatch Intelligence`

Drive is used for project control documents, source inventories, raw evidence files, reviewed datasets, and exports. PostgreSQL remains the authoritative structured application database.
