-- Admin App Database - Indexes, Triggers, and RPC Functions

-- Add missing columns to existing tables first
ALTER TABLE categories ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE categories RENAME COLUMN colour_code TO color_code;

-- Add missing columns to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Add missing columns to inventory_items table
ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES categories(id);
ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add missing columns to business_accounts table
ALTER TABLE business_accounts ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT true;
ALTER TABLE business_accounts ADD COLUMN IF NOT EXISTS suspension_recommended BOOLEAN DEFAULT false;

-- Add category_id column to inventory_items if it exists and doesn't have the column
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'inventory_items') THEN
        ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES categories(id);
    END IF;
END $$;

-- Create indexes only for tables that exist
DO $$
BEGIN
    -- Inventory indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'inventory_items') THEN
        CREATE INDEX IF NOT EXISTS idx_inventory_items_category ON inventory_items(category_id);
        CREATE INDEX IF NOT EXISTS idx_inventory_items_active ON inventory_items(is_active);
        CREATE INDEX IF NOT EXISTS idx_inventory_items_plu ON inventory_items(plu_code);
    END IF;

    -- Sales indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sales_transactions') THEN
        CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales_transactions(created_at);
        CREATE INDEX IF NOT EXISTS idx_sales_total_amount ON sales_transactions(total_amount);
    END IF;

    -- Transaction items indexes (only if columns exist)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'transaction_items') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'transaction_items' AND column_name = 'sale_id') THEN
            CREATE INDEX IF NOT EXISTS idx_transaction_items_sale_id ON transaction_items(sale_id);
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'transaction_items' AND column_name = 'inventory_item_id') THEN
            CREATE INDEX IF NOT EXISTS idx_transaction_items_product_id ON transaction_items(inventory_item_id);
        END IF;
    END IF;

    -- Profile indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
        CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
        CREATE INDEX IF NOT EXISTS idx_profiles_active ON profiles(is_active);
    END IF;

    -- Business accounts indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'business_accounts') THEN
        CREATE INDEX IF NOT EXISTS idx_business_accounts_active ON business_accounts(active);
        CREATE INDEX IF NOT EXISTS idx_business_accounts_balance ON business_accounts(balance);
    END IF;

    -- Leave requests indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'leave_requests') THEN
        CREATE INDEX IF NOT EXISTS idx_leave_requests_status ON leave_requests(status);
    END IF;

    -- Payroll indexes (only if column exists)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'payroll_entries') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'payroll_entries' AND column_name = 'payroll_period_id') THEN
            CREATE INDEX IF NOT EXISTS idx_payroll_entries_payroll_period ON payroll_entries(payroll_period_id);
        END IF;
    END IF;

    -- Alert indexes (only if column exists)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'shrinkage_alerts') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'shrinkage_alerts' AND column_name = 'resolved') THEN
            CREATE INDEX IF NOT EXISTS idx_shrinkage_alerts_resolved ON shrinkage_alerts(resolved);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'reorder_recommendations') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'reorder_recommendations' AND column_name = 'auto_resolved') THEN
            CREATE INDEX IF NOT EXISTS idx_reorder_recommendations_resolved ON reorder_recommendations(auto_resolved);
        END IF;
    END IF;
END $$;

