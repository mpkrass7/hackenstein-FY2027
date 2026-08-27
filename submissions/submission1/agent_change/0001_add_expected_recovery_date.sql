-- Migration 0001: forecast the expected recovery date per action.
--
-- Adds an additive, non-breaking `expected_recovery_date` column to
-- ops.ops_actions and backfills it from each action's move-type SLA, so the
-- Operations queue can forecast when each stocked-out position recovers:
--   transfer  -> +3 days   (inter-store move)
--   expedite  -> +1 day    (rush from DC)
--   substitute-> +0 days   (offer in-stock alternative immediately)
--   markdown_hold -> +7 days (hold window before re-evaluation)
--
-- Additive column with a backfill: existing app reads (SELECT *) keep working.

ALTER TABLE ops.ops_actions
    ADD COLUMN IF NOT EXISTS expected_recovery_date date;

UPDATE ops.ops_actions
SET expected_recovery_date = created_at::date + (
    CASE move_type
        WHEN 'transfer'      THEN 3
        WHEN 'expedite'      THEN 1
        WHEN 'substitute'    THEN 0
        WHEN 'markdown_hold' THEN 7
    END
) * INTERVAL '1 day'
WHERE expected_recovery_date IS NULL;
