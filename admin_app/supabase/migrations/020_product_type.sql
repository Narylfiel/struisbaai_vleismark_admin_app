-- H9: Product types for processing logic — Raw (no processing), Portioned, Manufactured (recipe-based).
-- Production + Inventory behavior can branch on product_type.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'inventory_items') THEN
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS product_type TEXT DEFAULT 'raw'
      CHECK (product_type IS NULL OR product_type IN ('raw', 'portioned', 'manufactured'));
    COMMENT ON COLUMN inventory_items.product_type IS 'Blueprint: Raw (no processing), Portioned, Manufactured (recipe-based)';
  END IF;
END $$;
