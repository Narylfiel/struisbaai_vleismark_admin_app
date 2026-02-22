-- Blueprint §5.5 Recipes & Production Batches, §5.6 Dryer/Biltong.
-- Links recipes to output product and expected yield; links batches to stock; dryer input/output products.

-- Recipes: output product (Own-Processed link), expected yield %, batch size for ingredient scaling
ALTER TABLE recipes
  ADD COLUMN IF NOT EXISTS output_product_id UUID REFERENCES inventory_items(id),
  ADD COLUMN IF NOT EXISTS expected_yield_pct DECIMAL(5,2) DEFAULT 100,
  ADD COLUMN IF NOT EXISTS batch_size_kg DECIMAL(10,3) DEFAULT 1;

COMMENT ON COLUMN recipes.output_product_id IS 'Blueprint: Output Product (e.g. Boerewors Traditional)';
COMMENT ON COLUMN recipes.expected_yield_pct IS 'Blueprint: Expected Yield % (e.g. 95 = 5% loss)';
COMMENT ON COLUMN recipes.batch_size_kg IS 'Blueprint: Ingredient quantities are per this batch size (e.g. 10 kg)';

-- Production batches: denormalized output product for completion flow
ALTER TABLE production_batches
  ADD COLUMN IF NOT EXISTS output_product_id UUID REFERENCES inventory_items(id);

COMMENT ON COLUMN production_batches.output_product_id IS 'Output product to add on completion (from recipe)';

-- Dryer batches: raw input product, finished output product, optional recipe
ALTER TABLE dryer_batches
  ADD COLUMN IF NOT EXISTS input_product_id UUID REFERENCES inventory_items(id),
  ADD COLUMN IF NOT EXISTS output_product_id UUID REFERENCES inventory_items(id),
  ADD COLUMN IF NOT EXISTS recipe_id UUID REFERENCES recipes(id);

COMMENT ON COLUMN dryer_batches.input_product_id IS 'Blueprint: Raw material (e.g. beef topside)';
COMMENT ON COLUMN dryer_batches.output_product_id IS 'Blueprint: Finished product (e.g. biltong PLU)';
COMMENT ON COLUMN dryer_batches.recipe_id IS 'Optional recipe (spice ratios, curing method)';

-- Extend dryer_type for Blueprint: Biltong / Droewors / Chilli Bites / Other (only if column exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'dryer_batches' AND column_name = 'dryer_type'
  ) THEN
    ALTER TABLE dryer_batches DROP CONSTRAINT IF EXISTS dryer_batches_dryer_type_check;
    ALTER TABLE dryer_batches ADD CONSTRAINT dryer_batches_dryer_type_check
      CHECK (dryer_type IN ('biltong', 'droewors', 'jerky', 'chilli_bites', 'other'));
  END IF;
END $$;
