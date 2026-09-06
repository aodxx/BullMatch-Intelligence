# Product Requirements Document — BullMatch Intelligence

Version: **0.2 — Phase 0 Approved**
Status: **APPROVED FOR PHASE 1 IMPLEMENTATION**

## 1. Product Vision

BullMatch Intelligence is a historical sports-data intelligence system for bull-match competitions. It collects, verifies, stores, searches, and analyzes bull profiles, camps, venues, events, matches, results, and supporting evidence.

The product reduces manual data entry through scheduled AI-assisted collection while preserving enough provenance and human review to explain where each historical fact came from.

The system is designed as a long-lived data platform, not merely a win/loss form.

## 2. Core Product Principle

The platform must distinguish between:

- information discovered from permitted external sources or submitted by operators
- raw evidence/source items
- AI-extracted candidate claims
- entity-resolution/duplicate/verification candidates
- human-reviewed/verified facts
- published statistics

Only verified and published data feeds authoritative public statistics by default.

AI confidence is advisory metadata, not truth.

## 3. Primary Users

### Administrator / Data Operator

Can manage BullMatch members, bulls, camps, owners, venues, sources, matches, evidence/review workflow, corrections, publication and system configuration allowed by role.

### Reviewer

Can inspect AI-proposed information and evidence, resolve duplicates/conflicts/entity matches, approve or reject candidates, and document decisions.

Reviewer decisions use controlled, auditable commands rather than unrestricted client writes to canonical tables.

### Viewer

Can search and view verified/published profiles, match history, statistics, rankings, and analytics permitted by the application.

### Automated Agent

Can discover permitted sources, ingest source items, extract structured candidate data, propose entity matches, detect duplicates/conflicts, assist verification and create review work.

Automated agents never bypass verification/publication policy to create authoritative history.

## 4. Core Domain

The system supports at least:

- Bulls
- Bull aliases
- Owners
- Owner aliases
- Camps
- Camp aliases
- Venues
- Venue aliases
- Events
- Matches
- Match participants
- Historical match-time snapshots
- Match results
- Sources
- Source runtime state
- Source items
- Evidence
- AI extraction runs
- Atomic claims
- Entity match candidates
- Duplicate candidates
- Verification results
- Review cases
- Review actions
- Fact provenance
- Identity merge/split history
- Audit history
- Agent runs

## 5. Bull Profile Requirements

A bull profile should support, when known:

- stable system ID
- canonical name
- aliases / alternate spellings / source labels
- image(s)
- birth date or estimated age with precision
- color/appearance descriptors
- breed/lineage information
- current camp/owner
- geographic association
- active/retired/deceased/unknown status
- notes

Historical facts must not be overwritten by current profile changes. Match-time weight, displayed name, camp, owner and age estimates remain attached to that match.

## 6. Match Requirements

A match should support:

- stable match ID
- event
- venue
- date/time with precision/unknown handling
- match order/number when known
- participants
- match-time participant snapshots
- result type
- winner participant when result is WIN
- draw/no-result/cancelled/unknown states
- duration when known
- result details
- evidence/provenance
- verification state
- publication state

Result integrity must prevent a winner from referring to a participant in another match.

## 7. Search & Profile MVP

Users should be able to:

- search bulls by canonical name or alias
- filter by camp, owner, province/area, venue, result and date range
- open a bull profile
- see total verified/published matches
- see wins, losses, draws and win rate
- see recent form
- see chronological match history
- open opponent profiles

Admin/reviewer surfaces can inspect provenance and evidence; public surfaces show only evidence references intended for public access.

## 8. Data Collection Requirements

The system uses isolated connectors rather than one monolithic scraper.

Initial connector categories may include, subject to access/platform rules:

- public websites
- official/public result pages
- RSS/feeds
- sitemaps
- search discovery
- YouTube metadata/transcripts where permitted
- supported public/authenticated APIs
- operator-submitted URLs/text/images/files

