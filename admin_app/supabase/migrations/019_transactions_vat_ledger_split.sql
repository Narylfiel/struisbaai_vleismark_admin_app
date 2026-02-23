-- M2: VAT split in POS ledger — add vat_amount to transactions; post CR 4000 (revenue) + CR 2100 (VAT) when present.
-- Blueprint §9.3: Cash sale DR 1000, CR 4000 Revenue + 2100 VAT.

-- 1. Add vat_amount to transactions (POS can populate when known)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'transactions') THEN
    ALTER TABLE transactions ADD COLUMN IF NOT EXISTS vat_amount DECIMAL(12,2) DEFAULT 0;
  END IF;
END $$;

-- 2. Update post_pos_sale_to_ledger to split revenue and VAT when vat_amount present
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'transactions')
     AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'ledger_entries')
     AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN

    CREATE OR REPLACE FUNCTION post_pos_sale_to_ledger()
    RETURNS TRIGGER AS $ledger$
    DECLARE
        amt DECIMAL(12,2);
        vat DECIMAL(12,2);
        revenue DECIMAL(12,2);
        dr_account TEXT;
        dr_name TEXT;
        rec_by UUID;
        entry_dt DATE;
    BEGIN
        amt := COALESCE(NEW.total_amount, 0);
        IF amt <= 0 THEN RETURN NEW; END IF;

        entry_dt := (COALESCE(NEW.created_at, NOW()))::DATE;
        rec_by := COALESCE(NEW.staff_id, (SELECT id FROM profiles WHERE role = 'owner' LIMIT 1));
        IF rec_by IS NULL THEN RETURN NEW; END IF;

        vat := COALESCE(NEW.vat_amount, 0);
        IF vat < 0 THEN vat := 0; END IF;
        IF vat > amt THEN vat := amt; END IF;
        revenue := amt - vat;

        IF NEW.account_id IS NOT NULL THEN
            dr_account := '1200';
            dr_name := 'Accounts Receivable (Business Accounts)';
        ELSIF LOWER(COALESCE(NEW.payment_method, '')) = 'cash' THEN
            dr_account := '1000';
            dr_name := 'Cash on Hand';
        ELSE
            dr_account := '1100';
            dr_name := 'Bank Account';
        END IF;

        -- DR: Cash/Bank/AR
        INSERT INTO ledger_entries (entry_date, account_code, account_name, debit, credit, description, reference_type, reference_id, source, recorded_by)
        VALUES (entry_dt, dr_account, dr_name, amt, 0, 'POS sale', 'adjustment', NEW.id, 'pos_sale', rec_by);
        -- CR: Revenue (4000)
        INSERT INTO ledger_entries (entry_date, account_code, account_name, debit, credit, description, reference_type, reference_id, source, recorded_by)
        VALUES (entry_dt, '4000', 'Meat Sales', 0, revenue, 'POS sale', 'adjustment', NEW.id, 'pos_sale', rec_by);
        -- CR: VAT (2100) when vat > 0
        IF vat > 0 THEN
            INSERT INTO ledger_entries (entry_date, account_code, account_name, debit, credit, description, reference_type, reference_id, source, recorded_by)
            VALUES (entry_dt, '2100', 'VAT Output', 0, vat, 'POS sale VAT', 'adjustment', NEW.id, 'pos_sale', rec_by);
        END IF;

        RETURN NEW;
    END;
    $ledger$ LANGUAGE plpgsql;

    DROP TRIGGER IF EXISTS trigger_post_transaction_to_ledger ON transactions;
    CREATE TRIGGER trigger_post_transaction_to_ledger
        AFTER INSERT ON transactions
        FOR EACH ROW
        EXECUTE FUNCTION post_pos_sale_to_ledger();
  END IF;
END $$;
