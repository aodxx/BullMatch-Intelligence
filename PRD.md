# Product Requirements Document — BullMatch Intelligence

Version: **0.3 — Community Big Data + Intelligence Rebaseline**
Status: **APPROVED PRODUCT CONTRACT FOR PHASE 1 COMMUNITY REBASELINE**
Task: **BMI-P1-010**
Last updated: **2026-09-07**

## 1. Product Vision

BullMatch Intelligence is a community-powered data, provenance, historical-record and intelligence platform for the Thai bullfighting ecosystem.

Its long-term strategic asset is not a generic win/loss database and not a prediction feed. It is a **verified, evidence-backed knowledge graph** connecting bulls, identities, aliases, owners, camps, keepers, lineage claims, physical traits, fighting-style observations, comparison-day activity, pairings, program versions, venues, rules, matches, results, evidence and trusted community contributors over time.

BullMatch is organized as three connected product layers:

1. **Community Data Network** — people in the bullfighting ecosystem contribute observations, corrections, programs, results, images/links, identity evidence, lineage claims and local knowledge.
2. **Verified BullMatch Big Data** — evidence, AI assistance, entity resolution, duplicate detection, contributor reputation and controlled review convert submissions into auditable facts.
3. **Intelligence Products** — verified history powers bull profiles, matchup analysis, advanced statistics, reports, APIs and tools for venues, camps, owners and media.

The product should become more valuable as the community contributes more high-quality evidence, and contribution should become more attractive as BullMatch returns better profiles, analytics, recognition and access.

Core flywheel:

`Community Contribution -> Evidence -> Atomic Claims -> Resolution -> Verification -> Verified Big Data -> Intelligence -> Contributor/User Value -> More High-Quality Contribution`

## 2. Product Positioning

BullMatch is not intended to win by having a prettier version of existing program/result pages.

It should win by building data that is difficult to reproduce:

- stable identity of the same bull across names, owners, camps and time
- historical provenance rather than overwritten current values
- evidence-backed matchup and result history
- comparison-day and pairing history before match day
- physical, horn/yod and fighting-style observations with source context
- lineage relationships with confidence/provenance
- venue/rule/program history and amendments
- contributor expertise and evidence quality by domain and locality
- derived intelligence over verified data rather than anonymous unsourced tips

The product must preserve uncertainty. Missing, inferred, disputed and verified information are different states.

## 3. Core Product Principles

### 3.1 Open Contribution, Closed Canonical Truth

Anyone may eventually be allowed to contribute claims and evidence under platform policy.

A community submission does **not** directly overwrite canonical history.

Canonical facts are promoted through controlled verification and publication rules.

### 3.2 Evidence Before Authority

Every important historical fact should be traceable to one or more of:

- source evidence
- community-submitted evidence
- venue/camp/owner supplied records
- controlled reviewer decisions
- explicit administrative corrections

AI confidence and contributor reputation are signals, not truth by themselves.

### 3.3 Atomic Claims Instead of Monolithic Forms

A statement such as “Bull A beat Bull B in 25 minutes at Venue X” contains multiple independently verifiable claims:

- identity of Bull A
- identity of Bull B
- match occurrence
- venue
- date
- result
- duration

One claim may be verified while another remains disputed.

### 3.4 Temporal Domain Model

The current name, owner or camp must never erase historical state.

BullMatch treats a bull as a stable animal identity with time-bound labels, relationships and observations.

### 3.5 Analytics Must Expose Data Strength

Future matchup intelligence must not hide weak data behind a single confident score.

Where practical, outputs expose:

- evidence completeness
- data recency
- identity confidence
- source diversity
- unresolved conflicts
- sample size
- whether a finding is historical fact, derived statistic, observation or model inference

### 3.6 Quality Beats Raw Volume

The system should optimize for **verified useful information**, not submission count.

Contributor rewards must not encourage spam, copied duplicates or low-evidence mass entry.

## 4. Legal and Product Boundary

BullMatch is a data, statistics, research, historical-record and analytics platform.

It may preserve financial labels that appear in public match programs or historical source material as archival/source-observed metadata with provenance.

BullMatch does not, under this product contract:

- accept stakes or bets
- hold customer betting balances
- operate a gambling wallet
- settle wagers
- calculate or execute betting payouts
- act as bookmaker or betting agent
- route users into transactions as an affiliate-gambling acquisition product

