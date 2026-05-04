-- Per-staff payment method for payroll
-- Business rule: each staff has own payment method (cash/bank_eft)
-- Admin can override at mark-as-paid time
ALTER TABLE staff_profiles
ADD COLUMN IF NOT EXISTS payment_method text
DEFAULT 'bank_eft'
CHECK (payment_method IN ('cash', 'bank_eft'));

ALTER TABLE payroll_entries
ADD COLUMN IF NOT EXISTS payment_method text
DEFAULT 'bank_eft'
CHECK (payment_method IN ('cash', 'bank_eft'));
