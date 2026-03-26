-- Migration 058: Make POS ledger posting refund-aware (DB-only)
-- Goal: When `transactions.is_refund=true`, reverse the sale journal:
--   - Credit Cash/Bank/AR instead of debiting it
--   - Debit Revenue instead of crediting it
--   - Debit VAT Output instead of crediting it
--
-- Stock is handled elsewhere (stock_movements -> inventory trigger). This migration is ledger-only.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'transactions'
  )
  AND EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'ledger_entries'
  )
  AND EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'profiles'
  ) THEN

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
      amt := abs(COALESCE(NEW.total_amount, 0));
      IF amt = 0 THEN
        RETURN NEW;
      END IF;

      entry_dt := (COALESCE(NEW.created_at, NOW()))::DATE;
      rec_by := COALESCE(NEW.staff_id, (SELECT id FROM profiles WHERE role = 'owner' LIMIT 1));
      IF rec_by IS NULL THEN
        RETURN NEW;
      END IF;

      vat := abs(COALESCE(NEW.vat_amount, 0));
      IF vat > amt THEN
        vat := amt;
      END IF;
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

      IF NEW.is_refund = true THEN
        -- Refund reversal:
        --   Credit Cash/Bank/AR (instead of debit)
        --   Debit Revenue (instead of credit)
        --   Debit VAT Output (instead of credit)
        INSERT INTO ledger_entries (
          entry_date, account_code, account_name,
          debit, credit, description,
          reference_type, reference_id, source, recorded_by
        )
        VALUES (
          entry_dt, dr_account, dr_name,
          0, amt, 'POS refund',
          'adjustment', NEW.id, 'pos_sale', rec_by
        );

        INSERT INTO ledger_entries (
          entry_date, account_code, account_name,
          debit, credit, description,
          reference_type, reference_id, source, recorded_by
        )
        VALUES (
          entry_dt, '4000', 'Meat Sales',
          revenue, 0, 'POS refund',
          'adjustment', NEW.id, 'pos_sale', rec_by
        );

        IF vat > 0 THEN
          INSERT INTO ledger_entries (
            entry_date, account_code, account_name,
            debit, credit, description,
            reference_type, reference_id, source, recorded_by
          )
          VALUES (
            entry_dt, '2100', 'VAT Output',
            vat, 0, 'POS refund VAT',
            'adjustment', NEW.id, 'pos_sale', rec_by
          );
        END IF;
      ELSE
        -- Existing sale journal:
        --   Debit Cash/Bank/AR
        --   Credit Revenue
        --   Credit VAT Output (when present)
        INSERT INTO ledger_entries (
          entry_date, account_code, account_name,
          debit, credit, description,
          reference_type, reference_id, source, recorded_by
        )
        VALUES (
          entry_dt, dr_account, dr_name,
          amt, 0, 'POS sale',
          'adjustment', NEW.id, 'pos_sale', rec_by
        );

        INSERT INTO ledger_entries (
          entry_date, account_code, account_name,
          debit, credit, description,
          reference_type, reference_id, source, recorded_by
        )
        VALUES (
          entry_dt, '4000', 'Meat Sales',
          0, revenue, 'POS sale',
          'adjustment', NEW.id, 'pos_sale', rec_by
        );

        IF vat > 0 THEN
          INSERT INTO ledger_entries (
            entry_date, account_code, account_name,
            debit, credit, description,
            reference_type, reference_id, source, recorded_by
          )
          VALUES (
            entry_dt, '2100', 'VAT Output',
            0, vat, 'POS sale VAT',
            'adjustment', NEW.id, 'pos_sale', rec_by
          );
        END IF;
      END IF;

      RETURN NEW;
    END;
    $ledger$ LANGUAGE plpgsql;

  END IF;
END $$;