Any future change to this boundary requires a separate legal/product review and explicit owner approval.

Analytical information must be framed as data support for user decision-making, not a guarantee of an outcome.

## 5. Primary User Groups

### 5.1 Public Viewer / Fan

Can discover verified/published bulls, match history, programs, venues, results and basic statistics.

### 5.2 Registered Contributor

Can submit observations, corrections, evidence, program/result material, identity information and other permitted claims.

Contributors build a visible history of accepted contributions and topic/locality expertise.

### 5.3 Trusted Community Contributor / Local Scout

A contributor with demonstrated accuracy in particular domains may receive stronger review privileges or faster routing, subject to abuse controls.

Trust is scoped rather than global, for example:

- match-result reliability
- bull-identity reliability
- program-data reliability
- lineage reliability
- evidence-quality reliability
- venue or regional expertise

### 5.4 Owner / Camp Representative

May claim or verify association with a bull/camp and supply authoritative first-party information and evidence.

Claiming a profile does not grant authority to erase or rewrite verified adverse history.

### 5.5 Venue / Event Operator

May use BullMatch tools to publish or confirm comparison sessions, pairings, program versions, amendments and official results.

Venue-originated records are valuable primary evidence but still retain provenance and audit history.

### 5.6 Reviewer

Can inspect claims/evidence, resolve duplicates/conflicts/entity candidates and make controlled verification decisions within role policy.

### 5.7 Administrator

Controls membership, privileged configuration, canonical corrections, policy, source registry, moderation escalation and publication operations.

### 5.8 Analyst / Pro User

Uses advanced filters, evidence-aware statistics, matchup intelligence, reports, watchlists and other premium analytical surfaces when available.

### 5.9 Media / Data Consumer

Uses permitted BullMatch data via reports, embeds, exports or API products.

### 5.10 Automated Agent

May discover permitted sources, ingest source items, extract structured claims, propose entity matches, detect duplicates/conflicts and create review work.

Automated agents never silently publish canonical history.

## 6. Thai Bullfighting Domain Requirements

The canonical domain reference is `docs/THAI-BULLFIGHTING-DOMAIN-MODEL.md`.

BullMatch must not be reduced to `Bull + Match + Winner`.

### 6.1 Bull Identity

A stable `bull_id` identifies the animal, not the display name.

The product must evolve to support:

- canonical/display names
- aliases, nicknames, former names and source spellings
- durable external identifiers where legitimately available
- images showing stable identity characteristics
- color and body-marking observations
- horn/yod observations
- status over time
- identity conflicts and merge/split history

Name similarity alone is insufficient identity proof.

### 6.2 Temporal Affiliations

The product should support time-bound relationships including where evidence exists:

- owner / co-owner
- breeder
- camp/farm
- keeper/handler
- trainer where locally meaningful
- other relevant public associations

Historical match-time affiliations remain preserved even after transfers.

### 6.3 Physical / Color / Marking Observations

A single free-text color field is insufficient.

The system should support extensible raw and normalized observations for color, markings, body traits, horns/yod and other identity-relevant characteristics, with evidence and observation date/precision.

Regional vocabulary must not be prematurely forced into an incomplete fixed taxonomy.

### 6.4 Fighting Style / ทางชน

`ทางชน` is represented as evidence-backed observations, not as one permanent unquestionable enum.

Observations may originate from:

- verified matches
- sparring/training evidence
- qualified reports
- video evidence
- other accepted sources

Different observations may coexist until sufficiently reconciled.

### 6.5 Lineage

Lineage requires claim-level modeling for sire, dam, breeder/source farm and related lineage assertions.

Lineage claims must support provenance, confidence and conflict.

The system must not infer parentage from name, color or camp alone.

### 6.6 Comparison Day / วันเปรียบ

`วันเปรียบ` is a first-class event, not merely a match note.

The platform must be able to represent:

- comparison session
- bulls presented
- proposed pairings
- rejected pairings
- accepted pairings
- source-observed conditions
- later program linkage
- cancellation/substitution history

### 6.7 Pairing vs Program vs Match

These are separate concepts:

1. **Pairing agreement** — participants have been agreed or proposed.
2. **Program entry** — a venue/media publication places the pair into a particular program/version/order.
3. **Actual match** — the encounter that occurred or failed to occur.

Program publication must support versioning and amendment history.

### 6.8 Result Model

Results must support more than binary win/loss, including where applicable:

