-- Fix: modifier_groups.sort_order missing (Blueprint §4.3). Modifier screen orders by sort_order.
ALTER TABLE modifier_groups ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;

COMMENT ON COLUMN modifier_groups.sort_order IS 'Blueprint §4.3: Display order for modifier groups';