-- Additional indexes for new tables (only create if table and columns exist)
DO $$
BEGIN
    -- Production tables
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'carcass_intakes' AND column_name = 'intake_date') THEN
        CREATE INDEX IF NOT EXISTS idx_carcass_intakes_date ON carcass_intakes(intake_date);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'carcass_breakdown_sessions' AND column_name = 'status') THEN
        CREATE INDEX IF NOT EXISTS idx_carcass_breakdown_sessions_status ON carcass_breakdown_sessions(status);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'stock_movements') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'stock_movements' AND column_name = 'item_id') AND
           EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'stock_movements' AND column_name = 'movement_type') THEN
            CREATE INDEX IF NOT EXISTS idx_stock_movements_item_type ON stock_movements(item_id, movement_type);
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'stock_movements' AND column_name = 'performed_at') THEN
            CREATE INDEX IF NOT EXISTS idx_stock_movements_date ON stock_movements(performed_at);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'production_batches' AND column_name = 'status') THEN
        CREATE INDEX IF NOT EXISTS idx_production_batches_status ON production_batches(status);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'hunter_jobs' AND column_name = 'status') THEN
        CREATE INDEX IF NOT EXISTS idx_hunter_jobs_status ON hunter_jobs(status);
    END IF;

    -- Accounting tables
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'invoices' AND column_name = 'status') THEN
        CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'invoices' AND column_name = 'due_date') THEN
        CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ledger_entries' AND column_name = 'entry_date') THEN
        CREATE INDEX IF NOT EXISTS idx_ledger_entries_date ON ledger_entries(entry_date);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'ledger_entries' AND column_name = 'account_code') THEN
        CREATE INDEX IF NOT EXISTS idx_ledger_entries_account ON ledger_entries(account_code);
    END IF;

    -- Customer tables
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'loyalty_customers' AND column_name = 'tier') THEN
        CREATE INDEX IF NOT EXISTS idx_loyalty_customers_tier ON loyalty_customers(tier);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'announcements' AND column_name = 'is_active') THEN
        CREATE INDEX IF NOT EXISTS idx_announcements_active ON announcements(is_active);
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'event_sales_history') AND
       EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'event_sales_history' AND column_name = 'event_id') AND
       EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'event_sales_history' AND column_name = 'date') THEN
        CREATE INDEX IF NOT EXISTS idx_event_sales_history_event_date ON event_sales_history(event_id, date);
    END IF;
END $$;

-- Triggers

-- 1. Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to tables with updated_at (only for tables that exist; idempotent)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'inventory_items') THEN
        DROP TRIGGER IF EXISTS update_inventory_items_updated_at ON inventory_items;
        CREATE TRIGGER update_inventory_items_updated_at BEFORE UPDATE ON inventory_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'invoices') THEN
        DROP TRIGGER IF EXISTS update_invoices_updated_at ON invoices;
        CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'loyalty_customers') THEN
        DROP TRIGGER IF EXISTS update_loyalty_customers_updated_at ON loyalty_customers;
        CREATE TRIGGER update_loyalty_customers_updated_at BEFORE UPDATE ON loyalty_customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'announcements') THEN
        DROP TRIGGER IF EXISTS update_announcements_updated_at ON announcements;
        CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- 2. Shrinkage Alert Trigger (only if production_batches table exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'production_batches') AND
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recipes') AND
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recipe_ingredients') AND
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'shrinkage_alerts') THEN

        CREATE OR REPLACE FUNCTION check_shrinkage_threshold()
        RETURNS TRIGGER AS $function$
        DECLARE
            expected_weight DECIMAL(10,2);
            actual_weight DECIMAL(10,2);
            shrinkage_pct DECIMAL(5,2);
            threshold_pct DECIMAL(5,2) := 2.0; -- 2% threshold
        BEGIN
            -- Calculate expected vs actual for production batches
            IF TG_OP = 'UPDATE' AND OLD.actual_quantity IS NULL AND NEW.actual_quantity IS NOT NULL THEN
                -- Get expected weight from recipe
                SELECT (ri.quantity * ri.quantity) INTO expected_weight
                FROM production_batches pb
                JOIN recipes r ON pb.recipe_id = r.id
                JOIN recipe_ingredients ri ON r.id = ri.recipe_id
                WHERE pb.id = NEW.id AND ri.ingredient_name LIKE '%meat%';

                -- Calculate shrinkage
                IF expected_weight > 0 THEN
                    shrinkage_pct := ((expected_weight - NEW.actual_quantity) / expected_weight) * 100;

                    IF shrinkage_pct > threshold_pct THEN
                        INSERT INTO shrinkage_alerts (batch_id, expected_weight, actual_weight, shrinkage_percentage, alert_type)
                        VALUES (NEW.id, expected_weight, NEW.actual_quantity, shrinkage_pct, 'production');
                    END IF;
                END IF;
            END IF;

            RETURN NEW;
        END;
        $function$ LANGUAGE plpgsql;

        CREATE TRIGGER trigger_shrinkage_check
            AFTER UPDATE ON production_batches
            FOR EACH ROW
            EXECUTE FUNCTION check_shrinkage_threshold();
    END IF;
