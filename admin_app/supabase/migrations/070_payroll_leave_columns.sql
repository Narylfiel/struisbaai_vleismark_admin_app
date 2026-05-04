-- Add leave day tracking columns to payroll_entries
-- Required for payslip PDF generation and audit trail
ALTER TABLE payroll_entries
  ADD COLUMN IF NOT EXISTS annual_leave_days numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sick_leave_days numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS family_leave_days numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS unpaid_leave_days numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS hourly_rate numeric DEFAULT 0;
