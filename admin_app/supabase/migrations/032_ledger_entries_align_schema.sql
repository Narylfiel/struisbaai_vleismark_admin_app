-- Align ledger_entries with admin app: remote has account_id, reference, created_by;
-- app expects account_code, account_name, reference_type, reference_id, recorded_by.
-- Add columns and allow account_id to be null so app can insert by account_code/account_name.

ALTER TABLE ledger_entries ADD COLUMN IF NOT EXISTS account_code TEXT;
ALTER TABLE ledger_entries ADD COLUMN IF NOT EXISTS account_name TEXT;
ALTER TABLE ledger_entries ADD COLUMN IF NOT EXISTS reference_type TEXT;
ALTER TABLE ledger_entries ADD COLUMN IF NOT EXISTS reference_id UUID;
ALTER TABLE ledger_entries ADD COLUMN IF NOT EXISTS recorded_by UUID REFERENCES profiles(id);

-- Allow inserts without account_id when using account_code/account_name
ALTER TABLE ledger_entries ALTER COLUMN account_id DROP NOT NULL;

-- Backfill account_code, account_name, recorded_by from existing data (chart_of_accounts + created_by)
UPDATE ledger_entries le
SET
  account_code = COALESCE(
    (SELECT c.account_code FROM chart_of_accounts c WHERE c.id = le.account_id),
    (SELECT c.code FROM chart_of_accounts c WHERE c.id = le.account_id)
  ),
  account_name = COALESCE(
    (SELECT c.account_name FROM chart_of_accounts c WHERE c.id = le.account_id),
    (SELECT c.name FROM chart_of_accounts c WHERE c.id = le.account_id)
  ),
  recorded_by = le.created_by
WHERE le.account_id IS NOT NULL AND (le.account_code IS NULL OR le.account_name IS NULL);

COMMENT ON COLUMN ledger_entries.account_code IS 'Denormalized for admin app; also used when account_id not set.';
COMMENT ON COLUMN ledger_entries.recorded_by IS 'Admin app: staff who recorded (profiles.id).';
