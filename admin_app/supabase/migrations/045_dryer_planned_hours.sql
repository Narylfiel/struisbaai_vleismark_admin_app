-- Migration 045: Planned drying duration (hours) for dryer batches.
ALTER TABLE dryer_batches ADD COLUMN IF NOT EXISTS planned_hours NUMERIC;

COMMENT ON COLUMN dryer_batches.planned_hours IS 'Planned drying time in hours (e.g. 48 for biltong, 24 for droëwors)';