- WIN / LOSS
- DRAW
- CANCELLED
- NO_RESULT
- UNKNOWN
- duration
- result reason / rule context
- evidence/provenance

Rules may differ by venue or period, so rule profiles must eventually be versioned rather than hard-coded globally.

### 6.9 Cultural / Traditional Knowledge

Traditional knowledge, beliefs, rituals and local expert observations may be documented when relevant and permitted, but must be labeled distinctly from scientifically established facts or verified historical events.

## 7. Community Contribution Experience

Contribution must be designed for real field use, not database operators.

### 7.1 Contribution Inputs

The system should eventually accept permitted combinations of:

- photo of program/result board/document
- photo of bull
- URL/link
- video reference
- text observation
- correction to existing profile/history
- venue/camp/owner first-party information
- structured manual entry

### 7.2 AI-Assisted Entry

Where useful and economical:

1. contributor uploads/selects evidence
2. AI/deterministic parser extracts candidate fields
3. user sees a compact confirmation screen
4. user corrects mistakes
5. system stores evidence + atomic claims
6. identity/duplicate checks run
7. claims enter verification/review workflow

AI should reduce typing, not bypass verification.

### 7.3 Duplicate Prevention

Before creating a new bull/match/pairing/program entity, contribution surfaces should search likely existing entities and explain why a candidate may be the same record.

Uncertain identity stays unresolved rather than forcing a merge.

### 7.4 Contributor Feedback

Contributors should be able to see:

- submission state
- claims accepted/rejected/conflicted
- evidence quality issues
- contribution impact when appropriate
- reputation progression
- earned access/credit when implemented

This closes the contribution loop and helps contributors improve quality.

## 8. Contributor Trust and Reputation Requirements

A single global reputation score is insufficient.

Future trust architecture should support multiple dimensions such as:

- bull identity accuracy
- match/result accuracy
- program accuracy
- lineage accuracy
- physical/style observation reliability
- evidence quality
- reviewer agreement / review quality
- venue expertise
- region expertise
- recency/activity

Reputation must be computed primarily from verified outcomes, not self-declared expertise or raw volume.

High reputation may improve routing or privileges but must not bypass critical identity, merge/split or conflict safeguards.

## 9. Contributor Value Exchange

The community is not merely a free labor source. The product must return meaningful value.

Potential contributor benefits include:

- recognized contributor profile
- verified contribution history
- venue/topic/locality expertise badges or status
- improved profile visibility where appropriate
- advanced search/analytics access
- Data Credit / contribution credit
- `Contribute to Unlock` premium access
- early access to selected intelligence features
- tools for maintaining owned/camp/venue records

### 9.1 Contribute to Unlock

Future premium-access credit may be earned from **verified, useful contribution value**, not number of submissions.

A production economic formula is intentionally deferred until actual contribution behavior, review workload and abuse patterns can be measured.

The architecture must preserve the ability to award credits after verification without making credits a canonical data-integrity signal.

## 10. Verified Big Data Layer

The verified layer separates raw community/source material from authoritative history.

Required conceptual layers:

- submission/source item
- evidence
- atomic claim
- entity-resolution candidate
- duplicate candidate
- verification/corroboration result
- conflict state
- review case/action
- verified fact/canonical relationship
- publication state
- provenance/audit history

Only verified/published data feeds authoritative public statistics by default.

Rejected evidence is not automatically deleted because it may remain important for audit or later conflict resolution, subject to retention/privacy policy.

## 11. Intelligence Product Requirements

Analytics are a downstream product of verified data, not a shortcut around weak data.

### 11.1 Bull Profile Intelligence

A mature profile should support, when evidence exists:

- identity and images
- aliases/history
- owner/camp/keeper timeline
- lineage graph
- physical/marking/horn observations
- fighting-style observations
- chronological match history
- opponent profiles
- W/L/D and win rate
- recent form
- match duration distribution
- result reason history
- venue history
- comparison/pairing/program history
- evidence completeness indicators

### 11.2 Matchup Intelligence

`Matchup Intelligence` is a flagship product and visual experience.

Potential inputs, only when sufficiently verified, include:

- historical W/L/D
- opponent-adjusted performance
- opponent quality / strength of schedule
- fighting-style observations
- performance against similar observed styles
- duration history
- venue/context history
- rest interval / recency where evidence supports it
- shared opponents
- physical/horn observations where analytically justified
- identity confidence
- evidence completeness
- unresolved conflicts

