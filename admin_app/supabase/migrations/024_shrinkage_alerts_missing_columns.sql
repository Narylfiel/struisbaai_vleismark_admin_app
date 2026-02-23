-- Add shrinkage_percentage (and related) if missing — dashboard/analytics select them.
ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS shrinkage_percentage DECIMAL(5,2);
ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS alert_type TEXT;
ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES production_batches(id) ON DELETE SET NULL;
ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS expected_weight DECIMAL(10,2);
ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS actual_weight DECIMAL(10,2);
