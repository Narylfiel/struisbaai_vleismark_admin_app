-- Migration 050: POS blueprint — extend transactions/transaction_items, add split_payments, till_sessions, petty_cash_movements.
-- Admin App reads only; POS writes. RLS allows authenticated read on new tables.

-- ═══════════════════════════════════════════════════════════════════
-- 1. Extend transactions
-- ═══════════════════════════════════════════════════════════════════
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS receipt_number TEXT;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS discount_total DECIMAL(12,2) DEFAULT 0;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS loyalty_customer_id UUID REFERENCES loyalty_customers(id);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS refund_of_transaction_id UUID REFERENCES transactions(id);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS is_refund BOOLEAN DEFAULT false;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS is_voided BOOLEAN DEFAULT false;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS voided_by UUID REFERENCES profiles(id);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS voided_at TIMESTAMPTZ;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS void_reason TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_receipt_number ON transactions(receipt_number) WHERE receipt_number IS NOT NULL;

-- ═══════════════════════════════════════════════════════════════════
-- 2. Extend transaction_items
-- ═══════════════════════════════════════════════════════════════════
ALTER TABLE transaction_items ADD COLUMN IF NOT EXISTS cost_price DECIMAL(12,2);
ALTER TABLE transaction_items ADD COLUMN IF NOT EXISTS discount_amount DECIMAL(12,2) DEFAULT 0;
ALTER TABLE transaction_items ADD COLUMN IF NOT EXISTS is_weighted BOOLEAN DEFAULT false;
ALTER TABLE transaction_items ADD COLUMN IF NOT EXISTS weight_kg DECIMAL(10,3);
ALTER TABLE transaction_items ADD COLUMN IF NOT EXISTS modifier_selections JSONB;

-- ═══════════════════════════════════════════════════════════════════
-- 3. split_payments (POS writes; Admin reads)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS split_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  payment_method TEXT NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  amount_tendered DECIMAL(12,2),
  change_given DECIMAL(12,2),
  card_reference TEXT,
  business_account_id UUID REFERENCES business_accounts(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_split_payments_transaction_id ON split_payments(transaction_id);

-- ═══════════════════════════════════════════════════════════════════
-- 4. till_sessions (POS writes; Admin reads)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS till_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  terminal_id TEXT NOT NULL,
  opened_by UUID NOT NULL REFERENCES profiles(id),
  opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  opening_float DECIMAL(12,2) NOT NULL DEFAULT 0,
  closed_by UUID REFERENCES profiles(id),
  closed_at TIMESTAMPTZ,
  expected_closing_cash DECIMAL(12,2),
  actual_closing_cash DECIMAL(12,2),
  variance DECIMAL(12,2),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_till_sessions_opened_at ON till_sessions(opened_at);
CREATE INDEX IF NOT EXISTS idx_till_sessions_status ON till_sessions(status);

-- ═══════════════════════════════════════════════════════════════════
-- 5. petty_cash_movements (POS writes; Admin reads)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS petty_cash_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  till_session_id UUID NOT NULL REFERENCES till_sessions(id) ON DELETE CASCADE,
  direction TEXT NOT NULL CHECK (direction IN ('in', 'out')),
  amount DECIMAL(12,2) NOT NULL,
  reason TEXT NOT NULL,
  recorded_by UUID NOT NULL REFERENCES profiles(id),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  terminal_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_petty_cash_movements_till_session_id ON petty_cash_movements(till_session_id);

-- ═══════════════════════════════════════════════════════════════════
-- 6. RLS: read access for authenticated users (POS inserts via service role)
-- ═══════════════════════════════════════════════════════════════════
ALTER TABLE split_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE till_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE petty_cash_movements ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read
DROP POLICY IF EXISTS "split_payments_read_authenticated" ON split_payments;
CREATE POLICY "split_payments_read_authenticated" ON split_payments
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "till_sessions_read_authenticated" ON till_sessions;
CREATE POLICY "till_sessions_read_authenticated" ON till_sessions
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "petty_cash_movements_read_authenticated" ON petty_cash_movements;
CREATE POLICY "petty_cash_movements_read_authenticated" ON petty_cash_movements
  FOR SELECT TO authenticated USING (true);
