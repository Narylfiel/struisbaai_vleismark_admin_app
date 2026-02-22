-- Blueprint §4.6 Supplier Management, §4.7 Stock-Take (multi-device ready).

-- 1. Suppliers (Blueprint §4.6)
CREATE TABLE IF NOT EXISTS suppliers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  contact_person TEXT,
  phone TEXT,
  email TEXT,
  address TEXT,
  payment_terms TEXT,
  bbbee_level TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- If suppliers already existed without bbbee_level, add it so COMMENT below succeeds
ALTER TABLE suppliers ADD COLUMN IF NOT EXISTS bbbee_level TEXT;

COMMENT ON TABLE suppliers IS 'Blueprint §4.6: Supplier Management';
COMMENT ON COLUMN suppliers.payment_terms IS 'e.g. COD / 7 days / 14 days / 30 days';
COMMENT ON COLUMN suppliers.bbbee_level IS 'e.g. Level 2';

-- 2. Stock-take sessions (Blueprint §4.7: Owner/Manager starts session)
CREATE TABLE IF NOT EXISTS stock_take_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'pending_approval', 'approved', 'cancelled')),
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  started_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  approved_by UUID REFERENCES profiles(id),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE stock_take_sessions IS 'Blueprint §4.7: Multi-device stock-take — one open session at a time';

-- 3. Stock-take entries (per product, per location; multi-device: same PLU from different locations)
CREATE TABLE IF NOT EXISTS stock_take_entries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES stock_take_sessions(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
  location_id UUID REFERENCES stock_locations(id),
  expected_quantity DECIMAL(10,3) NOT NULL DEFAULT 0,
  actual_quantity DECIMAL(10,3),
  variance DECIMAL(10,3) GENERATED ALWAYS AS (CASE WHEN actual_quantity IS NOT NULL THEN (actual_quantity - expected_quantity) ELSE NULL END) STORED,
  counted_by UUID REFERENCES profiles(id),
  device_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(session_id, item_id, location_id)
);

COMMENT ON TABLE stock_take_entries IS 'Blueprint §4.7: One row per (session, item, location); conflicts when same (session,item,location) from different devices resolved before approval';
COMMENT ON COLUMN stock_take_entries.device_id IS 'Multi-device: identifier of counting device for conflict detection';

CREATE INDEX IF NOT EXISTS idx_stock_take_entries_session ON stock_take_entries(session_id);
CREATE INDEX IF NOT EXISTS idx_stock_take_entries_item ON stock_take_entries(item_id);
CREATE INDEX IF NOT EXISTS idx_stock_take_sessions_status ON stock_take_sessions(status);
