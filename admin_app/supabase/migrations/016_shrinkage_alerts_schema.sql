-- Blueprint §10.1: shrinkage_alerts — align schema with dashboard and analytics.
-- Dashboard filters on resolved and displays item_name; trigger inserts batch_id, expected_weight, actual_weight, shrinkage_percentage, alert_type.
-- This migration creates the table if missing and adds status, resolved, item_name for consistent queries and display.

CREATE TABLE IF NOT EXISTS shrinkage_alerts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES inventory_items(id) ON DELETE SET NULL,
  item_name TEXT,
  batch_id UUID REFERENCES production_batches(id) ON DELETE SET NULL,
  expected_weight DECIMAL(10,2),
  actual_weight DECIMAL(10,2),
  shrinkage_percentage DECIMAL(5,2),
  alert_type TEXT,
  theoretical_stock DECIMAL(12,3),
  actual_stock DECIMAL(12,3),
  gap_amount DECIMAL(12,3),
  gap_percentage DECIMAL(5,2),
  possible_reasons TEXT,
  staff_involved TEXT,
  status TEXT NOT NULL DEFAULT 'Pending',
  resolved BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure columns exist if table was created by trigger elsewhere (e.g. only batch_id, expected_weight, etc.)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'shrinkage_alerts') THEN
    ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES inventory_items(id) ON DELETE SET NULL;
    ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS item_name TEXT;
    ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'Pending';
    ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS resolved BOOLEAN DEFAULT false;
    ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS theoretical_stock DECIMAL(12,3);
    ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS actual_stock DECIMAL(12,3);
    ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS gap_amount DECIMAL(12,3);
    ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS gap_percentage DECIMAL(5,2);
    ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS possible_reasons TEXT;
    ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS staff_involved TEXT;
    ALTER TABLE shrinkage_alerts ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    UPDATE shrinkage_alerts SET status = COALESCE(status, 'Pending'), resolved = COALESCE(resolved, false) WHERE status IS NULL OR resolved IS NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_shrinkage_alerts_resolved ON shrinkage_alerts(resolved);
CREATE INDEX IF NOT EXISTS idx_shrinkage_alerts_created_at ON shrinkage_alerts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_shrinkage_alerts_status ON shrinkage_alerts(status);

COMMENT ON TABLE shrinkage_alerts IS 'Blueprint §10.1: Mass-balance and production shrinkage alerts; dashboard shows unresolved, analytics uses status.';

-- Update trigger to set status and resolved so new rows work with dashboard filter.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'shrinkage_alerts') AND
     EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'production_batches') AND
     EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recipes') THEN
    CREATE OR REPLACE FUNCTION check_shrinkage_threshold()
    RETURNS TRIGGER AS $function$
    DECLARE
        expected_weight DECIMAL(10,2);
        shrinkage_pct DECIMAL(5,2);
        threshold_pct DECIMAL(5,2) := 2.0;
    BEGIN
        IF TG_OP = 'UPDATE' AND OLD.actual_quantity IS NULL AND NEW.actual_quantity IS NOT NULL THEN
            SELECT COALESCE(SUM(ri.quantity * ri.quantity), 0) INTO expected_weight
            FROM production_batches pb
            JOIN recipes r ON pb.recipe_id = r.id
            JOIN recipe_ingredients ri ON r.id = ri.recipe_id
            WHERE pb.id = NEW.id;
            IF expected_weight IS NULL THEN
              SELECT COALESCE(SUM(ri.quantity), 0) INTO expected_weight
              FROM production_batches pb
              JOIN recipe_ingredients ri ON pb.recipe_id = ri.recipe_id
              WHERE pb.id = NEW.id;
            END IF;
            IF expected_weight > 0 THEN
                shrinkage_pct := ((expected_weight - NEW.actual_quantity) / expected_weight) * 100;
                IF shrinkage_pct > threshold_pct THEN
                    INSERT INTO shrinkage_alerts (
                      batch_id, expected_weight, actual_weight, shrinkage_percentage, alert_type,
                      status, resolved, item_name
                    )
                    VALUES (
                      NEW.id, expected_weight, NEW.actual_quantity, shrinkage_pct, 'production',
                      'Pending', false, (SELECT r.name FROM production_batches pb JOIN recipes r ON pb.recipe_id = r.id WHERE pb.id = NEW.id LIMIT 1)
                    );
                END IF;
            END IF;
        END IF;
        RETURN NEW;
    END;
    $function$ LANGUAGE plpgsql;
  END IF;
END $$;
