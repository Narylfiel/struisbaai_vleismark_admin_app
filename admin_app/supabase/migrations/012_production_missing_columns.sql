-- Fix Production Batches & Dryer errors: missing columns in live DB.
-- Batches: inventory_items.current_stock does not exist
-- Dryer: dryer_batches.started_at does not exist (DB has start_date)

-- 1. inventory_items.current_stock (used by Batches, stock-take, reports)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'inventory_items') THEN
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS current_stock DECIMAL(10,3) DEFAULT 0;
    -- Backfill from fresh+frozen if present
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'inventory_items' AND column_name = 'stock_on_hand_fresh')
       AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'inventory_items' AND column_name = 'stock_on_hand_frozen') THEN
      UPDATE inventory_items
      SET current_stock = COALESCE(stock_on_hand_fresh, 0) + COALESCE(stock_on_hand_frozen, 0)
      WHERE current_stock = 0 OR current_stock IS NULL;
    END IF;
  END IF;
END $$;

-- 2. dryer_batches.started_at (app expects started_at; some DBs have start_date)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'dryer_batches') THEN
    ALTER TABLE dryer_batches ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    -- Backfill from start_date if that column exists
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'dryer_batches' AND column_name = 'start_date') THEN
      UPDATE dryer_batches SET started_at = start_date WHERE started_at IS NULL AND start_date IS NOT NULL;
    END IF;
  END IF;
END $$;
