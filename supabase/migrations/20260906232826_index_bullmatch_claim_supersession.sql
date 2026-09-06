-- BMI-P1-013 follow-up from Supabase Performance Advisor.
-- Production migration version reconciled: 20260906232826

create index claims_supersedes_claim_id_idx
  on bullmatch_private.claims(supersedes_claim_id)
  where supersedes_claim_id is not null;
