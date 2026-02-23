-- H3: Extend staff_credit.credit_type for Staff Credit screen: Advance | Meat Purchase | Deduction | Repayment | Other
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'staff_credit') THEN
    ALTER TABLE staff_credit DROP CONSTRAINT IF EXISTS staff_credit_credit_type_check;
    ALTER TABLE staff_credit ADD CONSTRAINT staff_credit_credit_type_check
      CHECK (credit_type IN ('meat_purchase', 'salary_advance', 'loan', 'deduction', 'repayment', 'other'));
    COMMENT ON COLUMN staff_credit.credit_type IS 'H3: meat_purchase | salary_advance | loan | deduction | repayment | other';
  END IF;
END $$;
