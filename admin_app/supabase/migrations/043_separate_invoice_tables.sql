-- Migration 043: Replace single 'invoices' usage with supplier_invoices and customer_invoices.
-- New tables; data migrated from invoices. Old invoices table is NOT dropped.

-- supplier_invoices: supplier-only invoices (no account_id)
CREATE TABLE IF NOT EXISTS supplier_invoices (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  invoice_number TEXT NOT NULL,
  supplier_id UUID REFERENCES suppliers(id),
  invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date DATE NOT NULL,
  line_items JSONB DEFAULT '[]'::jsonb,
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  tax_rate DECIMAL(5,2),
  tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  total DECIMAL(10,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','pending_review','approved','paid','overdue','cancelled')),
  payment_date DATE,
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- customer_invoices: account/customer invoices (no supplier_id)
CREATE TABLE IF NOT EXISTS customer_invoices (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  invoice_number TEXT NOT NULL,
  account_id UUID REFERENCES business_accounts(id),
  invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date DATE NOT NULL,
  line_items JSONB DEFAULT '[]'::jsonb,
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  tax_rate DECIMAL(5,2),
  tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  total DECIMAL(10,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','pending_review','approved','sent','paid','overdue','cancelled')),
  payment_date DATE,
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS
ALTER TABLE supplier_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all for anon" ON supplier_invoices FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for anon" ON customer_invoices FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "supplier_invoices_auth_policy" ON supplier_invoices FOR ALL TO public USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "customer_invoices_auth_policy" ON customer_invoices FOR ALL TO public USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Migrate existing data from invoices (old table has total; build line_items from invoice_line_items if present)
INSERT INTO supplier_invoices (id, invoice_number, supplier_id, invoice_date, due_date, line_items, subtotal, tax_rate, tax_amount, total, status, payment_date, notes, created_by, created_at, updated_at)
SELECT
  i.id,
  i.invoice_number,
  i.supplier_id,
  i.invoice_date,
  i.due_date,
  COALESCE(
    (SELECT jsonb_agg(jsonb_build_object('description', ili.description, 'quantity', ili.quantity, 'unit_price', ili.unit_price))
     FROM invoice_line_items ili WHERE ili.invoice_id = i.id),
    COALESCE(i.line_items, '[]'::jsonb)
  ),
  i.subtotal,
  i.tax_rate,
  COALESCE(i.tax_amount, 0),
  COALESCE(i.total, i.subtotal + COALESCE(i.tax_amount, 0)),
  i.status,
  i.payment_date,
  i.notes,
  i.created_by,
  i.created_at,
  i.updated_at
FROM invoices i
WHERE i.supplier_id IS NOT NULL;

INSERT INTO customer_invoices (id, invoice_number, account_id, invoice_date, due_date, line_items, subtotal, tax_rate, tax_amount, total, status, payment_date, notes, created_by, created_at, updated_at)
SELECT
  i.id,
  i.invoice_number,
  i.account_id,
  i.invoice_date,
  i.due_date,
  COALESCE(
    (SELECT jsonb_agg(jsonb_build_object('description', ili.description, 'quantity', ili.quantity, 'unit_price', ili.unit_price))
     FROM invoice_line_items ili WHERE ili.invoice_id = i.id),
    COALESCE(i.line_items, '[]'::jsonb)
  ),
  i.subtotal,
  i.tax_rate,
  COALESCE(i.tax_amount, 0),
  COALESCE(i.total, i.subtotal + COALESCE(i.tax_amount, 0)),
  i.status,
  i.payment_date,
  i.notes,
  i.created_by,
  i.created_at,
  i.updated_at
FROM invoices i
WHERE i.account_id IS NOT NULL;