Each connector must:

- be registered in Source Registry
- have explicit policy status and operational health
- respect source/platform permissions and rate limits
- produce the shared normalized ingestion contract
- preserve retrieval/provenance metadata
- generate deterministic source-native dedupe keys
- support retry-safe ingestion

Connector cursor state advances only after a safe persistence checkpoint.

## 9. AI Extraction Requirements

AI extraction produces structured candidate claims, not canonical historical records.

Candidate output includes:

- versioned schema identifier
- proposed entities
- proposed match facts
- explicit/inferred/unknown basis
- source/evidence references
- confidence per relevant claim
- model/provider/version metadata
- unresolved fields

Missing facts are never fabricated to complete a record.

External source content is untrusted data and cannot instruct agents to expose secrets, bypass review policy or alter system configuration.

## 10. Entity Resolution Requirements

The same bull may appear under different spellings, prefixes, aliases or source labels. Different bulls may also share similar names.

Entity resolution considers multiple independent signals where available:

- Thai-safe normalized name
- verified aliases or stable source-native mappings
- camp/owner context
- geography
- opponent/date/event relationships
- lineage/physical metadata
- chronology
- prior reviewer decisions

Thai text normalization is for candidate retrieval, not identity proof. Tone marks/vowels and semantic Thai characters are preserved by default.

Bull auto-link is intentionally conservative and requires more than name similarity. Merge/split operations are never automatic.

## 11. Duplicate Detection Requirements

Multiple sources may describe the same real match.

The system attempts to associate new evidence with an existing match instead of creating duplicate canonical matches when identity is sufficiently supported.

Potential duplicates are reviewable.

Confirming a duplicate must preserve new evidence rather than discard it.

## 12. Verification & Conflict Requirements

If sources disagree on important facts, the system preserves the conflict.

A conflict review case supports:

- competing candidate values
- supporting and contradicting evidence
- source/reliability metadata
- confidence/rationale
- reviewer decision or unresolved state
- reviewer notes
- audit history

Confidence scores are never averaged to erase contradictory evidence.

Important unresolved conflicts remain excluded from authoritative statistics.

## 13. Human Review Requirements

The Review Queue is the safety boundary between candidate data and authoritative history.

Reviewers must see evidence and impact before state-changing actions.

Required review flows include:

- new match
- new entity
- possible same bull/entity match
- possible duplicate match
- conflicting result/date
- low confidence or missing important fact
- data-quality finding
- source approval
- merge/split identity operations

Review commands are:

- auditable
- idempotent using command IDs
- stale-write safe using optimistic version checks
- role/policy controlled

Merge/split flows require explicit human confirmation, reason, dependency/statistics impact preview and reversible/auditable identity history.

## 14. Daily Automation Requirements

The architecture supports scheduled collection runs.

Each run records:

- agent/connector name/version
- correlation/run ID
- start/end timestamps
- sources attempted
- items scanned/created
- extraction/review outcomes
- errors/retries
- source health
- usage/cost metadata where feasible

A daily operator report should summarize:

- source health
- new source items/candidates
- verified records
- pending review
- conflicts
- possible duplicates
- failed jobs
- data-quality findings

Initial scheduling may use GitHub Actions; job/data contracts remain portable to another worker runtime later.

## 15. Shared Supabase Hosting Requirement

BullMatch currently reuses the existing Supabase free-plan project **`aodxx's Project`** rather than creating a third project.

BullMatch owns dedicated schemas:

- `bullmatch` — canonical application/review data
- `bullmatch_private` — source/AI/evidence/provenance/runtime data

`freshmart` remains outside BullMatch scope.

Supabase `auth.users` is shared project infrastructure. BullMatch membership/authorization is app-scoped through `bullmatch.app_users`.

A person existing in `auth.users` does not automatically receive BullMatch access.

