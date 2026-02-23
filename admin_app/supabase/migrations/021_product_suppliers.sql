-- H6: Supplier product mapping — multiple suppliers per product; supplier-specific codes and pricing.
-- Use cases: Purchase orders, supplier comparison (price/availability).
CREATE TABLE IF NOT EXISTS product_suppliers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  inventory_item_id UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
  supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
  supplier_product_code TEXT,
  supplier_product_name TEXT,
  unit_price DECIMAL(12,2),
  lead_time_days INTEGER,
  is_preferred BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(inventory_item_id, supplier_id)
);

CREATE INDEX IF NOT EXISTS idx_product_suppliers_item ON product_suppliers(inventory_item_id);
CREATE INDEX IF NOT EXISTS idx_product_suppliers_supplier ON product_suppliers(supplier_id);

COMMENT ON TABLE product_suppliers IS 'Blueprint H6: Multiple suppliers per product; supplier-specific codes and pricing.';
