-- H6: Chart of Accounts tree — parent_id for nested display (Assets | Liabilities | Equity | Income | Expenses).
ALTER TABLE chart_of_accounts ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES chart_of_accounts(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_chart_of_accounts_parent_id ON chart_of_accounts(parent_id);
COMMENT ON COLUMN chart_of_accounts.parent_id IS 'H6: Parent account for tree display; null = top-level under type.';
