-- Stock lifecycle blueprint §4.5: extend stock_movements for Waste, Donation, Sponsorship, Freezer, etc.
-- Every stock change MUST create a movement record; stock levels update correctly.

-- 1. Add metadata JSONB for donation/sponsorship/waste (recipient, event, value, reason, photo_url, freezer_pct)
ALTER TABLE stock_movements
  ADD COLUMN IF NOT EXISTS metadata JSONB;

-- 2. Extend movement_type to include blueprint actions
ALTER TABLE stock_movements
  DROP CONSTRAINT IF EXISTS stock_movements_movement_type_check;

ALTER TABLE stock_movements
  ADD CONSTRAINT stock_movements_movement_type_check
  CHECK (movement_type IN (
    'in', 'out', 'adjustment', 'transfer', 'waste', 'production',
    'donation', 'sponsorship', 'staff_meal', 'freezer'
  ));

-- 3. Extend reference_type if needed (optional; keep existing for now)
-- reference_type already has: purchase, sale, production, adjustment, waste

COMMENT ON COLUMN stock_movements.metadata IS 'Blueprint §4.5: donation (recipient, type, value), sponsorship (recipient, event, value), waste (reason, staff, photo_url), freezer (markdown_pct)';