END $$;

-- 3. Reorder Alert Trigger (only if required tables exist)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'inventory_items') AND
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'stock_movements') AND
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'reorder_recommendations') THEN

        CREATE OR REPLACE FUNCTION check_reorder_threshold()
        RETURNS TRIGGER AS $reorder$
        DECLARE
            item_record RECORD;
            days_of_stock DECIMAL(8,2);
            reorder_threshold_days INTEGER := 7;
        BEGIN
            -- Get item details
            SELECT * INTO item_record FROM inventory_items WHERE id = NEW.item_id;

            IF item_record.reorder_point > 0 AND item_record.average_daily_sales > 0 THEN
                days_of_stock := item_record.current_stock / item_record.average_daily_sales;

                IF days_of_stock <= reorder_threshold_days AND
                   NOT EXISTS (SELECT 1 FROM reorder_recommendations WHERE item_id = NEW.item_id AND auto_resolved = false) THEN
                    INSERT INTO reorder_recommendations (
                        item_id, current_stock, reorder_point, days_of_stock, recommended_quantity
                    ) VALUES (
                        NEW.item_id,
                        item_record.current_stock,
                        item_record.reorder_point,
                        days_of_stock,
                        GREATEST(item_record.reorder_point - item_record.current_stock, 0)
                    );
                END IF;
            END IF;

            RETURN NEW;
        END;
        $reorder$ LANGUAGE plpgsql;

        CREATE TRIGGER trigger_reorder_check
            AFTER INSERT OR UPDATE ON stock_movements
            FOR EACH ROW
            WHEN (NEW.movement_type IN ('out', 'adjustment'))
            EXECUTE FUNCTION check_reorder_threshold();
    END IF;
END $$;

-- 4. AWOL Detection Trigger (only if account_awol_records table exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'account_awol_records') THEN

        CREATE OR REPLACE FUNCTION detect_awol_pattern()
        RETURNS TRIGGER AS $awol$
        DECLARE
            awol_count INTEGER;
            threshold INTEGER := 3;
        BEGIN
            -- Count recent AWOL incidents for this account
            SELECT COUNT(*) INTO awol_count
            FROM account_awol_records
            WHERE account_id = NEW.account_id
            AND awol_date >= CURRENT_DATE - INTERVAL '30 days';

            -- Flag if threshold exceeded
            IF awol_count >= threshold THEN
                -- Could trigger notification or status change
                RAISE NOTICE 'AWOL pattern detected for account %: % incidents in last 30 days', NEW.account_id, awol_count;
            END IF;

            RETURN NEW;
        END;
        $awol$ LANGUAGE plpgsql;

        CREATE TRIGGER trigger_awol_detection
            AFTER INSERT ON account_awol_records
            FOR EACH ROW
            EXECUTE FUNCTION detect_awol_pattern();
    END IF;
END $$;

-- 5. Account Suspension Trigger (only if required tables exist)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'invoices') AND
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'business_accounts') THEN

        CREATE OR REPLACE FUNCTION check_account_suspension()
        RETURNS TRIGGER AS $suspension$
        DECLARE
            overdue_days INTEGER;
            suspension_threshold INTEGER := 30; -- days
        BEGIN
            -- Calculate overdue days
            SELECT EXTRACT(DAY FROM CURRENT_DATE - due_date) INTO overdue_days
            FROM invoices
            WHERE id = NEW.invoice_id AND status = 'overdue';

            IF overdue_days >= suspension_threshold THEN
                -- Mark account for suspension review
                UPDATE business_accounts
                SET suspension_recommended = true
                WHERE id = (SELECT account_id FROM invoices WHERE id = NEW.invoice_id);
            END IF;

            RETURN NEW;
        END;
        $suspension$ LANGUAGE plpgsql;

        -- Note: This would need to be attached to invoice status updates
    END IF;
