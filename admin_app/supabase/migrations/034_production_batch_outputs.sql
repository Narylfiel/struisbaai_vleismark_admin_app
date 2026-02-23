-- M3: Production split — one batch → multiple output products.
-- production_batch_outputs stores each output product with qty and unit.

ALTER TABLE production_batches ADD COLUMN IF NOT EXISTS cost_total NUMERIC;

CREATE TABLE IF NOT EXISTS production_batch_outputs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES production_batches(id) ON DELETE CASCADE,
  inventory_item_id UUID NOT NULL REFERENCES inventory_items(id),
  qty_produced NUMERIC NOT NULL,
  unit TEXT NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE production_batch_outputs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "auth users" ON production_batch_outputs
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
