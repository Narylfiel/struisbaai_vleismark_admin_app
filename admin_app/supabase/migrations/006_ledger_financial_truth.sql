-- Ledger-based financial system: ledger_entries as single financial truth (Blueprint §9).
-- Every financial event (POS sale, invoice, payment, waste, donation) must create ledger entries.

-- Add source (event type) and metadata for integration and audit.
ALTER TABLE ledger_entries
  ADD COLUMN IF NOT EXISTS source TEXT;

ALTER TABLE ledger_entries
  ADD COLUMN IF NOT EXISTS metadata JSONB;

-- Extend reference_type to allow more sources (optional; source column is primary for event type).
-- reference_type stays as invoice, payment, adjustment, transfer for backward compatibility.
-- source values: pos_sale, invoice, payment_received, waste, donation, sponsorship, payroll, purchase_sale_repayment, etc.

COMMENT ON COLUMN ledger_entries.source IS 'Event that created this entry: pos_sale, invoice, payment_received, waste, donation, sponsorship, payroll, purchase_sale_repayment';
COMMENT ON COLUMN ledger_entries.metadata IS 'Extra context: transaction_id, amount_net, vat, cost, etc.';

-- Index for P&L / VAT / Cash flow: filter by source and by date+account (only if account_code exists).
CREATE INDEX IF NOT EXISTS idx_ledger_entries_source ON ledger_entries(source);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'ledger_entries' AND column_name = 'account_code'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_ledger_entries_entry_date_account ON ledger_entries(entry_date, account_code);
  END IF;
END $$;