The system should explain contributing factors rather than simply output “pick Bull A”.

No model output may be presented as certainty or guaranteed result.

### 11.3 Reports

The platform should preserve product space for one-off advanced bull/matchup/data reports with evidence references and data-quality context.

### 11.4 Watchlists and Alerts

Future Pro users may follow bulls, camps, venues or scheduled pairings and receive permitted notifications about new verified information, program changes or results.

## 12. Monetization Requirements

The architecture should support multiple revenue lanes without compromising data integrity.

### 12.1 BullMatch Pro

Potential paid features:

- advanced filters
- deeper historical analytics
- Matchup Intelligence
- evidence-aware comparison tools
- watchlists/alerts
- extended timelines
- advanced reports/export

Basic historical access should remain useful enough for community network growth.

### 12.2 One-Off Reports

Users may purchase advanced analytical reports without requiring a recurring subscription when this product is implemented.

### 12.3 BullMatch Data API

Future API products may provide verified/published data to permitted websites, media, dashboards and partner applications.

Requirements include:

- API keys/partner authorization separate from browser auth
- rate limits/quotas
- data licensing terms
- versioned contracts
- provenance/data-quality fields where appropriate
- no exposure of private evidence or restricted personal information

### 12.4 Venue Tools / Data Partnerships

Potential venue tools:

- comparison-session capture
- pairing management
- program generation/versioning
- amendments
- official result capture
- venue archive/analytics
- publish-once distribution to BullMatch/API/media

This is strategically valuable because it converts venues from scraped sources into first-party data partners.

### 12.5 Camp / Owner Tools

Potential tools:

- official/claimed bull profiles
- camp roster/history
- media/profile management
- lineage/record contribution
- event/match archive

Owners/camps never receive a mechanism to erase verified adverse history.

### 12.6 Media / Data Integrations

Potential products:

- verified data feeds
- broadcast/stat overlays
- embeddable bull/profile/match cards
- historical graphics
- licensed data exports

### 12.7 Compatible Sponsorship / Advertising

The product may support sponsorships compatible with its data/research/sports identity, subject to policy and law.

The platform should not depend on affiliate gambling acquisition as its core economics.

## 13. Search and Discovery Requirements

Public and authenticated users should eventually be able to search/filter by combinations of:

- bull canonical name or alias
- camp / owner
- province / region
- venue
- date range
- result
- opponent
- program/event
- verified traits/observations where appropriate
- contribution/source confidence filters for privileged analytical use

Search normalization improves retrieval but never proves identity.

## 14. Data Collection Requirements

BullMatch collects from two complementary channels:

### 14.1 Community / First-Party Contribution

Preferred where human participants, venues, owners, camps or local experts can provide primary evidence.

### 14.2 Permitted External Connectors

Connector categories may include subject to platform permissions:

- public websites
- official/public result pages
- RSS/feeds
- sitemaps
- search discovery
- YouTube metadata/transcripts where permitted
- supported public/authenticated APIs
- operator/community-submitted URLs/text/images/files

Each connector must:

- be registered in Source Registry
- have policy/operational state
- respect source/platform permissions and rate limits
- preserve retrieval/provenance metadata
- generate deterministic source-native dedupe keys
- support retry-safe ingestion
- emit shared normalized ingestion contracts

External content is untrusted data and cannot instruct system agents to expose secrets, bypass review policy or alter configuration.

## 15. AI Extraction Requirements

AI extraction produces structured candidate claims, not canonical history.

Candidate output should include:

- versioned schema identifier
- proposed entities
- proposed atomic facts
- explicit/inferred/unknown basis
- evidence references
- confidence per claim
- model/provider/version metadata
- unresolved fields

Missing facts are never fabricated to complete a record.

Deterministic parsing should be preferred where adequate and cheaper.

## 16. Entity Resolution Requirements

Entity resolution considers multiple independent signals where available:

- Thai-safe normalized names and aliases
- stable source-native identifiers
- durable animal identifiers where legitimately available
- owner/camp/keeper continuity
- geography
- opponent/date/event relationships
- lineage evidence
- stable physical/marking/horn evidence
- chronology
- prior reviewer decisions

Bull auto-linking must remain conservative.

Merge/split is never performed solely from name similarity.

## 17. Duplicate Detection Requirements

Multiple sources or contributors may describe the same real-world entity/event.