END $$;

-- RPC Functions

-- 1. Get dashboard metrics (only if required tables exist)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sales_transactions') AND
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'transaction_items') AND
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'inventory_items') THEN

        CREATE OR REPLACE FUNCTION get_dashboard_metrics(start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days', end_date DATE DEFAULT CURRENT_DATE)
        RETURNS TABLE (
            total_sales DECIMAL(10,2),
            transaction_count BIGINT,
            avg_transaction DECIMAL(10,2),
            top_products JSON
        ) AS $dashboard$
        BEGIN
            RETURN QUERY
            SELECT
                COALESCE(SUM(s.total_amount), 0) as total_sales,
                COUNT(s.id) as transaction_count,
                COALESCE(AVG(s.total_amount), 0) as avg_transaction,
                COALESCE(json_agg(json_build_object('name', ii.name, 'quantity', SUM(ti.quantity))), '[]') as top_products
            FROM sales_transactions s
            LEFT JOIN transaction_items ti ON s.id = ti.sale_id
            LEFT JOIN inventory_items ii ON ti.inventory_item_id = ii.id
            WHERE s.created_at >= start_date AND s.created_at <= end_date + INTERVAL '1 day';
        END;
        $dashboard$ LANGUAGE plpgsql;
    END IF;
END $$;

-- 2. Calculate yield percentage
CREATE OR REPLACE FUNCTION calculate_yield_percentage(carcass_weight DECIMAL, cuts_weight DECIMAL)
RETURNS DECIMAL(5,2) AS $$
BEGIN
    IF carcass_weight > 0 THEN
        RETURN (cuts_weight / carcass_weight) * 100;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 3. Get inventory valuation (only if inventory_items table exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'inventory_items') THEN

        CREATE OR REPLACE FUNCTION get_inventory_valuation()
        RETURNS TABLE (
            total_value DECIMAL(10,2),
            total_items BIGINT,
            low_stock_items BIGINT
        ) AS $valuation$
        BEGIN
            RETURN QUERY
            SELECT
                COALESCE(SUM(ii.current_stock * ii.average_cost), 0) as total_value,
                COUNT(*) as total_items,
                COUNT(*) FILTER (WHERE ii.current_stock <= ii.reorder_point) as low_stock_items
            FROM inventory_items ii
            WHERE ii.is_active = true;
        END;
        $valuation$ LANGUAGE plpgsql;
    END IF;
END $$;

-- 4. Process payroll period (only if required tables exist)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'payroll_periods') AND
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') AND
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'payroll_entries') THEN

        CREATE OR REPLACE FUNCTION process_payroll_period(period_id UUID)
        RETURNS VOID AS $payroll$
        DECLARE
            period_record RECORD;
            staff_record RECORD;
        BEGIN
            -- Get period details
            SELECT * INTO period_record FROM payroll_periods WHERE id = period_id;

            IF period_record.status != 'open' THEN
                RAISE EXCEPTION 'Payroll period is not open for processing';
            END IF;

            -- Process each staff member
            FOR staff_record IN
                SELECT p.id, p.basic_salary, p.is_active
                FROM profiles p
                WHERE p.is_active = true
            LOOP
                -- Insert payroll entry (simplified - would need more complex logic)
                INSERT INTO payroll_entries (
                    payroll_period_id, staff_id, basic_salary
                ) VALUES (
                    period_id, staff_record.id, staff_record.basic_salary
                );
            END LOOP;

            -- Update period totals
            UPDATE payroll_periods
            SET status = 'completed',
                processed_at = NOW(),
                total_gross = (SELECT SUM(gross_pay) FROM payroll_entries WHERE payroll_period_id = period_id),
                total_deductions = (SELECT SUM(total_deductions) FROM payroll_entries WHERE payroll_period_id = period_id),
                total_net = (SELECT SUM(net_pay) FROM payroll_entries WHERE payroll_period_id = period_id)
            WHERE id = period_id;
        END;
        $payroll$ LANGUAGE plpgsql;
    END IF;
END $$;