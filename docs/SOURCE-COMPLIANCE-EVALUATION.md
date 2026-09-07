# Source Compliance Evaluation Framework

Task: `BMI-P2-003`  
Contract: `source-compliance-evaluation/1.0.0`

## Purpose

BullMatch must evaluate a candidate data source before the source can be configured as `APPROVED` and before any connector polls it. This framework makes that decision evidence-backed and reproducible without turning an autonomous collection agent into the approval authority.

The framework is for **data-source access, evidence provenance and operational policy**. It is not a mechanism for wagering, odds, payments, wallets, settlement or payouts.

## Decision boundary

Every new candidate starts as `REVIEW_REQUIRED`.

An evaluation record may describe observations and a proposed runtime policy, but it does not create a Production `sources` row and it does not enable polling.

`APPROVED` is contract-valid only when:

- `decided_at` is present
- `decided_by` is present
- `authority = OWNER_OR_COMPLIANCE`
- at least one decision-basis reference is recorded
- blocking reasons are empty

This is a record of an explicit decision; it is not authorization for an AI agent to self-approve a source. Autonomous agents may gather evidence and prepare a `REVIEW_REQUIRED` dossier, but the approval authority stays outside the collector.

`BLOCKED` requires at least one blocking reason.

## Required evaluation areas

### 1. Source identity

Record:

- public source name
- operator/owner when identifiable
- source category
- canonical public URL when applicable
- stated public purpose
- references supporting the source/operator identity

Do not treat a page title, channel handle or copied brand name alone as proof of operator identity.

### 2. Access review

Record the proposed access method and whether applicable policy surfaces were checked:

- terms or published usage policy
- robots directives for public-page automation where relevant
- API policy/documentation when an API is proposed
- public evidence references used to make the assessment

Unknown or unresolved access conditions remain explicit; they are not converted into permissive defaults.

### 3. Rights, retention and attribution

Evaluate separately:

- whether BullMatch may retain a public reference
- what content retention class is justified
- whether attribution is required
- whether normalization/derivative text is permitted or remains unclear

A right to view a page does not automatically imply a right to retain or republish media. BullMatch should prefer evidence references and normalized factual claims over unnecessary media copying unless permission supports retention.

### 4. Proposed runtime policy

Before a source can enter the persisted APPROVED registry, document:

- polling enabled/disabled proposal
- interval
- timezone and active windows
- maximum items per run
- complete request-rate limits
- initial cursor strategy
- dedupe-key basis

The values need a source-specific rationale. The framework must not invent a generic rate limit merely to make the registry contract valid.

### 5. Provenance/reliability review

Propose one reliability tier:

- `OFFICIAL`
- `HIGH`
- `MEDIUM`
- `LOW`
- `UNKNOWN`

The tier is provenance metadata, not a guarantee that an individual claim is true. A claim still follows the BullMatch evidence -> claims -> resolution -> review/verification -> controlled-promotion path.

The dossier must also state whether independent cross-checking is `NONE`, `PREFERRED`, or `REQUIRED`.

### 6. Operational safety

Describe only secret **requirements**, never secret values.

Also record:

- withdrawal/deactivation policy
- connector failure policy
- source-specific tests required before Production polling

At minimum a real connector should prove source/run identity, checkpoint safety, dedupe semantics, rate-limit behavior and failure handling before enablement.

## Evidence handling

Evaluation references are URLs used to support the compliance/access decision. They are not automatically Bull/Match evidence and must not be inserted into canonical history merely because the source later becomes approved.

Likewise, evaluating a source must not collect real bull names, match results or venue history as fixture data. Connector conformance should continue using synthetic `.invalid` fixtures until the source has an explicit approval record.

## Relationship to the persisted source registry

`BMI-P2-002` aligned `bullmatch_private.sources` with the full polling/rate-limit policy required by `source-registry-entry/1.0.0`.

After an explicit APPROVED evaluation, a separate controlled configuration action may map the approved policy into a private source-registry row. That action must preserve:

- the approved access method
- approved polling/rate-limit values
- reliability tier rationale
- secret-requirement names only
- `policy_status = APPROVED` only after the approval record exists

The collection runtime still rechecks policy/status/polling before execution and again at persistence time.

## Synthetic contract example

`packages/contracts/examples/source-compliance-evaluation.json` is deliberately unresolved:

- `.invalid` URL
- no real operator
- access/rights not reviewed
- polling disabled
- no runtime rate limit invented
- decision remains `REVIEW_REQUIRED`

It is a shape/conformance example only, not a candidate recommendation.

## Candidate dossier workflow

For each real candidate considered later:

1. create a new evaluation record with `REVIEW_REQUIRED`
2. collect public source/operator/access/rights references without polling the source
3. complete access, rights, provenance and proposed runtime-policy sections
4. list unresolved blockers explicitly
5. present the dossier for owner/compliance decision
6. record `APPROVED` or `BLOCKED` only after that explicit decision
7. if approved, open a source-specific connector task with source-specific tests and controlled registry configuration

## What BMI-P2-003 does not do

- it does not select the first Production source on behalf of the owner
- it does not change any source to APPROVED
- it does not create API credentials
- it does not scrape/poll a real website/channel/API
- it does not insert Bull/Match facts
- it does not bypass review/verification
- it does not broaden database grants or browser access
