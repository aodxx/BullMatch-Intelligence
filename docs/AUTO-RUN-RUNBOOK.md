# BullMatch Intelligence — Autonomous Run Runbook

Status: **ACTIVE**
Owner: Primary Maintainer
Task: `BMI-OPS-003`
Last updated: 2026-09-06

## 1. Purpose

This runbook is the continuity contract for scheduled autonomous development runs. Each run must be able to wake up, understand the latest repository state, choose the next safe piece of work, execute it, validate it, and leave a precise handoff for the next run without requiring the project owner to type “continue”.

The runbook does not authorize unsafe shortcuts, unreviewed production-data fabrication, secret exposure, direct community writes into canonical history, or gambling transaction features.

## 2. Required startup reads

At the start of every autonomous run, read in this order:

1. `AGENTS.md`
2. `PROJECT_STATUS.md`
3. `TASKS.md`
4. `docs/AUTO-RUN-RUNBOOK.md`
5. `docs/TEAM-WORKFLOW.md`
6. `PRD.md`
7. `docs/THAI-BULLFIGHTING-DOMAIN-MODEL.md`
8. the latest relevant PR/branch/task handoff

Before editing, verify that the intended task is not already owned by another active branch or contributor.

## 3. Product direction that must persist across runs

BullMatch Intelligence is being re-centered as three connected layers:

### Layer A — Community Data Network
People in the Thai bullfighting ecosystem can contribute observations, corrections, programs, results, photos, links, identity evidence, lineage claims, venue information and local knowledge.

Community users submit claims and evidence. They do **not** directly overwrite canonical historical records.

### Layer B — Verified BullMatch Big Data
AI-assisted extraction, entity resolution, duplicate detection, evidence linkage, contributor reputation, community review and controlled verification convert community/source submissions into trustworthy facts.

Canonical truth is evidence-backed and auditable. Conflicts remain visible until resolved.

### Layer C — Intelligence Products
Verified data supports bull profiles, opponent history, matchup analysis, style observations, lineage, venue/camp analytics, evidence confidence, advanced reports, APIs and B2B tooling for camps, venues, media and data partners.

The strategic asset is the verified data network and knowledge graph, not a generic win/loss form.

## 4. Legal and product boundary

BullMatch is a data, statistics, research, historical-record and analytics platform.

It must not become a bet-taking service, bookmaker, wallet, stake collection service, odds settlement engine, payout system or gambling transaction intermediary unless a separately reviewed lawful product scope is explicitly approved in the future.

Financial labels seen in public match programs may be preserved as source-observed archival metadata with provenance, not as transaction instructions.

## 5. Domain rules that must shape implementation

Never reduce the domain to `Bull A + Bull B + Winner`.

The system must be able to evolve toward modeling:

- stable bull identity independent of display name
- aliases and historical naming
- physical/color/marking/horn observations
- fighting-style / `ทางชน` observations with evidence
- lineage claims and provenance
- owner/camp/keeper relationships over time
- comparison day / `วันเปรียบ`
- proposed and rejected pairings
- accepted pairing agreements
- versioned program publication/amendments
- actual match occurrence
- result, duration and reason
- recovery/rest and subsequent history
- venue/event rule versions
- evidence and claim-level verification

Use `docs/THAI-BULLFIGHTING-DOMAIN-MODEL.md` as the baseline. Do not invent regional vocabulary or venue rules where evidence is uncertain.

## 6. Community contribution principles

The target model is:

`Open Contribution -> Evidence -> Atomic Claims -> Entity Resolution -> Corroboration/Review -> Verified Facts -> Published History -> Analytics`

Rules:

- reward quality, not raw submission volume
- contributor reputation is multidimensional, not one global trust score
- reputation may differ by topic, venue, region and evidence quality
- data contribution should be easy, ideally AI-assisted from photos/programs/links with human confirmation
- owner/camp claims can improve profile authority but cannot erase adverse verified history
- rejected or superseded evidence remains auditable where retention policy permits

## 7. Business-model direction

Engineering decisions should preserve optional future monetization through:

- BullMatch Pro advanced analytics
- one-off advanced matchup/data reports
- BullMatch Data API
- venue tools and venue data partnerships
- camp/owner management and official profile tools
- media/data integrations
- relevant sponsorship/advertising compatible with the product boundary

A future `Contribute to Unlock` mechanism may exchange verified high-quality contribution effort for premium access, but should not reward unverified volume.

Do not optimize the product around affiliate gambling acquisition.

## 8. Visual and interaction design mandate

BullMatch must not look like a generic template dashboard or a cute/cartoon bull application.

Mandatory direction:

