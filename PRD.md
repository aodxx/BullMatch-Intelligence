# Product Requirements Document — BullMatch Intelligence

Version: 0.1 (Foundation)
Status: Draft / Phase 0

## 1. Product Vision

BullMatch Intelligence is a historical sports-data intelligence system for bull-match competitions. It collects, verifies, stores, searches, and analyzes bull profiles, camps, venues, events, matches, results, and supporting evidence.

The long-term product should reduce manual data entry through scheduled AI-assisted collection while preserving enough provenance for humans to verify where each fact came from.

## 2. Core Product Principle

The platform must distinguish between:

- information discovered on the internet or submitted by users
- AI-extracted candidate facts
- reviewed/verified facts
- published statistics

Only verified/published data should feed authoritative public statistics by default.

## 3. Primary Users

### Administrator / Data Operator

Can manage bulls, camps, venues, sources, matches, evidence, review cases, and corrections.

### Reviewer

Can inspect AI-proposed information and evidence, resolve duplicates/conflicts/entity matches, approve or reject candidates, and document corrections.

### Viewer

Can search and view verified profiles, match history, statistics, rankings, and analytics.

### Automated Agent

Can discover permitted sources, ingest new source items, extract structured candidate data, match entities, detect duplicates/conflicts, and create review work. Automated agents do not bypass verification policy.

## 4. Core Domain

The system must support at least:

- Bulls
- Bull aliases
- Owners
- Camps
- Venues
- Events
- Matches
- Match participants
- Historical match-time attributes
- Match results
- Sources
- Source items
- Evidence
- AI extraction runs
- Entity match candidates
- Duplicate candidates
- Verification/review cases
- Review actions
- Audit history
- Agent runs

## 5. Bull Profile Requirements

A bull profile should support, when known:

- stable system ID
- name
- aliases / alternate spellings
- image(s)
- birth date or estimated age
- color/appearance descriptors
- breed/lineage information
- current camp/owner
- geographic association
- status (active/retired/etc.)
- notes

Historical values must not be overwritten when they matter to a past match. For example, match-time weight should remain attached to that match.

## 6. Match Requirements

A match should support:

- stable match ID
- event
- venue
- date/time (with precision/unknown handling)
- match order/number when known
- participants
- match-time participant attributes such as weight/age when known
- result
- winner/loser or draw/no-result/cancelled
- duration when known
- finish/result detail when known
- evidence links
- verification state

## 7. Search & Profile MVP

Users should eventually be able to:

- search bulls by name or alias
- filter by camp, owner, province/area, venue, result, date range
- open a bull profile
- see total matches, wins, losses, draws, and win rate
- see recent form
- see chronological match history
- open opponent profiles
- inspect supporting source/evidence on reviewed/admin surfaces

## 8. Data Collection Requirements

The system must support connectors rather than one monolithic scraper.

Potential connector categories include, subject to access and platform rules:

- public websites
- official/public result pages
- RSS/feeds
- sitemaps
- search discovery
- YouTube metadata/transcripts where permitted
- supported APIs
- operator-submitted URLs/text/images

Each connector must preserve provenance and retrieval metadata.

## 9. AI Extraction Requirements

AI extraction must produce structured candidate data, not directly edit published statistics.

Candidate output should include:

- proposed entities
- proposed match facts
- source/evidence references
- confidence per relevant claim
- extraction model/version metadata
- unresolved fields

## 10. Entity Resolution Requirements

The system must handle the same bull being referred to by different names/spellings.

Entity resolution should consider multiple signals where available, including:

- normalized name
- known aliases
- camp/owner
- geography
- opponent/date/event relationships
- lineage/physical metadata
- historical context

Uncertain matches must be represented as candidates for review instead of silently merging records.

## 11. Duplicate Detection Requirements

Multiple sources may describe the same match.

The system must attempt to associate evidence with an existing match rather than create a duplicate match whenever match identity is sufficiently supported.

Potential duplicate cases must be reviewable.

## 12. Verification & Conflict Requirements

If sources disagree on important facts, the system must preserve the conflict.

A review case should support:

- competing candidate values
- evidence for each candidate
- source metadata
- confidence/rationale
- reviewer decision
- reviewer notes
- audit trail

## 13. Daily Automation Requirements

The architecture must support scheduled collection runs.

Each run should record:

- agent/connector name and version
- start/end timestamps
- sources attempted
- items discovered
- items ingested
- extraction/review outcomes
- errors/retries
- cost/usage metadata where feasible

A daily report should summarize new verified data, pending reviews, conflicts, duplicates, failures, and source health.

## 14. MVP Boundary

The first operational MVP should prioritize trustworthy data over broad source coverage.

MVP includes:

1. admin authentication/roles
2. bull/camp/venue management
3. manual verified match entry
4. bull profile + basic statistics
5. source registry
6. raw evidence ingestion
7. review queue
8. one compliant automated source connector
9. AI structured extraction for that connector
10. scheduled daily run

MVP does not require every social platform connector.

## 15. Non-Functional Requirements

### Data Integrity

- stable IDs
- migrations for schema changes
- evidence/provenance preservation
- auditable corrections
- idempotent ingestion where feasible

### Security

- no credentials in Git
- least-privilege database/API access
- admin/reviewer authorization
- protected service credentials

### Maintainability

- versioned shared contracts
- isolated connectors
- clear agent boundaries
- multi-agent development workflow

### Observability

- agent run history
- ingestion error records
- source health
- review backlog metrics

## 16. Success Measures

Initial success is not measured only by number of collected records.

Important measures include:

- verified match count
- percentage of collected items correctly deduplicated
- entity-resolution precision
- review workload per verified match
- evidence completeness
- connector success/failure rate
- time from discovery to verified record

## 17. Product Safety / Integrity Rule

The system must not present an AI-generated prediction or inference as a historical fact. Historical facts, derived statistics, and predictive analysis must remain distinguishable in both data model and UI.
