-- ============================================
-- MIGRATION 100: Extend Print Queue for Unified System
-- PURPOSE: Add print_type and hold_until to support delivery labels
-- DATE: 2026-04-08
-- SAFETY: Additive only, backward compatible
-- ============================================

-- Add print_type column with default 'pos' for backward compatibility
ALTER TABLE online_order_print_queue
ADD COLUMN print_type TEXT NOT NULL DEFAULT 'pos'
CHECK (print_type IN ('pos', 'delivery_label'));

-- Add hold_until column for time-based print hold
ALTER TABLE online_order_print_queue
ADD COLUMN hold_until TIMESTAMPTZ;

-- Backfill existing rows to ensure they have 'pos' type
UPDATE online_order_print_queue
SET print_type = 'pos'
WHERE print_type IS NULL;

-- Add index for efficient polling by print type and hold status
CREATE INDEX idx_print_queue_type_hold 
ON online_order_print_queue(print_type, hold_until, printed) 
WHERE printed = false;

-- Add comments for documentation
COMMENT ON COLUMN online_order_print_queue.print_type IS 
'Type of print job: pos (pick slip for Click & Collect) or delivery_label (delivery label). Default pos for backward compatibility.';

COMMENT ON COLUMN online_order_print_queue.hold_until IS 
'Hold printing until this time. NULL = print immediately. Used for delivery labels with 17:00-09:00 hold window.';

-- ============================================
-- Update contamination prevention trigger
-- ============================================

CREATE OR REPLACE FUNCTION prevent_delivery_pos_contamination()
RETURNS TRIGGER AS $$
DECLARE
  v_is_delivery BOOLEAN;
BEGIN
  -- Get is_delivery flag from order
  SELECT is_delivery INTO v_is_delivery
  FROM online_orders
  WHERE id = NEW.order_id;

  -- RULE 1: Delivery orders can ONLY use 'delivery_label' print type
  IF v_is_delivery = true AND NEW.print_type = 'pos' THEN
    RAISE EXCEPTION 'POS_CONTAMINATION: Delivery orders cannot use pos print type. Use delivery_label instead.';
  END IF;

  -- RULE 2: Click & Collect orders can ONLY use 'pos' print type
  IF v_is_delivery = false AND NEW.print_type = 'delivery_label' THEN
    RAISE EXCEPTION 'DELIVERY_CONTAMINATION: Click & Collect orders cannot use delivery_label print type. Use pos instead.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger already exists, just updated the function above
-- No need to recreate trigger

-- ============================================
-- Validation
-- ============================================

-- Verify columns exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'online_order_print_queue' 
    AND column_name = 'print_type'
  ) THEN
    RAISE EXCEPTION 'Migration failed: print_type column not created';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'online_order_print_queue' 
    AND column_name = 'hold_until'
  ) THEN
    RAISE EXCEPTION 'Migration failed: hold_until column not created';
  END IF;

  RAISE NOTICE 'Migration 100 completed successfully';
END $$;
