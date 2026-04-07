-- PAYE / HR: optional DOB for secondary/tertiary tax rebates (admin payroll).
ALTER TABLE staff_profiles
  ADD COLUMN IF NOT EXISTS date_of_birth date NULL;
