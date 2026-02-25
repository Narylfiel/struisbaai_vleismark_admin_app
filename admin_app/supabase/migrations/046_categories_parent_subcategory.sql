-- inventory_items: sub_category_id for product subcategory (only; parent_id on categories already exists in DB).
-- Category list shows subcategories indented under parent; product form filters subcategories by main category.

-- sub_category_id: add only if missing (ADD COLUMN IF NOT EXISTS)
ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS sub_category_id UUID REFERENCES categories(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_inventory_items_sub_category_id ON inventory_items(sub_category_id);
COMMENT ON COLUMN inventory_items.sub_category_id IS 'Subcategory (child of category_id); used with sub_category text for display.';
