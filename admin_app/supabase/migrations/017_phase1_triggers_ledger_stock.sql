-- Phase 1 full correction: triggers for shrinkage, POS→ledger, stock deduction; account_transactions table.
-- Run after 016 (shrinkage_alerts table) and 004 (transactions, transaction_items), 002 (ledger_entries).

-- ═══════════════════════════════════════════════════════════════════
-- 1. SHRINKAGE TRIGGER — create explicitly after table exists (fix migration order)
-- ═══════════════════════════════════════════════════════════════════
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'shrinkage_alerts')
     AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'production_batches')
     AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recipes') THEN

    CREATE OR REPLACE FUNCTION check_shrinkage_threshold()
    RETURNS TRIGGER AS $fn$
    DECLARE
        expected_weight DECIMAL(10,2);
        shrinkage_pct DECIMAL(5,2);
        threshold_pct DECIMAL(5,2) := 2.0;
        recipe_name_val TEXT;
    BEGIN
        IF TG_OP = 'UPDATE' AND (OLD.actual_quantity IS DISTINCT FROM NEW.actual_quantity) AND NEW.actual_quantity IS NOT NULL THEN
            SELECT COALESCE(SUM(ri.quantity), 0) INTO expected_weight
            FROM production_batches pb
            JOIN recipe_ingredients ri ON pb.recipe_id = ri.recipe_id
            WHERE pb.id = NEW.id;
            IF expected_weight IS NULL OR expected_weight <= 0 THEN
              SELECT COALESCE(SUM(ri.quantity * ri.quantity), 0) INTO expected_weight
              FROM production_batches pb
              JOIN recipes r ON pb.recipe_id = r.id
              JOIN recipe_ingredients ri ON r.id = ri.recipe_id
              WHERE pb.id = NEW.id;
            END IF;
            IF expected_weight > 0 THEN
                shrinkage_pct := ((expected_weight - NEW.actual_quantity) / expected_weight) * 100;
                IF shrinkage_pct > threshold_pct THEN
                    SELECT r.name INTO recipe_name_val
                    FROM production_batches pb
                    JOIN recipes r ON pb.recipe_id = r.id
                    WHERE pb.id = NEW.id
                    LIMIT 1;
                    INSERT INTO shrinkage_alerts (
                      batch_id, expected_weight, actual_weight, shrinkage_percentage, alert_type,
                      status, resolved, item_name
                    )
                    VALUES (
                      NEW.id, expected_weight, NEW.actual_quantity, shrinkage_pct, 'production',
                      'Pending', false, COALESCE(recipe_name_val, 'Production batch')
                    );
                END IF;
            END IF;
        END IF;
        RETURN NEW;
    END;
    $fn$ LANGUAGE plpgsql;

    DROP TRIGGER IF EXISTS trigger_shrinkage_check ON production_batches;
    CREATE TRIGGER trigger_shrinkage_check
        AFTER UPDATE ON production_batches
        FOR EACH ROW
        EXECUTE FUNCTION check_shrinkage_threshold();
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════
-- 2. ACCOUNT_TRANSACTIONS (for payment history — app already inserts)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS account_transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  account_id UUID NOT NULL REFERENCES business_accounts(id) ON DELETE CASCADE,
  transaction_type TEXT NOT NULL,
  reference TEXT,
  description TEXT,
  amount DECIMAL(12,2) NOT NULL,
  running_balance DECIMAL(12,2),
  payment_method TEXT,
  transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════
-- 3. POS TRANSACTION → LEDGER (Blueprint §9: every financial event posts)
-- ═══════════════════════════════════════════════════════════════════
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'transactions')
     AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'ledger_entries')
     AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN

    CREATE OR REPLACE FUNCTION post_pos_sale_to_ledger()
    RETURNS TRIGGER AS $ledger$
    DECLARE
        amt DECIMAL(12,2);
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

        INSERT INTO ledger_entries (entry_date, account_code, account_name, debit, credit, description, reference_type, reference_id, source, recorded_by)
        VALUES (entry_dt, dr_account, dr_name, amt, 0, 'POS sale', 'adjustment', NEW.id, 'pos_sale', rec_by);
        INSERT INTO ledger_entries (entry_date, account_code, account_name, debit, credit, description, reference_type, reference_id, source, recorded_by)
        VALUES (entry_dt, '4000', 'Meat Sales', 0, amt, 'POS sale', 'adjustment', NEW.id, 'pos_sale', rec_by);

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

-- ═══════════════════════════════════════════════════════════════════
-- 4. TRANSACTION_ITEMS → DEDUCT STOCK (inventory_items single source)
-- ═══════════════════════════════════════════════════════════════════
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'transaction_items')
     AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'inventory_items')
     AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'inventory_items' AND column_name = 'current_stock') THEN

    CREATE OR REPLACE FUNCTION deduct_stock_on_sale()
    RETURNS TRIGGER AS $stock$
    BEGIN
        IF NEW.inventory_item_id IS NOT NULL AND NEW.quantity IS NOT NULL AND NEW.quantity > 0 THEN
            UPDATE inventory_items
            SET current_stock = GREATEST(0, COALESCE(current_stock, 0) - NEW.quantity)
            WHERE id = NEW.inventory_item_id;
        END IF;
        RETURN NEW;
    END;
    $stock$ LANGUAGE plpgsql;

    DROP TRIGGER IF EXISTS trigger_deduct_stock_on_sale ON transaction_items;
    CREATE TRIGGER trigger_deduct_stock_on_sale
        AFTER INSERT ON transaction_items
        FOR EACH ROW
        EXECUTE FUNCTION deduct_stock_on_sale();
  END IF;
END $$;
