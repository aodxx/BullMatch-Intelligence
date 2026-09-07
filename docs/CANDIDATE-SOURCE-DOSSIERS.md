# Candidate Source Dossier Research

Task: `BMI-P2-004`  
Status: research shortlist only — no source approval or activation

## Purpose

Apply the `source-compliance-evaluation/1.0.0` framework to a small set of plausible real-world Thai bullfighting information sources without polling them, creating credentials, ingesting Bull/Match facts, or granting any source `APPROVED` status.

Every dossier under `docs/source-evaluations/` is deliberately `REVIEW_REQUIRED`, has `polling_enabled=false`, and records unresolved blockers explicitly.

## Shortlist

### 1. wuachon.co — domain-specialist publisher / aggregator

Why it is interesting:

- public pages publish bullfighting program/result-style information directly relevant to BullMatch's evidence network
- likely higher domain coverage than general government sources

Why it is not approved:

- operator identity has not yet been established from a sufficiently authoritative first-party policy/about surface
- terms, robots directives and automation-specific policy are unresolved
- reuse/normalization/attribution rights are unresolved
- a defensible rate limit, cursor and dedupe policy cannot be invented from page visibility alone

Current disposition: `REVIEW_REQUIRED`.

### 2. Thailand Sports Almanac — official government sports reference

Public operator identification on the site points to the Office of the Permanent Secretary, Ministry of Tourism and Sports.

Potential BullMatch role:

- official reference/corroboration for sports/venue context where the site actually publishes relevant records

Limitations:

- bullfighting-specific coverage depth and update cadence are not established
- automation/reuse policy still requires first-party verification
- it is not currently justified as the main recurring match-program feed

Current disposition: `REVIEW_REQUIRED`.

### 3. Surat Thani Provincial Government — official provincial news source

The official provincial site has published public news involving a bullfighting venue, demonstrating that government-originated venue/event context can exist on this source.

Potential BullMatch role:

- official corroboration for venue/event context when the provincial government itself publishes it

Limitations:

- episodic government news is not a dedicated bullfighting program/result feed
- automation/reuse policy is unresolved
- any future collection scope would need narrow relevance filters and conservative request policy

Current disposition: `REVIEW_REQUIRED`.

## Evaluation conclusion

The shortlist confirms an important architecture point: BullMatch will likely need **different source roles**, not one universal source ranking.

- a domain-specialist publisher may offer high coverage but require stronger operator/rights/corroboration review
- an official government source may offer stronger provenance for the facts it publishes but lower coverage and cadence
- source reliability tier therefore describes provenance, while each extracted claim still enters evidence -> atomic claims -> resolution -> review/verification -> controlled promotion

No candidate in this research is ready for Production activation.

## Minimum action before any first-source connector task

For the selected candidate, obtain and record enough first-party evidence to resolve the relevant blockers, including access/automation policy, rights/attribution basis, operator identity, and source-specific runtime behavior. Then an owner/compliance authority must explicitly record an `APPROVED` decision under the versioned evaluation contract.

Until then:

- no private source-registry row should be activated
- no recurring connector should call the source
- no credentials should be created for the purpose of bypassing this gate
- no Bull/Match facts discovered during compliance research should be treated as canonical or Production fixture data