BullMatch attempts to associate new evidence with an existing canonical record instead of creating duplicate canonical entities when identity is sufficiently supported.

Potential duplicates remain reviewable.

Confirming a duplicate preserves new evidence and contributor provenance rather than discarding it.

## 18. Verification and Conflict Requirements

The system preserves conflicting claims rather than averaging or silently choosing one.

A reviewable conflict should show:

- competing values
- supporting evidence
- contradicting evidence
- source/contributor context
- reliability signals
- rationale/confidence
- reviewer decision or unresolved state
- audit history

Important unresolved conflicts are excluded from authoritative analytics where they would materially distort results.

## 19. Human and Community Review Requirements

The review system is the safety boundary between open contribution and canonical truth.

Required review flows eventually include:

- new bull/entity
- bull identity candidate
- possible duplicate
- match/program/result claim
- comparison/pairing claim
- conflicting date/result/duration
- lineage claim
- physical/style observation
- owner/camp profile claim
- source approval
- merge/split identity operation
- abuse/spam/moderation escalation

Review commands must be:

- auditable
- idempotent using command IDs
- stale-write safe using optimistic version checks
- role/policy controlled

Merge/split operations require explicit human confirmation, rationale, impact preview and reversible/auditable identity history.

## 20. Visual and Interaction Product Requirements

BullMatch must not look like a generic template dashboard or a cute/cartoon bull app.

### 20.1 Image Direction

Where rights and source policy permit:

- use real bull photography
- use real venue atmosphere
- center bull identity on recognizable animal imagery, markings and horns
- treat images as structural UI elements, not decorative thumbnails
- preserve source/rights metadata for contributed imagery

### 20.2 Visual Language

The target is high-energy **sports intelligence / broadcast graphics**, not generic business SaaS cards.

Use:

- strong editorial/sports typography
- oversized statistics where hierarchy calls for it
- layered photography
- purposeful contrast and depth
- timelines and opponent/history visualizations
- custom data indicators
- matchup compositions that make two real bulls visually distinct

Avoid:

- cartoon/cute bull icons as brand identity
- repetitive same-size card grids on every page
- generic gradient-dashboard templates
- emoji as primary data/interface language
- decorative animation that obscures evidence or analytics

### 20.3 Motion Language

Motion may include where useful:

- page/section transitions
- bull-vs-bull matchup reveal
- image depth/parallax within performance limits
- stat count/reveal
- timeline progression
- chart/data transitions
- state-change micro-interactions
- live/update indicators

Motion must communicate hierarchy, state or competitive energy.

Reduced-motion behavior is mandatory.

Mobile performance and data readability override animation spectacle.

### 20.4 Flagship Experience

`Matchup Intelligence` should become one of the most visually distinctive surfaces in the product: real bull imagery, side-by-side identity, progressive stat reveal, evidence-strength context and explainable analytical factors.

## 21. Security and Privacy Requirements

BullMatch currently reuses shared Supabase infrastructure and owns only its dedicated schemas.

Requirements:

- `bullmatch_private` is never directly exposed to browser clients
- browser-reachable tables require explicit grants + RLS
- authenticated user status alone does not grant BullMatch application privileges
- authorization uses BullMatch app membership/roles, not user-editable metadata
- service-role keys/secrets never enter browser code
- privileged publish/review/merge/split commands are server-mediated
- community contributions cannot write canonical history directly
- personal contact/private evidence remains access-controlled
- first-party profile claims must not expose private ownership/contact data without policy
- unrelated shared Supabase application schemas must not be modified

## 22. Non-Functional Requirements

### Data Integrity

- stable UUID identities
- migration-controlled schema evolution
- historical snapshots and temporal relationships
- evidence/provenance preservation
- auditable corrections
- retry-safe ingestion
- idempotent/stale-safe review commands
- no destructive rewrite merely for implementation convenience

### Scalability / Big Data Readiness

- store structured metadata in PostgreSQL
- store large media externally/object storage rather than PostgreSQL blobs
- use hashes/dedupe keys where appropriate
- design indexes around identity, chronology, venue, match and contribution-review workloads
- retain a path to partition/archive high-volume evidence or logs later without changing canonical IDs
- separate transactional canonical data from derived analytics where scaling requires it

### Cost / Free-Plan Awareness

- reuse existing free-plan capacity responsibly during early phases
- cache/deterministically parse before calling AI unnecessarily
- control media retention and generated derivative size
- monitor DB/storage growth before enabling broad public upload
- do not commit to contribution rewards whose economics are unmeasured

