-- Blueprint §7.3a: Staff AWOL / Absconding records (HR) — separate from account_awol_records (business accounts).
CREATE TABLE IF NOT EXISTS staff_awol_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  awol_date DATE NOT NULL,
  expected_start_time TIME,
  notified_owner_manager BOOLEAN DEFAULT false,
  notified_who TEXT,
  resolution TEXT NOT NULL DEFAULT 'pending' CHECK (resolution IN ('returned', 'resigned', 'dismissed', 'warning_issued', 'pending')),
  written_warning_issued BOOLEAN DEFAULT false,
  warning_document_url TEXT,
  notes TEXT,
  recorded_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_staff_awol_staff_id ON staff_awol_records(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_awol_date ON staff_awol_records(awol_date);
CREATE INDEX IF NOT EXISTS idx_staff_awol_resolution ON staff_awol_records(resolution);

COMMENT ON TABLE staff_awol_records IS 'Blueprint §7.3a: Staff absconding (AWOL) — links to disciplinary file; 3+ incidents = persistent AWOL flag.';

-- Blueprint §7.5: Extend staff_credit for meat purchases, salary advances, loans (one ledger per employee).
ALTER TABLE staff_credit ADD COLUMN IF NOT EXISTS credit_type TEXT DEFAULT 'meat_purchase' CHECK (credit_type IN ('meat_purchase', 'salary_advance', 'loan'));
ALTER TABLE staff_credit ADD COLUMN IF NOT EXISTS items_purchased TEXT;
ALTER TABLE staff_credit ADD COLUMN IF NOT EXISTS repayment_plan TEXT;
ALTER TABLE staff_credit ADD COLUMN IF NOT EXISTS deduct_from TEXT DEFAULT 'next_payroll' CHECK (deduct_from IN ('next_payroll', 'specific_period'));
ALTER TABLE staff_credit ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'deducted', 'partial', 'cleared'));

-- Backfill: existing rows get status from is_paid
UPDATE staff_credit SET status = CASE WHEN is_paid THEN 'cleared' ELSE 'pending' END WHERE status IS NULL;
UPDATE staff_credit SET credit_type = 'meat_purchase' WHERE credit_type IS NULL;

COMMENT ON COLUMN staff_credit.credit_type IS 'Blueprint §7.5: meat_purchase | salary_advance | loan';
COMMENT ON COLUMN staff_credit.status IS 'pending | deducted | partial | cleared';
