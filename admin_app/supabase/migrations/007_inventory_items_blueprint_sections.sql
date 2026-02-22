-- Blueprint §4.2: Product form Sections A–H — ensure inventory_items has all required columns.
-- Run only if inventory_items exists (e.g. from POS or prior migration). All ADD COLUMN IF NOT EXISTS.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'inventory_items') THEN
    -- A: Identity (Blueprint §4.2 Section A)
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS sub_category TEXT;
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS supplier_ids JSONB; -- array of supplier id or name

    -- B: Pricing (sell_price, cost_price, target_margin_pct, freezer_markdown_pct, vat_group, price_last_changed often exist)
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS average_cost DECIMAL(10,2);
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS price_last_changed TIMESTAMP WITH TIME ZONE;

    -- C: Stock
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS pack_size DECIMAL(10,2) DEFAULT 1;
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS storage_location_ids JSONB;
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS carcass_link_id UUID;
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS dryer_biltong_product BOOLEAN DEFAULT false;

    -- D: Barcode & Scale
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS barcode_prefix TEXT; -- '20' | '21' | null

    -- E: Modifiers
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS modifier_group_ids JSONB;

    -- F: Production (recipe_id links to recipes if that table exists)
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS recipe_id UUID;
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS dryer_product_type TEXT;
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS manufactured_item BOOLEAN DEFAULT false;

    -- G: Media & Notes
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS image_url TEXT;
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS dietary_tags JSONB;
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS allergen_info JSONB;
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS internal_notes TEXT;

    -- H: Activity (last_edited_by links to profiles if that table exists)
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS last_edited_by UUID;
    ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS last_edited_at TIMESTAMP WITH TIME ZONE;
  END IF;
END $$;