- use real bull photography and real venue atmosphere where rights/source permit
- do not use cartoon bull icons as the product’s visual identity
- prioritize strong photographic composition, typography, numbers and purpose-built indicators over generic emoji/icon decoration
- bull identity should visually center on the real animal: portrait, markings, horns, profile history and matchup composition
- analytics should feel like high-end sports intelligence / broadcast graphics rather than business-admin cards
- important pages may use layered imagery, motion, depth, cinematic transitions, stat reveals, timelines, matchup transitions and animated data visualization
- motion must improve hierarchy, state awareness or excitement; it must not obscure data or harm usability
- provide reduced-motion behavior and protect mobile performance
- avoid repeating the same card grid, gradient and icon pattern across every screen
- `Matchup Intelligence` should become a flagship visual experience

The design system should include a reusable motion language, image treatment, typography hierarchy, data-visualization grammar and component rules rather than page-by-page improvised effects.

## 9. Autonomous priority order

Unless a newly discovered production/security blocker is more urgent, autonomous runs should follow this order:

### Priority 0 — Safety / production integrity
Fix security, broken production, data-corruption risk or deployment blockers first.

### Priority 1 — `BMI-P1-010` Product Rebaseline v0.3
Update product requirements from operator-centric historical database to Community Data Network + Verified Big Data + Intelligence Products. Incorporate monetization boundaries, contributor value exchange and design mandate.

### Priority 2 — `BMI-P1-011` Database Schema v0.2
Design additive schema changes for community submissions, atomic claims, evidence, temporal affiliations, comparison/pairing/program lifecycle, contributor reputation and future analytics. Do not destructively rewrite working production tables without a migration/compatibility plan.

### Priority 3 — `BMI-P1-012` Contribution & Trust Architecture
Define contribution flow, moderation/review, contributor reputation dimensions, anti-spam/abuse controls, claim verification, owner/camp claim behavior and `Contribute to Unlock` readiness.

### Priority 4 — `BMI-APP-004` Visual Design Rebaseline
Create and implement the real-bull/high-energy sports-intelligence design system: imagery rules, typography, layout, motion, data visual language, responsive behavior and reduced-motion/performance rules.

### Priority 5 — `BMI-P1-008` Review Backend Foundation (re-scoped)
Implement the review backend against the new claim/community model rather than the old operator-only assumptions.

### Priority 6 — Community contribution implementation
Build controlled submission UI/API, evidence upload/reference flows, duplicate/entity suggestions and contributor profile/reputation surfaces.

### Priority 7 — Automated collection pipeline
Proceed with compliant external connectors, extraction and scheduled source collection after the new domain/community contracts are stable.

### Priority 8 — Intelligence products
Build advanced matchup analytics only from sufficiently verified data; expose evidence completeness/confidence rather than presenting weak data as certainty.

## 10. How to choose work inside a run

1. Check for urgent production/security failures.
2. Check the priority list above.
3. Select the highest-priority task whose dependencies are satisfied and which has no active ownership conflict.
4. Claim the Task ID and branch before significant edits.
5. Keep the run focused on one logical task unless that task finishes and the next task is clearly safe to start.
6. Prefer additive, reversible changes.
7. Do not wait for owner confirmation for ordinary implementation details already covered by approved project direction.
8. Do not guess credentials, legal approvals, real-world facts or irreversible business decisions.

## 11. Required validation

Depending on the work performed:

- run TypeScript/lint/tests/build where applicable
- run database migration/rollback/isolation tests when schema/security changes
- verify no secret or personal credential entered Git
- verify production-facing APIs preserve role boundaries
- verify no fabricated bull/match records are inserted as real data
- for UI work, verify mobile layout, loading/error/empty states, reduced motion and performance-sensitive animation behavior
- update relevant documentation when architecture/product behavior changes

Ordinary code/test failures should be investigated and fixed within the same run when feasible.

## 12. End-of-run handoff

Before the run ends, update the repository so the next run can answer these questions without guessing:

- What Task ID is active?
- What was completed?
- What files/migrations/API contracts changed?
- What tests/checks passed or failed?
- Is there a blocker?
- What exact next action should be taken?
- Is there an open PR and what is its state?

Update `TASKS.md` and/or `PROJECT_STATUS.md` when the task state materially changes. Use PR descriptions as canonical implementation handoffs.

A run is successful even if it cannot finish a full task, provided it leaves a tested, coherent state and a precise next action.

## 13. Blocking policy

If blocked by a dependency the autonomous run cannot resolve (for example an unavailable credential, an external account confirmation, a venue-specific fact that requires field validation, or an irreversible product/legal decision):

1. record the exact blocker
2. record what has already been verified
3. identify the minimum owner/external action required
4. continue with another safe non-conflicting task if available
5. do not repeatedly redo the same failed check every hour without new information

## 14. Definition of continuity

The owner should not need to type “ดำเนินการต่อ” for normal forward progress.

Every autonomous run should leave enough state in GitHub for the next run to resume deterministically from the repository rather than relying on chat memory alone.
