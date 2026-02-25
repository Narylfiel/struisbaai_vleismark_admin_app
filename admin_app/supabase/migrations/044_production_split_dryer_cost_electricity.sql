-- Migration 044: Production batch splitting, dryer time/cost tracking, electricity rate config.
-- Feature 1: production_batches — parent_batch_id, split_note.
-- Feature 2: dryer_batches — loaded_at, completed_at, drying_hours (computed), kwh_per_hour, electricity_cost.
-- Feature 2: system_config — seed electricity_rate_per_kwh for dryer cost.

-- 1. Production batches: split columns
ALTER TABLE production_batches
  ADD COLUMN IF NOT EXISTS parent_batch_id UUID REFERENCES production_batches(id),
  ADD COLUMN IF NOT EXISTS split_note TEXT;

COMMENT ON COLUMN production_batches.parent_batch_id IS 'Parent batch when this batch is a split output';
COMMENT ON COLUMN production_batches.split_note IS 'Note describing the split';

-- 2. Dryer batches: time and cost columns
ALTER TABLE dryer_batches
  ADD COLUMN IF NOT EXISTS loaded_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS kwh_per_hour NUMERIC DEFAULT 2.5,
  ADD COLUMN IF NOT EXISTS electricity_cost NUMERIC;

-- Backfill loaded_at from started_at where missing
UPDATE dryer_batches SET loaded_at = started_at WHERE loaded_at IS NULL AND started_at IS NOT NULL;

-- Drying hours: plain column (app or trigger can set it; Flutter sends completed_at and kwh_per_hour on complete)
ALTER TABLE dryer_batches ADD COLUMN IF NOT EXISTS drying_hours NUMERIC;

-- Trigger to set drying_hours when completed_at is set
CREATE OR REPLACE FUNCTION set_dryer_batch_drying_hours()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.completed_at IS NOT NULL AND NEW.loaded_at IS NOT NULL THEN
    NEW.drying_hours := EXTRACT(EPOCH FROM (NEW.completed_at - NEW.loaded_at)) / 3600.0;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_dryer_batch_drying_hours ON dryer_batches;
CREATE TRIGGER trg_dryer_batch_drying_hours
  BEFORE INSERT OR UPDATE ON dryer_batches
  FOR EACH ROW
  EXECUTE PROCEDURE set_dryer_batch_drying_hours();

COMMENT ON COLUMN dryer_batches.loaded_at IS 'Set on create (loaded into dryer)';
COMMENT ON COLUMN dryer_batches.completed_at IS 'Set on weigh-out complete';
COMMENT ON COLUMN dryer_batches.kwh_per_hour IS 'Dryer power kW (default 2.5)';
COMMENT ON COLUMN dryer_batches.electricity_cost IS 'Calculated by Flutter and saved on complete';

-- 3. Seed electricity rate in system_config (for dryer cost)
INSERT INTO system_config (key, value, description, is_active)
VALUES ('electricity_rate_per_kwh', to_jsonb('2.50'::text), 'Electricity rate R/kWh for dryer cost tracking', true)
ON CONFLICT (key) DO NOTHING;
