-- C1: One-time alignment — set current_stock from fresh+frozen where current_stock is 0 but fresh/frozen have value.
-- UI and POS trigger use current_stock as single source of truth; this backfills for existing rows that had only fresh/frozen set.
-- Does not remove stock_on_hand_fresh / stock_on_hand_frozen columns.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'inventory_items' AND column_name = 'current_stock')
     AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'inventory_items' AND column_name = 'stock_on_hand_fresh')
     AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'inventory_items' AND column_name = 'stock_on_hand_frozen') THEN
    UPDATE inventory_items
    SET current_stock = COALESCE(stock_on_hand_fresh, 0) + COALESCE(stock_on_hand_frozen, 0)
    WHERE (current_stock = 0 OR current_stock IS NULL)
      AND (COALESCE(stock_on_hand_fresh, 0) > 0 OR COALESCE(stock_on_hand_frozen, 0) > 0);
  END IF;
END $$;