BullMatch migrations must not modify unrelated application schemas/tables and the architecture must remain portable to a future dedicated Supabase project.

## 16. Data API / Security Requirements

- `bullmatch_private` is not exposed to browser clients
- any browser-reachable `bullmatch` table has explicit grants + RLS
- `TO authenticated` alone is not sufficient authorization
- policies verify active BullMatch membership/role where required
- user-editable auth metadata is never used for authorization
- service-role/secret credentials never enter browser code
- privileged review/publish/merge/split operations should be server-mediated
- new tables are not assumed to be automatically exposed through the Data API
- Supabase-managed platform schemas such as `realtime` are not modified by BullMatch

## 17. MVP Boundary

The first operational MVP prioritizes trustworthy data over broad source coverage.

MVP includes:

1. BullMatch admin/reviewer authentication and app-scoped roles
2. bull/camp/owner/venue management
3. manual verified match entry
4. bull profile + basic verified statistics
5. source registry
6. raw evidence/source-item ingestion
7. review queue
8. one compliant automated source connector
9. AI structured extraction for that connector
10. entity/duplicate/verification routing
11. scheduled daily run
12. daily operator report baseline

MVP does not require every social platform connector or predictive analytics.

## 18. Non-Functional Requirements

### Data Integrity

- stable UUID identities
- migration-controlled schema changes
- historical snapshots
- evidence/provenance preservation
- auditable corrections
- retry-safe/idempotent ingestion
- stale-safe/idempotent review commands

### Security

- no credentials in Git
- least-privilege database/API access
- BullMatch-specific membership/authorization
- protected service credentials
- private AI/evidence schema inaccessible from browser clients
- shared-Supabase isolation tests

### Maintainability

- versioned language-neutral contracts
- isolated connectors/provider adapters
- clear agent boundaries
- multi-agent Task ID + branch/PR workflow
- schema namespace ownership

### Observability

- agent run history
- ingestion errors
- source health
- review backlog metrics
- correlation IDs
- database/security advisor checks

### Cost / Free-Plan Awareness

- reuse current Supabase capacity responsibly
- avoid unnecessary large PostgreSQL blobs
- control scheduled job frequency
- monitor storage/database growth
- use deterministic parsing/caching where AI is unnecessary

## 19. Success Measures

Initial success is not measured only by collected-record count.

Important measures include:

- verified/published match count
- evidence completeness
- duplicate-detection precision
- entity-resolution precision
- false auto-link / overturned-link rate
- review workload per verified match
- conflict backlog
- connector success/failure rate
- source health
- time from discovery to verified record
- percentage of automated runs completing without manual recovery

## 20. Product Safety / Integrity Rule

The system must never present an AI-generated prediction, inferred claim or unresolved conflict as verified historical fact.

Historical facts, derived statistics and future predictive/analytical outputs remain distinguishable in data model and UI.

## 21. Phase Plan

### Phase 0 — Foundation & Architecture

**COMPLETE** when this PRD is approved together with:
- Architecture
- Database schema + namespace overlay
- AI contracts
- Source Registry/Connector contract
- Entity Resolution strategy
- Review Queue UX
- team workflow

### Phase 1 — Core Verified Database

Implement:
- shared Supabase namespace bootstrap
- reproducible migrations
- RLS/authorization/isolation tests
- canonical CRUD
- manual verified match workflow
- profile/basic statistics
- review backend foundation

### Phase 2 — First Automated Collection Pipeline

Implement one permitted source end-to-end:

`Source -> Ingestion -> Evidence -> Extraction -> Resolution -> Duplicate/Verification -> Review`

Then schedule daily runs.

### Phase 3 — Multi-Source Expansion

Add more approved connectors, source discovery, multi-source corroboration/conflict handling and daily operations reporting.

### Phase 4 — Analytics

Add rankings, head-to-head, form history, camp/venue analysis, historical trends and natural-language analysis over verified data.
