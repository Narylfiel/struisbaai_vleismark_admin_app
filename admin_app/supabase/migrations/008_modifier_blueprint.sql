-- Blueprint §4.3: Modifier groups (Required?, Allow Multiple?, Max Selections)
-- and modifier items (Track Inventory?, Linked Item).
-- Extends 001_admin_app_tables_part1 modifier_groups / modifier_items.

-- Modifier groups: selection behaviour
ALTER TABLE modifier_groups
  ADD COLUMN IF NOT EXISTS is_required BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS allow_multiple BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS max_selections INTEGER DEFAULT 1;

-- Modifier items: inventory and linked product
ALTER TABLE modifier_items
  ADD COLUMN IF NOT EXISTS track_inventory BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS inventory_item_id UUID REFERENCES inventory_items(id);

COMMENT ON COLUMN modifier_groups.is_required IS 'Blueprint: Required? (optional = false)';
COMMENT ON COLUMN modifier_groups.allow_multiple IS 'Blueprint: Allow Multiple? (pick one = false)';
COMMENT ON COLUMN modifier_groups.max_selections IS 'Blueprint: Max Selections (e.g. 1)';
COMMENT ON COLUMN modifier_items.track_inventory IS 'Blueprint: Track Inventory?';
COMMENT ON COLUMN modifier_items.inventory_item_id IS 'Blueprint: Linked Item (inventory product)';
