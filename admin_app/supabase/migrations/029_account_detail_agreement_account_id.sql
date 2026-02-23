-- H5: Link purchase_sale_agreement to business_account for Account Detail Agreements tab.
ALTER TABLE purchase_sale_agreement ADD COLUMN IF NOT EXISTS account_id UUID REFERENCES business_accounts(id);
CREATE INDEX IF NOT EXISTS idx_purchase_sale_agreement_account_id ON purchase_sale_agreement(account_id);
COMMENT ON COLUMN purchase_sale_agreement.account_id IS 'H5: Business account this agreement relates to (for Account Detail Agreements tab).';
