-- Fix PGRST204: ensure chart_of_accounts has account_code (and required columns) in schema.
-- Use when remote table was created with different schema or table was missing.

-- 1) Create table if it doesn't exist (full schema from blueprint)
CREATE TABLE IF NOT EXISTS chart_of_accounts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  account_code TEXT UNIQUE NOT NULL,
  account_name TEXT NOT NULL,
  account_type TEXT NOT NULL CHECK (account_type IN ('asset', 'liability', 'equity', 'income', 'expense')),
  subcategory TEXT,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id)
);

-- 2) Add columns if table already existed with different schema (e.g. missing account_code)
ALTER TABLE chart_of_accounts ADD COLUMN IF NOT EXISTS account_code TEXT;
ALTER TABLE chart_of_accounts ADD COLUMN IF NOT EXISTS account_name TEXT;
ALTER TABLE chart_of_accounts ADD COLUMN IF NOT EXISTS account_type TEXT;
ALTER TABLE chart_of_accounts ADD COLUMN IF NOT EXISTS subcategory TEXT;
ALTER TABLE chart_of_accounts ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE chart_of_accounts ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;
ALTER TABLE chart_of_accounts ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES chart_of_accounts(id) ON DELETE SET NULL;

COMMENT ON TABLE chart_of_accounts IS 'Chart of accounts for ledger; 031 ensures account_code column exists for import.';