### Maintainability

- versioned contracts
- isolated provider/connectors
- explicit domain boundaries
- Task ID + branch/PR workflow
- additive migrations and compatibility plans
- documented UI/motion system rather than page-specific hacks

### Observability

Track over time:

- source health
- contribution volume and verification yield
- review backlog
- conflict backlog
- duplicate rates
- entity-resolution accuracy
- contributor-quality metrics
- agent runs/errors
- storage/database growth
- API usage when commercial surfaces launch

### Accessibility / Performance

- mobile-first usable layouts
- readable typography and contrast
- reduced-motion support
- keyboard/focus support where relevant
- animation budgets protecting low/mid-range mobile devices
- meaningful loading/error/empty states

## 23. Success Measures

BullMatch success is not measured by raw rows collected.

### Data Network

- verified/published facts
- verified bulls with usable identity evidence
- verified matches/programs/comparison records
- evidence completeness
- percentage of contributions reaching verified state
- duplicate submission rate
- contributor retention
- number of active trusted contributors by venue/region/topic

### Data Quality

- entity-resolution precision
- false merge / overturned link rate
- review disagreement/overturn rate
- conflict backlog
- lineage verification quality
- time from contribution/discovery to verified fact
- source diversity for important facts

### Product Usage

- bull-profile repeat visits
- search-to-profile success
- matchup-analysis usage
- watchlist/report usage when launched
- contribution loop completion

### Commercial Readiness

- Pro feature engagement before/after paywall experiments
- verified-contribution cost vs value
- API partner demand
- venue/camp adoption
- report willingness-to-pay
- contribution credit economics and abuse rate

## 24. Product Safety and Integrity Rules

The system must never present:

- AI-generated inference as verified historical fact
- unresolved conflict as settled fact
- contributor reputation as proof by itself
- model output as guaranteed match outcome
- unsourced lineage or physical claims as verified
- profile ownership as permission to rewrite verified history

Historical facts, community claims, observations, derived statistics and predictive/analytical outputs must remain distinguishable in data model and UI.

## 25. Release / Phase Plan

### Foundation — COMPLETE

Existing production foundation remains active:

- shared Supabase namespace
- controlled API boundary
- app-scoped auth/roles
- canonical bull/camp/owner/venue/match foundation
- public verified-data surfaces
- GitHub Pages frontend

### Community Rebaseline Contract

1. **BMI-P1-009** — Thai Bullfighting Domain Rebaseline — COMPLETE
2. **BMI-P1-010** — Product Rebaseline v0.3 — this document
3. **BMI-P1-011** — Database Schema v0.2 additive design
4. **BMI-P1-012** — Contribution & Trust Architecture
5. **BMI-APP-004** — Real-bull / Sports Intelligence / Motion visual rebaseline
6. **BMI-P1-008** — Review Backend Foundation re-scoped to claims/community

### Community Data Network Implementation

Implement controlled contribution capabilities after the contracts above stabilize:

- contributor membership/profile
- evidence submission
- AI-assisted extraction/confirmation
- atomic claims
- entity/duplicate suggestions
- moderation/review routing
- contributor feedback/reputation surfaces

### Automated Collection Expansion

After community/domain contracts are stable:

`Source -> Ingestion -> Evidence -> Atomic Claims -> Resolution -> Verification/Review -> Canonical Fact`

Then add compliant scheduled connectors incrementally.

### Intelligence Products

Build in stages as verified data density becomes sufficient:

- enriched bull profile
- historical and opponent analytics
- Matchup Intelligence
- Pro/watchlists/reports
- API/B2B data products
- venue/camp/media tools

Do not ship advanced analytical certainty before underlying data can support it.

## 26. Immediate Next Contract

The next engineering contract is **BMI-P1-011 — Database Schema v0.2: Community Claims + Temporal Domain**.

It must translate this PRD and the Thai Bullfighting Domain Model into an **additive, backward-compatible schema plan** covering at minimum:

- community contributors/submissions
- evidence linkage
- atomic claims
- temporal bull affiliations
- physical/style observations
- lineage claims
- comparison sessions
- proposed/accepted pairings
- program versions/amendments
- contributor reputation dimensions
- trust/verification compatibility
- migration/rollback strategy against the working production schema

No destructive production rewrite is authorized by this PRD.
