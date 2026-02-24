--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: audit_trigger_function(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.audit_trigger_function() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_staff_id uuid;
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_log (action, table_name, record_id, new_value, severity, created_at)
    VALUES (TG_OP, TG_TABLE_NAME, NEW.id::text, to_jsonb(NEW), 'info', now());
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_log (action, table_name, record_id, old_value, new_value, severity, created_at)
    VALUES (TG_OP, TG_TABLE_NAME, NEW.id::text, to_jsonb(OLD), to_jsonb(NEW), 'info', now());
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_log (action, table_name, record_id, old_value, severity, created_at)
    VALUES (TG_OP, TG_TABLE_NAME, OLD.id::text, to_jsonb(OLD), 'info', now());
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: calculate_asset_depreciation(uuid, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_asset_depreciation(asset_id uuid, as_at_date date DEFAULT CURRENT_DATE) RETURNS numeric
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    v_purchase_price NUMERIC;
    v_purchase_date DATE;
    v_depreciation_rate NUMERIC;
    v_depreciation_method TEXT;
    v_status TEXT;
    v_book_value NUMERIC;
    v_years NUMERIC;
    v_accumulated_depreciation NUMERIC;
    v_current_value NUMERIC;
BEGIN
    -- Fetch asset details
    SELECT purchase_price, purchase_date, depreciation_rate, depreciation_method, status, current_value
    INTO v_purchase_price, v_purchase_date, v_depreciation_rate, v_depreciation_method, v_status, v_book_value
    FROM equipment_assets
    WHERE id = asset_id;
    
    -- If asset not found or written off, return 0
    IF v_status = 'written_off' OR v_purchase_price IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Calculate years in service (fractional)
    v_years := EXTRACT(DAY FROM (as_at_date - v_purchase_date)) / 365.25;
    
    -- Cannot have negative depreciation period
    IF v_years < 0 THEN
        RETURN v_purchase_price;
    END IF;
    
    -- Calculate depreciation based on method
    IF v_depreciation_method = 'straight_line' THEN
        -- Straight-line: depreciation = (purchase_price * depreciation_rate * years) / 100
        v_accumulated_depreciation := (v_purchase_price * v_depreciation_rate * v_years) / 100;
    ELSIF v_depreciation_method = 'diminishing' THEN
        -- Diminishing value: current_value = purchase_price * (1 - rate/100)^years
        -- Accumulated depreciation = purchase_price - current_value
        v_accumulated_depreciation := v_purchase_price - (v_purchase_price * POWER(1 - (v_depreciation_rate / 100), v_years));
    ELSE
        -- Default to straight-line if method is unknown
        v_accumulated_depreciation := (v_purchase_price * v_depreciation_rate * v_years) / 100;
    END IF;
    
    -- Current value = purchase_price - accumulated_depreciation, minimum 0
    v_current_value := GREATEST(0, v_purchase_price - v_accumulated_depreciation);
    
    RETURN ROUND(v_current_value, 2);
END;
$$;


--
-- Name: calculate_yield_percentage(numeric, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_yield_percentage(carcass_weight numeric, cuts_weight numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF carcass_weight > 0 THEN
        RETURN (cuts_weight / carcass_weight) * 100;
    ELSE
        RETURN 0;
    END IF;
END;
$$;


--
-- Name: check_account_suspension(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_account_suspension() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
        $$;


--
-- Name: check_reorder_threshold(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_reorder_threshold() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
        $$;


--
-- Name: check_shrinkage_threshold(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_shrinkage_threshold() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
    $$;


--
-- Name: deduct_stock_on_sale(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deduct_stock_on_sale() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF NEW.inventory_item_id IS NOT NULL AND NEW.quantity IS NOT NULL AND NEW.quantity > 0 THEN
            UPDATE inventory_items
            SET current_stock = GREATEST(0, COALESCE(current_stock, 0) - NEW.quantity)
            WHERE id = NEW.inventory_item_id;
        END IF;
        RETURN NEW;
    END;
    $$;


--
-- Name: detect_awol_pattern(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.detect_awol_pattern() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
        $$;


--
-- Name: get_dashboard_metrics(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_dashboard_metrics(start_date date DEFAULT (CURRENT_DATE - '30 days'::interval), end_date date DEFAULT CURRENT_DATE) RETURNS TABLE(total_sales numeric, transaction_count bigint, avg_transaction numeric, top_products json)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(SUM(t.total_amount), 0)::DECIMAL(10,2) as total_sales,
    COUNT(t.id)::BIGINT as transaction_count,
    COALESCE(AVG(t.total_amount), 0)::DECIMAL(10,2) as avg_transaction,
    COALESCE(
      (SELECT json_agg(agg) FROM (
        SELECT json_build_object('name', ii.name, 'quantity', SUM(ti.quantity)::DECIMAL) as agg
        FROM transaction_items ti
        LEFT JOIN inventory_items ii ON ti.inventory_item_id = ii.id
        WHERE ti.transaction_id IN (SELECT id FROM transactions WHERE created_at >= start_date AND created_at <= end_date + INTERVAL '1 day')
        GROUP BY ii.name
        LIMIT 20
      ) sub),
      '[]'::JSON
    ) as top_products
  FROM transactions t
  WHERE t.created_at >= start_date AND t.created_at <= end_date + INTERVAL '1 day';
END;
$$;


--
-- Name: get_inventory_valuation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_inventory_valuation() RETURNS TABLE(total_value numeric, total_items bigint, low_stock_items bigint)
    LANGUAGE plpgsql
    AS $$
        BEGIN
            RETURN QUERY
            SELECT
                COALESCE(SUM(ii.current_stock * ii.average_cost), 0) as total_value,
                COUNT(*) as total_items,
                COUNT(*) FILTER (WHERE ii.current_stock <= ii.reorder_point) as low_stock_items
            FROM inventory_items ii
            WHERE ii.is_active = true;
        END;
        $$;


--
-- Name: post_pos_sale_to_ledger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.post_pos_sale_to_ledger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
    $$;


--
-- Name: process_payroll_period(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.process_payroll_period(period_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
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
        $$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: validate_timecard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_timecard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Validate that clock_out is after clock_in if both are provided
    IF NEW.clock_in IS NOT NULL AND NEW.clock_out IS NOT NULL THEN
        IF NEW.clock_out <= NEW.clock_in THEN
            RAISE EXCEPTION 'clock_out must be after clock_in';
        END IF;
    END IF;
    
    -- Validate that break_minutes is not negative
    IF NEW.break_minutes < 0 THEN
        RAISE EXCEPTION 'break_minutes cannot be negative';
    END IF;
    
    -- Validate that breaks do not exceed shift duration
    IF NEW.clock_in IS NOT NULL AND NEW.clock_out IS NOT NULL AND NEW.break_minutes IS NOT NULL THEN
        IF NEW.break_minutes >= EXTRACT(EPOCH FROM (NEW.clock_out - NEW.clock_in)) / 60 THEN
            RAISE EXCEPTION 'break_minutes cannot exceed or equal total shift duration';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account_awol_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_awol_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    awol_date date NOT NULL,
    reason text,
    recorded_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: account_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    transaction_type text NOT NULL,
    reference text,
    description text,
    amount numeric(10,2) NOT NULL,
    running_balance numeric(10,2),
    payment_method text,
    proof_url text,
    recorded_by uuid,
    transaction_date date DEFAULT CURRENT_DATE NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT account_transactions_payment_method_check CHECK ((payment_method = ANY (ARRAY['EFT'::text, 'Cash'::text, 'Card'::text, 'Other'::text]))),
    CONSTRAINT account_transactions_transaction_type_check CHECK ((transaction_type = ANY (ARRAY['sale'::text, 'payment'::text])))
);


--
-- Name: announcements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.announcements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    content text NOT NULL,
    announcement_type text DEFAULT 'general'::text NOT NULL,
    priority text DEFAULT 'normal'::text NOT NULL,
    is_active boolean DEFAULT true,
    start_date date DEFAULT CURRENT_DATE NOT NULL,
    end_date date,
    target_audience text DEFAULT 'all'::text,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT announcements_announcement_type_check CHECK ((announcement_type = ANY (ARRAY['general'::text, 'promotion'::text, 'event'::text, 'maintenance'::text]))),
    CONSTRAINT announcements_priority_check CHECK ((priority = ANY (ARRAY['low'::text, 'normal'::text, 'high'::text, 'urgent'::text]))),
    CONSTRAINT announcements_target_audience_check CHECK ((target_audience = ANY (ARRAY['all'::text, 'customers'::text, 'staff'::text])))
);


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    action text NOT NULL,
    table_name text,
    record_id text,
    staff_id uuid,
    staff_name text,
    authorised_by uuid,
    authorised_name text,
    old_value jsonb,
    new_value jsonb,
    details text,
    severity text DEFAULT 'info'::text,
    ip_address text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT audit_log_severity_check CHECK ((severity = ANY (ARRAY['info'::text, 'warning'::text, 'critical'::text])))
);


--
-- Name: TABLE audit_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.audit_log IS 'Immutable system activity log; Module 14 Audit.';


--
-- Name: awol_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.awol_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    staff_id uuid NOT NULL,
    awol_date date NOT NULL,
    notes text,
    resolved boolean DEFAULT false,
    resolved_notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: business_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.business_accounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    account_type text,
    email text,
    phone text,
    balance numeric(15,2) DEFAULT 0,
    credit_limit numeric(15,2),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    contact_person text,
    whatsapp text,
    vat_number text,
    credit_terms_days integer DEFAULT 7,
    auto_suspend boolean DEFAULT false,
    auto_suspend_days integer DEFAULT 30,
    suspended boolean DEFAULT false,
    suspended_at timestamp with time zone,
    notes text,
    address text,
    active boolean DEFAULT true,
    suspension_recommended boolean DEFAULT false
);


--
-- Name: TABLE business_accounts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.business_accounts IS 'Business/credit accounts; referenced by account_transactions, invoices, account_awol_records.';


--
-- Name: business_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.business_settings (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    business_name text DEFAULT 'Struisbaai Vleismark'::text,
    trading_name text,
    address text,
    vat_number text,
    phone text,
    email text,
    logo_url text,
    working_hours_start time without time zone DEFAULT '07:00:00'::time without time zone,
    working_hours_end time without time zone DEFAULT '17:00:00'::time without time zone,
    overtime_after_daily numeric(4,2) DEFAULT 9.0,
    overtime_after_weekly numeric(5,2) DEFAULT 45.0,
    sunday_pay_multiplier numeric(4,2) DEFAULT 2.0,
    public_holiday_multiplier numeric(4,2) DEFAULT 2.0,
    blockman_verification boolean DEFAULT false,
    shrinkage_tolerance_pct numeric(5,2) DEFAULT 2.0,
    auto_void_parked_hours integer DEFAULT 4,
    receipt_footer text DEFAULT 'Thank you for your business!'::text,
    scale_brand text DEFAULT 'Ishida'::text,
    scale_weight_prefix integer DEFAULT 20,
    scale_price_prefix integer DEFAULT 21,
    scale_plu_digits integer DEFAULT 4,
    scale_primary_mode text DEFAULT 'price_embedded'::text,
    vat_standard numeric(5,2) DEFAULT 15.0,
    vat_zero_rated numeric(5,2) DEFAULT 0.0,
    event_spike_multiplier numeric(4,2) DEFAULT 2.0,
    currency_symbol text DEFAULT 'R'::text,
    country text DEFAULT 'ZA'::text,
    timezone text DEFAULT 'Africa/Johannesburg'::text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: carcass_breakdown_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.carcass_breakdown_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    intake_id uuid NOT NULL,
    carcass_number integer NOT NULL,
    actual_weight_kg numeric(8,2) NOT NULL,
    template_id uuid,
    started_at timestamp with time zone DEFAULT now(),
    completed_at timestamp with time zone,
    processed_by uuid NOT NULL,
    status text DEFAULT 'in_progress'::text NOT NULL,
    notes text,
    CONSTRAINT carcass_breakdown_sessions_carcass_number_check CHECK ((carcass_number > 0)),
    CONSTRAINT carcass_breakdown_sessions_status_check CHECK ((status = ANY (ARRAY['in_progress'::text, 'completed'::text, 'cancelled'::text])))
);


--
-- Name: carcass_cuts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.carcass_cuts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    carcass_id uuid NOT NULL,
    cut_name text NOT NULL,
    weight numeric(12,2),
    inventory_item_id uuid,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    intake_id uuid,
    expected_kg numeric,
    actual_kg numeric,
    plu_code integer,
    sellable boolean DEFAULT true,
    breakdown_date timestamp with time zone
);


--
-- Name: carcass_intakes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.carcass_intakes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    intake_date date NOT NULL,
    species text NOT NULL,
    supplier_id uuid,
    hunter_job_id uuid,
    weight_in numeric(12,2),
    weight_out numeric(12,2),
    status text NOT NULL,
    job_type text NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    remaining_weight numeric,
    variance_pct numeric,
    reference_number text,
    yield_template_id uuid,
    delivery_date date,
    carcass_type text,
    CONSTRAINT carcass_intakes_job_type_check CHECK ((job_type = ANY (ARRAY['retail'::text, 'hunter'::text]))),
    CONSTRAINT carcass_intakes_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'complete'::text])))
);


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    color_code text,
    sort_order integer DEFAULT 0,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    notes text,
    updated_at timestamp with time zone DEFAULT now(),
    is_active boolean DEFAULT true
);


--
-- Name: chart_of_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chart_of_accounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    account_type text NOT NULL,
    parent_id uuid,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    account_code text,
    account_name text,
    subcategory text,
    sort_order integer DEFAULT 0,
    CONSTRAINT chart_of_accounts_account_type_check CHECK ((account_type = ANY (ARRAY['asset'::text, 'liability'::text, 'equity'::text, 'income'::text, 'expense'::text])))
);


--
-- Name: TABLE chart_of_accounts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.chart_of_accounts IS 'Chart of accounts for ledger; 031 ensures account_code column exists for import.';


--
-- Name: COLUMN chart_of_accounts.parent_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.chart_of_accounts.parent_id IS 'H6: Parent account for tree display; null = top-level under type.';


--
-- Name: compliance_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.compliance_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    staff_id uuid NOT NULL,
    document_type text NOT NULL,
    expiry_date date,
    file_url text,
    is_verified boolean DEFAULT false,
    verified_by uuid,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE compliance_records; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.compliance_records IS 'H4: BCEA document compliance — one row per staff per document type; expiry and file link.';


--
-- Name: customer_announcements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_announcements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    channel text NOT NULL,
    sent_at timestamp with time zone,
    recipient_count integer,
    status text DEFAULT 'draft'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    image_url text,
    CONSTRAINT customer_announcements_channel_check CHECK ((channel = ANY (ARRAY['whatsapp'::text, 'sms'::text, 'both'::text]))),
    CONSTRAINT customer_announcements_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'sent'::text, 'failed'::text])))
);


--
-- Name: donations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.donations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    donor_name text NOT NULL,
    donation_type text NOT NULL,
    donation_value numeric(10,2),
    donation_date date DEFAULT CURRENT_DATE NOT NULL,
    payment_status text DEFAULT 'received'::text NOT NULL,
    contact_details text,
    purpose text,
    tax_certificate_issued boolean DEFAULT false,
    notes text,
    recorded_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT donations_donation_type_check CHECK ((donation_type = ANY (ARRAY['cash'::text, 'goods'::text, 'services'::text]))),
    CONSTRAINT donations_payment_status_check CHECK ((payment_status = ANY (ARRAY['received'::text, 'pending'::text, 'cancelled'::text])))
);


--
-- Name: dryer_batch_ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dryer_batch_ingredients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    batch_id uuid NOT NULL,
    inventory_item_id uuid NOT NULL,
    quantity_used numeric(10,3) NOT NULL,
    added_at timestamp with time zone DEFAULT now()
);


--
-- Name: dryer_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dryer_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    start_date date,
    end_date date,
    items jsonb,
    weight_in numeric(12,2),
    weight_out numeric(12,2),
    shrinkage_pct numeric(5,2) GENERATED ALWAYS AS (
CASE
    WHEN (weight_in > (0)::numeric) THEN (((weight_in - weight_out) / weight_in) * (100)::numeric)
    ELSE (0)::numeric
END) STORED,
    status text NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    input_product_id uuid,
    output_product_id uuid,
    recipe_id uuid,
    started_at timestamp with time zone DEFAULT now(),
    batch_number text DEFAULT 'DB-pending'::text,
    CONSTRAINT dryer_batches_status_check CHECK ((status = ANY (ARRAY['loading'::text, 'drying'::text, 'complete'::text])))
);


--
-- Name: COLUMN dryer_batches.input_product_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dryer_batches.input_product_id IS 'Blueprint: Raw material (e.g. beef topside)';


--
-- Name: COLUMN dryer_batches.output_product_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dryer_batches.output_product_id IS 'Blueprint: Finished product (e.g. biltong PLU)';


--
-- Name: COLUMN dryer_batches.recipe_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dryer_batches.recipe_id IS 'Optional recipe (spice ratios, curing method)';


--
-- Name: equipment_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.equipment_assets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    serial_number text,
    purchase_date date NOT NULL,
    purchase_price numeric(15,2) NOT NULL,
    current_value numeric(15,2),
    depreciation_rate numeric(5,2) DEFAULT 0 NOT NULL,
    depreciation_method text DEFAULT 'straight_line'::text NOT NULL,
    location text,
    status text DEFAULT 'active'::text NOT NULL,
    last_service_date date,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT equipment_assets_depreciation_method_check CHECK ((depreciation_method = ANY (ARRAY['straight_line'::text, 'diminishing'::text]))),
    CONSTRAINT equipment_assets_status_check CHECK ((status = ANY (ARRAY['active'::text, 'under_repair'::text, 'written_off'::text])))
);


--
-- Name: equipment_register; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.equipment_register (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    asset_number text NOT NULL,
    description text NOT NULL,
    category text NOT NULL,
    purchase_date date NOT NULL,
    purchase_price numeric(10,2) NOT NULL,
    supplier_name text,
    location text,
    depreciation_method text DEFAULT 'straight_line'::text,
    useful_life_years integer NOT NULL,
    salvage_value numeric(10,2) DEFAULT 0,
    accumulated_depreciation numeric(10,2) DEFAULT 0,
    current_value numeric(10,2) GENERATED ALWAYS AS ((purchase_price - accumulated_depreciation)) STORED,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_by uuid,
    service_log jsonb DEFAULT '[]'::jsonb,
    status text DEFAULT 'active'::text,
    depreciation_rate numeric(5,2),
    CONSTRAINT equipment_register_depreciation_method_check CHECK ((depreciation_method = ANY (ARRAY['straight_line'::text, 'declining_balance'::text, 'diminishing'::text]))),
    CONSTRAINT equipment_register_status_check CHECK ((status = ANY (ARRAY['active'::text, 'under_repair'::text, 'written_off'::text])))
);


--
-- Name: event_sales_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_sales_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    date date NOT NULL,
    sales_amount numeric(10,2) DEFAULT 0 NOT NULL,
    transaction_count integer DEFAULT 0 NOT NULL,
    avg_transaction numeric(10,2) GENERATED ALWAYS AS (
CASE
    WHEN (transaction_count > 0) THEN (sales_amount / (transaction_count)::numeric)
    ELSE (0)::numeric
END) STORED,
    top_products jsonb,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: event_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_tags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_name text NOT NULL,
    event_date date NOT NULL,
    notes text,
    affected_categories text[],
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: hunter_job_processes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hunter_job_processes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    job_id uuid NOT NULL,
    process_type text NOT NULL,
    started_at timestamp with time zone DEFAULT now(),
    completed_at timestamp with time zone,
    processed_by uuid NOT NULL,
    weight_before_kg numeric(8,2),
    weight_after_kg numeric(8,2),
    notes text,
    CONSTRAINT hunter_job_processes_process_type_check CHECK ((process_type = ANY (ARRAY['skinning'::text, 'quartering'::text, 'aging'::text, 'packaging'::text, 'freezing'::text])))
);


--
-- Name: hunter_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hunter_jobs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    job_date date NOT NULL,
    hunter_name text NOT NULL,
    contact_phone text,
    species text NOT NULL,
    weight_in numeric(12,2),
    processing_instructions jsonb,
    status text DEFAULT 'intake'::text NOT NULL,
    cuts jsonb DEFAULT '[]'::jsonb,
    charge_total numeric(15,2),
    paid boolean DEFAULT false,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    customer_name text,
    customer_phone text,
    animal_type text,
    estimated_weight numeric(8,2),
    total_amount numeric(10,2),
    CONSTRAINT hunter_jobs_status_check CHECK ((status = ANY (ARRAY['quoted'::text, 'confirmed'::text, 'in_progress'::text, 'completed'::text, 'cancelled'::text, 'intake'::text, 'processing'::text, 'ready'::text, 'collected'::text, 'Intake'::text, 'Processing'::text, 'Ready for Collection'::text, 'Completed'::text])))
);


--
-- Name: COLUMN hunter_jobs.weight_in; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.hunter_jobs.weight_in IS 'H1: Actual weight in (kg) after processing.';


--
-- Name: COLUMN hunter_jobs.processing_instructions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.hunter_jobs.processing_instructions IS 'H1: Selected cut names from intake.';


--
-- Name: COLUMN hunter_jobs.cuts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.hunter_jobs.cuts IS 'H1: Per-cut actual weight and linked inventory_item_id.';


--
-- Name: COLUMN hunter_jobs.paid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.hunter_jobs.paid IS 'H1: Mark paid on summary.';


--
-- Name: hunter_process_materials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hunter_process_materials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    process_id uuid NOT NULL,
    material_type text NOT NULL,
    item_name text NOT NULL,
    quantity_used numeric(10,3) NOT NULL,
    unit text NOT NULL,
    cost numeric(10,2),
    used_at timestamp with time zone DEFAULT now(),
    CONSTRAINT hunter_process_materials_material_type_check CHECK ((material_type = ANY (ARRAY['packaging'::text, 'labels'::text, 'supplies'::text])))
);


--
-- Name: hunter_service_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hunter_service_config (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    species text NOT NULL,
    base_rate numeric(12,2),
    per_kg_rate numeric(12,2),
    cut_options jsonb DEFAULT '[]'::jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: hunter_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hunter_services (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    base_price numeric(10,2) NOT NULL,
    price_per_kg numeric(10,2),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    cut_options jsonb DEFAULT '[]'::jsonb
);


--
-- Name: COLUMN hunter_services.cut_options; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.hunter_services.cut_options IS 'H1: Cut names for processing (e.g. ["Steaks","Mince","Biltong"]) per species.';


--
-- Name: inventory_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_items (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    plu_code integer NOT NULL,
    name text NOT NULL,
    pos_display_name text,
    scale_label_name text,
    sku text,
    barcode text,
    barcode_prefix text,
    item_type text,
    category text,
    sub_category text,
    scale_item boolean DEFAULT false,
    ishida_sync boolean DEFAULT false,
    text_lookup_code text,
    sell_price numeric(10,2),
    cost_price numeric(10,2),
    average_cost_price numeric(10,2),
    target_margin_pct numeric(5,2),
    freezer_markdown_pct numeric(5,2),
    vat_group text DEFAULT 'standard'::text,
    price_last_changed timestamp with time zone,
    stock_control_type text DEFAULT 'use_stock_control'::text,
    unit_type text DEFAULT 'kg'::text,
    allow_sell_by_fraction boolean DEFAULT true,
    pack_size numeric(10,3) DEFAULT 1,
    stock_on_hand_fresh numeric(10,3) DEFAULT 0,
    stock_on_hand_frozen numeric(10,3) DEFAULT 0,
    reorder_level numeric(10,3) DEFAULT 0,
    slow_moving_trigger_days integer DEFAULT 3,
    shelf_life_fresh integer,
    shelf_life_frozen integer,
    carcass_link text,
    recipe_link uuid,
    is_manufactured boolean DEFAULT false,
    dryer_product boolean DEFAULT false,
    supplier_id uuid,
    image_url text,
    dietary_tags text[],
    allergen_info text[],
    internal_notes text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    supplier_ids jsonb,
    average_cost numeric(10,2),
    storage_location_ids jsonb,
    carcass_link_id uuid,
    dryer_biltong_product boolean DEFAULT false,
    modifier_group_ids jsonb,
    recipe_id uuid,
    dryer_product_type text,
    manufactured_item boolean DEFAULT false,
    last_edited_by uuid,
    last_edited_at timestamp with time zone,
    category_id uuid,
    current_stock numeric(10,3) DEFAULT 0,
    product_type text DEFAULT 'raw'::text,
    CONSTRAINT inventory_items_barcode_prefix_check CHECK ((barcode_prefix = ANY (ARRAY['20'::text, '21'::text, 'none'::text]))),
    CONSTRAINT inventory_items_item_type_check CHECK ((item_type = ANY (ARRAY['own_cut'::text, 'own_processed'::text, 'third_party_resale'::text, 'service'::text, 'packaging'::text, 'internal'::text]))),
    CONSTRAINT inventory_items_product_type_check CHECK (((product_type IS NULL) OR (product_type = ANY (ARRAY['raw'::text, 'portioned'::text, 'manufactured'::text])))),
    CONSTRAINT inventory_items_stock_control_type_check CHECK ((stock_control_type = ANY (ARRAY['use_stock_control'::text, 'no_stock_control'::text, 'recipe_based'::text, 'carcass_linked'::text, 'hanger_count'::text]))),
    CONSTRAINT inventory_items_unit_type_check CHECK ((unit_type = ANY (ARRAY['kg'::text, 'units'::text, 'packs'::text]))),
    CONSTRAINT inventory_items_vat_group_check CHECK ((vat_group = ANY (ARRAY['standard'::text, 'zero_rated'::text, 'exempt'::text])))
);


--
-- Name: COLUMN inventory_items.product_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.inventory_items.product_type IS 'Blueprint: Raw (no processing), Portioned, Manufactured (recipe-based)';


--
-- Name: invoice_line_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice_line_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_id uuid NOT NULL,
    description text NOT NULL,
    quantity numeric(10,3) DEFAULT 1 NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    line_total numeric(10,2) GENERATED ALWAYS AS ((quantity * unit_price)) STORED,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: invoices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_number text NOT NULL,
    account_id uuid NOT NULL,
    invoice_date date NOT NULL,
    due_date date,
    line_items jsonb DEFAULT '[]'::jsonb,
    subtotal numeric(15,2),
    tax_rate numeric(5,2),
    tax_amount numeric(15,2),
    total numeric(15,2),
    status text DEFAULT 'draft'::text NOT NULL,
    payment_date date,
    created_by uuid,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    supplier_id uuid,
    CONSTRAINT invoices_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'pending_review'::text, 'approved'::text, 'sent'::text, 'paid'::text, 'overdue'::text, 'cancelled'::text])))
);


--
-- Name: COLUMN invoices.supplier_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.invoices.supplier_id IS 'Blueprint §9.1: Supplier for this invoice (supplier invoices)';


--
-- Name: leave_balances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leave_balances (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    employee_id uuid NOT NULL,
    annual_leave_balance numeric(5,2) DEFAULT 0,
    sick_leave_balance numeric(5,2) DEFAULT 0,
    family_leave_balance numeric(5,2) DEFAULT 3,
    last_updated timestamp with time zone DEFAULT now(),
    last_accrual_date date
);


--
-- Name: leave_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leave_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    staff_id uuid NOT NULL,
    leave_type text NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    days_requested numeric(5,2),
    status text DEFAULT 'pending'::text NOT NULL,
    approved_by uuid,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    employee_id uuid,
    CONSTRAINT leave_requests_leave_type_check CHECK ((leave_type = ANY (ARRAY['annual'::text, 'sick'::text, 'family'::text, 'unpaid'::text]))),
    CONSTRAINT leave_requests_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text])))
);


--
-- Name: TABLE leave_requests; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.leave_requests IS 'Staff leave requests; dashboard shows Pending. staff_id logically references staff_profiles(id).';


--
-- Name: ledger_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ledger_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid,
    entry_date date NOT NULL,
    description text,
    debit numeric(15,2) DEFAULT 0,
    credit numeric(15,2) DEFAULT 0,
    reference text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    source text,
    metadata jsonb,
    account_code text,
    account_name text,
    reference_type text,
    reference_id uuid,
    recorded_by uuid
);


--
-- Name: COLUMN ledger_entries.source; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ledger_entries.source IS 'Event that created this entry: pos_sale, invoice, payment_received, waste, donation, sponsorship, payroll, purchase_sale_repayment';


--
-- Name: COLUMN ledger_entries.metadata; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ledger_entries.metadata IS 'Extra context: transaction_id, amount_net, vat, cost, etc.';


--
-- Name: COLUMN ledger_entries.account_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ledger_entries.account_code IS 'Denormalized for admin app; also used when account_id not set.';


--
-- Name: COLUMN ledger_entries.recorded_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.ledger_entries.recorded_by IS 'Admin app: staff who recorded (profiles.id).';


--
-- Name: loyalty_customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loyalty_customers (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    full_name text NOT NULL,
    email text,
    phone text,
    whatsapp text,
    birthday date,
    physical_address text,
    loyalty_tier text DEFAULT 'member'::text,
    points_balance integer DEFAULT 0,
    total_spend numeric(12,2) DEFAULT 0,
    visit_count integer DEFAULT 0,
    favourite_products text[],
    notes text,
    active boolean DEFAULT true,
    joined_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    tags jsonb DEFAULT '[]'::jsonb,
    CONSTRAINT loyalty_customers_loyalty_tier_check CHECK ((loyalty_tier = ANY (ARRAY['member'::text, 'elite'::text, 'vip'::text])))
);


--
-- Name: message_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    message_sid text,
    to_number text NOT NULL,
    message_content text,
    status text NOT NULL,
    error_message text,
    sent_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE message_logs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.message_logs IS 'WhatsApp/SMS message audit trail; used by WhatsAppService.';


--
-- Name: modifier_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modifier_groups (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    required boolean DEFAULT false,
    allow_multiple boolean DEFAULT false,
    max_selections integer DEFAULT 1,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    is_required boolean DEFAULT false,
    updated_at timestamp with time zone DEFAULT now(),
    sort_order integer DEFAULT 0
);


--
-- Name: COLUMN modifier_groups.allow_multiple; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.modifier_groups.allow_multiple IS 'Blueprint: Allow Multiple? (pick one = false)';


--
-- Name: COLUMN modifier_groups.max_selections; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.modifier_groups.max_selections IS 'Blueprint: Max Selections (e.g. 1)';


--
-- Name: COLUMN modifier_groups.is_required; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.modifier_groups.is_required IS 'Blueprint: Required? (optional = false)';


--
-- Name: COLUMN modifier_groups.sort_order; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.modifier_groups.sort_order IS 'Blueprint §4.3: Display order for modifier groups';


--
-- Name: modifier_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modifier_items (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    modifier_group_id uuid NOT NULL,
    name text NOT NULL,
    price_adjustment numeric(10,2) DEFAULT 0,
    track_inventory boolean DEFAULT false,
    linked_item_id uuid,
    sort_order integer DEFAULT 0,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    inventory_item_id uuid,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: COLUMN modifier_items.track_inventory; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.modifier_items.track_inventory IS 'Blueprint: Track Inventory?';


--
-- Name: COLUMN modifier_items.inventory_item_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.modifier_items.inventory_item_id IS 'Blueprint: Linked Item (inventory product)';


--
-- Name: payroll_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payroll_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    staff_id uuid NOT NULL,
    pay_period_start date NOT NULL,
    pay_period_end date NOT NULL,
    pay_frequency text NOT NULL,
    gross_pay numeric(12,2),
    deductions numeric(12,2),
    net_pay numeric(12,2),
    status text DEFAULT 'draft'::text NOT NULL,
    approved_by uuid,
    paid_at timestamp with time zone,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT payroll_entries_pay_frequency_check CHECK ((pay_frequency = ANY (ARRAY['weekly'::text, 'fortnightly'::text, 'monthly'::text]))),
    CONSTRAINT payroll_entries_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'approved'::text, 'paid'::text])))
);


--
-- Name: payroll_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payroll_periods (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    period_name text NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    processed_at timestamp with time zone,
    processed_by uuid,
    total_gross numeric(10,2) DEFAULT 0,
    total_deductions numeric(10,2) DEFAULT 0,
    total_net numeric(10,2) DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT payroll_periods_status_check CHECK ((status = ANY (ARRAY['open'::text, 'processing'::text, 'completed'::text, 'closed'::text])))
);


--
-- Name: printer_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.printer_config (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text,
    ip_address text,
    port integer DEFAULT 9100,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: product_suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_suppliers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    inventory_item_id uuid NOT NULL,
    supplier_id uuid NOT NULL,
    supplier_product_code text,
    supplier_product_name text,
    unit_price numeric(12,2),
    lead_time_days integer,
    is_preferred boolean DEFAULT false,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE product_suppliers; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.product_suppliers IS 'Blueprint H6: Multiple suppliers per product; supplier-specific codes and pricing.';


--
-- Name: production_batch_ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.production_batch_ingredients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    batch_id uuid NOT NULL,
    ingredient_id uuid NOT NULL,
    planned_quantity numeric(10,3) NOT NULL,
    actual_quantity numeric(10,3),
    used_at timestamp with time zone DEFAULT now()
);


--
-- Name: production_batch_outputs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.production_batch_outputs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    batch_id uuid NOT NULL,
    inventory_item_id uuid NOT NULL,
    qty_produced numeric NOT NULL,
    unit text NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: production_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.production_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    batch_date date NOT NULL,
    recipe_id uuid,
    qty_produced numeric(12,2),
    unit text,
    cost_total numeric(15,2),
    notes text,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    output_product_id uuid,
    CONSTRAINT production_batches_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'complete'::text])))
);


--
-- Name: COLUMN production_batches.output_product_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.production_batches.output_product_id IS 'Output product to add on completion (from recipe)';


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    full_name text NOT NULL,
    role text NOT NULL,
    pin_hash text NOT NULL,
    phone text,
    email text,
    id_number text,
    start_date date,
    employment_type text,
    hourly_rate numeric(10,2),
    monthly_salary numeric(10,2),
    payroll_frequency text,
    max_discount_pct numeric(5,2) DEFAULT 5.0,
    bank_name text,
    bank_account text,
    bank_branch_code text,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_active boolean DEFAULT true,
    CONSTRAINT profiles_employment_type_check CHECK ((employment_type = ANY (ARRAY['hourly'::text, 'weekly_salary'::text, 'monthly_salary'::text]))),
    CONSTRAINT profiles_payroll_frequency_check CHECK ((payroll_frequency = ANY (ARRAY['weekly'::text, 'monthly'::text]))),
    CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['owner'::text, 'manager'::text, 'cashier'::text, 'blockman'::text])))
);


--
-- Name: purchase_order_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_order_lines (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    purchase_order_id uuid NOT NULL,
    inventory_item_id uuid NOT NULL,
    quantity numeric(12,3) DEFAULT 0 NOT NULL,
    unit text DEFAULT 'kg'::text,
    unit_price numeric(12,2),
    line_total numeric(12,2),
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: purchase_orders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    po_number text NOT NULL,
    supplier_id uuid NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    order_date date DEFAULT CURRENT_DATE NOT NULL,
    expected_date date,
    notes text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT purchase_orders_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'sent'::text, 'confirmed'::text, 'received'::text, 'cancelled'::text])))
);


--
-- Name: TABLE purchase_orders; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.purchase_orders IS 'Blueprint H7: Purchase orders — supplier first; multiple products; save/download/send.';


--
-- Name: purchase_sale_agreement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_sale_agreement (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agreement_number text NOT NULL,
    agreement_type text NOT NULL,
    party_name text NOT NULL,
    party_contact text,
    asset_description text NOT NULL,
    agreed_price numeric(10,2) NOT NULL,
    agreement_date date DEFAULT CURRENT_DATE NOT NULL,
    completion_date date,
    status text DEFAULT 'draft'::text NOT NULL,
    payment_terms text,
    special_conditions text,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    account_id uuid,
    CONSTRAINT purchase_sale_agreement_agreement_type_check CHECK ((agreement_type = ANY (ARRAY['purchase'::text, 'sale'::text]))),
    CONSTRAINT purchase_sale_agreement_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'signed'::text, 'completed'::text, 'cancelled'::text])))
);


--
-- Name: COLUMN purchase_sale_agreement.account_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.purchase_sale_agreement.account_id IS 'H5: Business account this agreement relates to (for Account Detail Agreements tab).';


--
-- Name: purchase_sale_agreements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_sale_agreements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agreement_type text NOT NULL,
    account_id uuid NOT NULL,
    description text,
    amount numeric(15,2),
    deposit_paid numeric(15,2) DEFAULT 0,
    balance_due numeric(15,2) GENERATED ALWAYS AS ((COALESCE(amount, (0)::numeric) - COALESCE(deposit_paid, (0)::numeric))) STORED,
    agreement_date date NOT NULL,
    completion_date date,
    status text DEFAULT 'pending'::text NOT NULL,
    file_url text,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT purchase_sale_agreements_agreement_type_check CHECK ((agreement_type = ANY (ARRAY['purchase'::text, 'sale'::text]))),
    CONSTRAINT purchase_sale_agreements_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'active'::text, 'completed'::text, 'cancelled'::text])))
);


--
-- Name: purchase_sale_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_sale_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agreement_id uuid NOT NULL,
    payment_date date NOT NULL,
    amount numeric(10,2) NOT NULL,
    payment_method text NOT NULL,
    reference_number text,
    notes text,
    recorded_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: recipe_ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipe_ingredients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    recipe_id uuid NOT NULL,
    inventory_item_id uuid,
    ingredient_name text NOT NULL,
    quantity numeric(10,3) NOT NULL,
    unit text NOT NULL,
    sort_order integer DEFAULT 0,
    is_optional boolean DEFAULT false,
    notes text
);


--
-- Name: recipes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    category text,
    ingredients jsonb,
    instructions text,
    yield_qty numeric(12,2),
    yield_unit text,
    cost_per_unit numeric(12,2),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    output_product_id uuid,
    expected_yield_pct numeric(5,2) DEFAULT 100,
    batch_size_kg numeric(10,3) DEFAULT 1,
    cook_time_minutes bigint,
    created_by uuid
);


--
-- Name: COLUMN recipes.output_product_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.recipes.output_product_id IS 'Blueprint: Output Product (e.g. Boerewors Traditional)';


--
-- Name: COLUMN recipes.expected_yield_pct; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.recipes.expected_yield_pct IS 'Blueprint: Expected Yield % (e.g. 95 = 5% loss)';


--
-- Name: COLUMN recipes.batch_size_kg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.recipes.batch_size_kg IS 'Blueprint: Ingredient quantities are per this batch size (e.g. 10 kg)';


--
-- Name: COLUMN recipes.cook_time_minutes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.recipes.cook_time_minutes IS 'time taken to make';


--
-- Name: COLUMN recipes.created_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.recipes.created_by IS 'Staff who created the recipe (audit); may reference staff_profiles(id) or profiles(id).';


--
-- Name: reorder_recommendations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reorder_recommendations (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    item_id uuid NOT NULL,
    days_of_stock numeric(5,1),
    urgency text,
    recommended_qty numeric(10,3),
    based_on_days integer DEFAULT 7,
    auto_resolved boolean DEFAULT false,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT reorder_recommendations_urgency_check CHECK ((urgency = ANY (ARRAY['urgent'::text, 'soon'::text, 'ok'::text])))
);


--
-- Name: TABLE reorder_recommendations; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.reorder_recommendations IS 'Low-stock alerts; populated by trigger on stock_movements (003). item_id logically references inventory_items(id).';


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    role_name text NOT NULL,
    permissions jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: sales_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    receipt_number text,
    total_amount numeric(10,2) DEFAULT 0.00 NOT NULL,
    tax_amount numeric(10,2) DEFAULT 0.00,
    payment_method text,
    staff_id uuid,
    status text DEFAULT 'completed'::text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: scale_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scale_config (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    primary_mode text DEFAULT 'Price-embedded'::text,
    plu_digits integer DEFAULT 4,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE scale_config; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.scale_config IS 'Scale/hardware config; used by SettingsRepository getScaleConfig/updateScaleConfig.';


--
-- Name: shrinkage_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shrinkage_alerts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid NOT NULL,
    alert_date date NOT NULL,
    expected_qty numeric(12,2),
    actual_qty numeric(12,2),
    variance_pct numeric(5,2),
    acknowledged boolean DEFAULT false,
    acknowledged_by uuid,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    resolved boolean DEFAULT false,
    resolved_by uuid,
    resolved_at timestamp with time zone,
    resolution_notes text,
    product_id uuid,
    item_name text,
    status text DEFAULT 'Pending'::text,
    theoretical_stock numeric(12,3),
    actual_stock numeric(12,3),
    gap_amount numeric(12,3),
    gap_percentage numeric(5,2),
    possible_reasons text,
    staff_involved text,
    shrinkage_percentage numeric(5,2),
    alert_type text,
    batch_id uuid,
    expected_weight numeric(10,2),
    actual_weight numeric(10,2)
);


--
-- Name: TABLE shrinkage_alerts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.shrinkage_alerts IS 'Blueprint §10.1: Mass-balance and production shrinkage alerts; dashboard shows unresolved, analytics uses status.';


--
-- Name: sponsorships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sponsorships (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sponsor_name text NOT NULL,
    event_name text NOT NULL,
    sponsorship_amount numeric(10,2) NOT NULL,
    sponsorship_date date DEFAULT CURRENT_DATE NOT NULL,
    payment_status text DEFAULT 'pending'::text NOT NULL,
    contact_person text,
    contact_details text,
    benefits_provided text,
    notes text,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT sponsorships_payment_status_check CHECK ((payment_status = ANY (ARRAY['pending'::text, 'paid'::text, 'cancelled'::text])))
);


--
-- Name: staff_awol_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_awol_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    staff_id uuid NOT NULL,
    awol_date date NOT NULL,
    expected_start_time time without time zone,
    notified_owner_manager boolean DEFAULT false,
    notified_who text,
    resolution text DEFAULT 'pending'::text NOT NULL,
    written_warning_issued boolean DEFAULT false,
    warning_document_url text,
    notes text,
    recorded_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT staff_awol_records_resolution_check CHECK ((resolution = ANY (ARRAY['returned'::text, 'resigned'::text, 'dismissed'::text, 'warning_issued'::text, 'pending'::text])))
);


--
-- Name: TABLE staff_awol_records; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.staff_awol_records IS 'Blueprint §7.3a: Staff absconding (AWOL) — links to disciplinary file; 3+ incidents = persistent AWOL flag.';


--
-- Name: staff_credit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_credit (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    staff_id uuid NOT NULL,
    credit_amount numeric(10,2) NOT NULL,
    reason text NOT NULL,
    granted_date date DEFAULT CURRENT_DATE NOT NULL,
    due_date date,
    is_paid boolean DEFAULT false,
    paid_date date,
    granted_by uuid NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    credit_type text DEFAULT 'meat_purchase'::text,
    items_purchased text,
    repayment_plan text,
    deduct_from text DEFAULT 'next_payroll'::text,
    status text DEFAULT 'pending'::text NOT NULL,
    CONSTRAINT staff_credit_credit_type_check CHECK ((credit_type = ANY (ARRAY['meat_purchase'::text, 'salary_advance'::text, 'loan'::text, 'deduction'::text, 'repayment'::text, 'other'::text]))),
    CONSTRAINT staff_credit_deduct_from_check CHECK ((deduct_from = ANY (ARRAY['next_payroll'::text, 'specific_period'::text]))),
    CONSTRAINT staff_credit_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'deducted'::text, 'partial'::text, 'cleared'::text])))
);


--
-- Name: COLUMN staff_credit.credit_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.staff_credit.credit_type IS 'H3: meat_purchase | salary_advance | loan | deduction | repayment | other';


--
-- Name: COLUMN staff_credit.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.staff_credit.status IS 'pending | deducted | partial | cleared';


--
-- Name: staff_credits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_credits (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    staff_id uuid NOT NULL,
    credit_date date NOT NULL,
    amount numeric(12,2),
    reason text,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: staff_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_documents (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    employee_id uuid NOT NULL,
    doc_type text NOT NULL,
    file_name text NOT NULL,
    file_url text NOT NULL,
    uploaded_by uuid,
    uploaded_at timestamp with time zone DEFAULT now(),
    notes text,
    CONSTRAINT staff_documents_doc_type_check CHECK ((doc_type = ANY (ARRAY['id_copy'::text, 'contract'::text, 'tax_form'::text, 'training_cert'::text, 'disciplinary'::text, 'other'::text])))
);


--
-- Name: staff_loans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_loans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    staff_id uuid NOT NULL,
    loan_amount numeric(10,2) NOT NULL,
    interest_rate numeric(5,2) DEFAULT 0,
    term_months integer,
    monthly_payment numeric(10,2),
    granted_date date DEFAULT CURRENT_DATE NOT NULL,
    first_payment_date date,
    is_active boolean DEFAULT true,
    granted_by uuid NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: staff_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    full_name text NOT NULL,
    role text NOT NULL,
    pin_hash text NOT NULL,
    phone text,
    hire_date date,
    pay_frequency text NOT NULL,
    hourly_rate numeric(10,2),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    email text,
    id_number text,
    employment_type text,
    monthly_salary numeric,
    max_discount_pct numeric DEFAULT 5.0,
    bank_name text,
    bank_account text,
    bank_branch_code text,
    notes text,
    CONSTRAINT staff_profiles_pay_frequency_check CHECK ((pay_frequency = ANY (ARRAY['weekly'::text, 'fortnightly'::text, 'monthly'::text])))
);


--
-- Name: stock_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_locations (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    type text,
    sort_order integer DEFAULT 0,
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT stock_locations_type_check CHECK ((type = ANY (ARRAY['display_fridge'::text, 'walk_in_fridge'::text, 'deep_freezer'::text, 'deli_counter'::text, 'dry_store'::text, 'dryer'::text, 'other'::text])))
);


--
-- Name: stock_movements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_movements (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    item_id uuid NOT NULL,
    movement_type text NOT NULL,
    quantity numeric(10,3) NOT NULL,
    unit_type text DEFAULT 'kg'::text,
    location_from uuid,
    location_to uuid,
    balance_after numeric(10,3),
    reference_id text,
    reference_type text,
    reason text,
    staff_id uuid,
    photo_url text,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    CONSTRAINT stock_movements_movement_type_check CHECK ((movement_type = ANY (ARRAY['in'::text, 'out'::text, 'adjustment'::text, 'transfer'::text, 'waste'::text, 'production'::text, 'donation'::text, 'sponsorship'::text, 'staff_meal'::text, 'freezer'::text])))
);


--
-- Name: COLUMN stock_movements.metadata; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.stock_movements.metadata IS 'Blueprint §4.5: donation (recipient, type, value), sponsorship (recipient, event, value), waste (reason, staff, photo_url), freezer (markdown_pct)';


--
-- Name: stock_take_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_take_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    session_id uuid NOT NULL,
    item_id uuid NOT NULL,
    location_id uuid,
    expected_quantity numeric(10,3) DEFAULT 0 NOT NULL,
    actual_quantity numeric(10,3),
    variance numeric(10,3) GENERATED ALWAYS AS (
CASE
    WHEN (actual_quantity IS NOT NULL) THEN (actual_quantity - expected_quantity)
    ELSE NULL::numeric
END) STORED,
    counted_by uuid,
    device_id text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE stock_take_entries; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.stock_take_entries IS 'Blueprint §4.7: One row per (session, item, location); conflicts when same (session,item,location) from different devices resolved before approval';


--
-- Name: COLUMN stock_take_entries.device_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.stock_take_entries.device_id IS 'Multi-device: identifier of counting device for conflict detection';


--
-- Name: stock_take_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_take_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    started_at timestamp with time zone DEFAULT now(),
    started_by uuid,
    approved_at timestamp with time zone,
    approved_by uuid,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT stock_take_sessions_status_check CHECK ((status = ANY (ARRAY['open'::text, 'in_progress'::text, 'pending_approval'::text, 'approved'::text, 'cancelled'::text])))
);


--
-- Name: TABLE stock_take_sessions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.stock_take_sessions IS 'Blueprint §4.7: Multi-device stock-take — one open session at a time';


--
-- Name: stock_takes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_takes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    take_date date NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    device_count integer,
    entries jsonb DEFAULT '[]'::jsonb,
    variances jsonb DEFAULT '[]'::jsonb,
    completed_at timestamp with time zone,
    approved_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT stock_takes_status_check CHECK ((status = ANY (ARRAY['open'::text, 'in_progress'::text, 'complete'::text])))
);


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppliers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    contact_name text,
    phone text,
    email text,
    account_number text,
    notes text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    vat_number text,
    address text,
    city text,
    postal_code text,
    payment_terms text,
    bank_name text,
    bank_account text,
    bank_branch_code text,
    bbbee_level text
);


--
-- Name: TABLE suppliers; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.suppliers IS 'Blueprint §4.6: Supplier Management';


--
-- Name: COLUMN suppliers.payment_terms; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.suppliers.payment_terms IS 'e.g. COD / 7 days / 14 days / 30 days';


--
-- Name: COLUMN suppliers.bbbee_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.suppliers.bbbee_level IS 'e.g. Level 2';


--
-- Name: system_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_config (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    key text NOT NULL,
    description text,
    value jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE system_config; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.system_config IS 'System/notification config keys; used by SettingsRepository getSystemConfig, toggleNotification.';


--
-- Name: tax_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tax_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    percentage numeric(5,2) DEFAULT 0.00 NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE tax_rules; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.tax_rules IS 'Tax rules (e.g. VAT); used by SettingsRepository getTaxRules, createTaxRule, deleteTaxRule.';


--
-- Name: timecards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.timecards (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    staff_id uuid NOT NULL,
    shift_date date NOT NULL,
    clock_in timestamp with time zone,
    clock_out timestamp with time zone,
    break_minutes integer DEFAULT 0,
    break_detail jsonb,
    total_hours numeric(5,2) GENERATED ALWAYS AS (
CASE
    WHEN ((clock_in IS NOT NULL) AND (clock_out IS NOT NULL)) THEN round(((EXTRACT(epoch FROM (clock_out - clock_in)) / (3600)::numeric) - ((break_minutes)::numeric / (60)::numeric)), 2)
    ELSE NULL::numeric
END) STORED,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    employee_id uuid
);


--
-- Name: TABLE timecards; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.timecards IS 'Clock-in/out records; dashboard shows who is clocked in today. May be populated by Clock-In app. staff_id logically references staff_profiles(id).';


--
-- Name: transaction_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transaction_id uuid NOT NULL,
    inventory_item_id uuid,
    quantity numeric(12,3) DEFAULT 0 NOT NULL,
    unit_price numeric(12,2) DEFAULT 0 NOT NULL,
    line_total numeric(12,2) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    total_amount numeric(12,2) DEFAULT 0 NOT NULL,
    cost_amount numeric(12,2),
    payment_method text,
    till_session_id uuid,
    staff_id uuid,
    account_id uuid,
    notes text,
    vat_amount numeric(12,2) DEFAULT 0
);


--
-- Name: yield_template_cuts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yield_template_cuts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid NOT NULL,
    cut_name text NOT NULL,
    expected_percentage numeric(5,2) NOT NULL,
    expected_weight_kg numeric(8,2),
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT yield_template_cuts_expected_percentage_check CHECK (((expected_percentage > (0)::numeric) AND (expected_percentage <= (100)::numeric)))
);


--
-- Name: yield_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.yield_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    species text NOT NULL,
    cuts jsonb DEFAULT '[]'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    carcass_type text,
    template_name text
);


--
-- Name: account_awol_records account_awol_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_awol_records
    ADD CONSTRAINT account_awol_records_pkey PRIMARY KEY (id);


--
-- Name: account_transactions account_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions
    ADD CONSTRAINT account_transactions_pkey PRIMARY KEY (id);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: awol_records awol_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awol_records
    ADD CONSTRAINT awol_records_pkey PRIMARY KEY (id);


--
-- Name: business_accounts business_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_accounts
    ADD CONSTRAINT business_accounts_pkey PRIMARY KEY (id);


--
-- Name: business_settings business_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.business_settings
    ADD CONSTRAINT business_settings_pkey PRIMARY KEY (id);


--
-- Name: carcass_breakdown_sessions carcass_breakdown_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carcass_breakdown_sessions
    ADD CONSTRAINT carcass_breakdown_sessions_pkey PRIMARY KEY (id);


--
-- Name: carcass_cuts carcass_cuts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carcass_cuts
    ADD CONSTRAINT carcass_cuts_pkey PRIMARY KEY (id);


--
-- Name: carcass_intakes carcass_intakes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carcass_intakes
    ADD CONSTRAINT carcass_intakes_pkey PRIMARY KEY (id);


--
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: chart_of_accounts chart_of_accounts_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chart_of_accounts
    ADD CONSTRAINT chart_of_accounts_code_key UNIQUE (code);


--
-- Name: chart_of_accounts chart_of_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chart_of_accounts
    ADD CONSTRAINT chart_of_accounts_pkey PRIMARY KEY (id);


--
-- Name: compliance_records compliance_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compliance_records
    ADD CONSTRAINT compliance_records_pkey PRIMARY KEY (id);


--
-- Name: customer_announcements customer_announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_announcements
    ADD CONSTRAINT customer_announcements_pkey PRIMARY KEY (id);


--
-- Name: donations donations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_pkey PRIMARY KEY (id);


--
-- Name: dryer_batch_ingredients dryer_batch_ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dryer_batch_ingredients
    ADD CONSTRAINT dryer_batch_ingredients_pkey PRIMARY KEY (id);


--
-- Name: dryer_batches dryer_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dryer_batches
    ADD CONSTRAINT dryer_batches_pkey PRIMARY KEY (id);


--
-- Name: equipment_assets equipment_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipment_assets
    ADD CONSTRAINT equipment_assets_pkey PRIMARY KEY (id);


--
-- Name: equipment_assets equipment_assets_serial_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipment_assets
    ADD CONSTRAINT equipment_assets_serial_number_key UNIQUE (serial_number);


--
-- Name: equipment_register equipment_register_asset_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipment_register
    ADD CONSTRAINT equipment_register_asset_number_key UNIQUE (asset_number);


--
-- Name: equipment_register equipment_register_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipment_register
    ADD CONSTRAINT equipment_register_pkey PRIMARY KEY (id);


--
-- Name: event_sales_history event_sales_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_sales_history
    ADD CONSTRAINT event_sales_history_pkey PRIMARY KEY (id);


--
-- Name: event_tags event_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_tags
    ADD CONSTRAINT event_tags_pkey PRIMARY KEY (id);


--
-- Name: hunter_job_processes hunter_job_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hunter_job_processes
    ADD CONSTRAINT hunter_job_processes_pkey PRIMARY KEY (id);


--
-- Name: hunter_jobs hunter_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hunter_jobs
    ADD CONSTRAINT hunter_jobs_pkey PRIMARY KEY (id);


--
-- Name: hunter_process_materials hunter_process_materials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hunter_process_materials
    ADD CONSTRAINT hunter_process_materials_pkey PRIMARY KEY (id);


--
-- Name: hunter_service_config hunter_service_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hunter_service_config
    ADD CONSTRAINT hunter_service_config_pkey PRIMARY KEY (id);


--
-- Name: hunter_service_config hunter_service_config_species_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hunter_service_config
    ADD CONSTRAINT hunter_service_config_species_key UNIQUE (species);


--
-- Name: hunter_services hunter_services_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hunter_services
    ADD CONSTRAINT hunter_services_name_key UNIQUE (name);


--
-- Name: hunter_services hunter_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hunter_services
    ADD CONSTRAINT hunter_services_pkey PRIMARY KEY (id);


--
-- Name: inventory_items inventory_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_pkey PRIMARY KEY (id);


--
-- Name: inventory_items inventory_items_plu_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_plu_code_key UNIQUE (plu_code);


--
-- Name: invoice_line_items invoice_line_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_line_items
    ADD CONSTRAINT invoice_line_items_pkey PRIMARY KEY (id);


--
-- Name: invoices invoices_invoice_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_invoice_number_key UNIQUE (invoice_number);


--
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: leave_balances leave_balances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_pkey PRIMARY KEY (id);


--
-- Name: leave_requests leave_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT leave_requests_pkey PRIMARY KEY (id);


--
-- Name: ledger_entries ledger_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT ledger_entries_pkey PRIMARY KEY (id);


--
-- Name: loyalty_customers loyalty_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loyalty_customers
    ADD CONSTRAINT loyalty_customers_pkey PRIMARY KEY (id);


--
-- Name: message_logs message_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_logs
    ADD CONSTRAINT message_logs_pkey PRIMARY KEY (id);


--
-- Name: modifier_groups modifier_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifier_groups
    ADD CONSTRAINT modifier_groups_pkey PRIMARY KEY (id);


--
-- Name: modifier_items modifier_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifier_items
    ADD CONSTRAINT modifier_items_pkey PRIMARY KEY (id);


--
-- Name: payroll_entries payroll_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_entries
    ADD CONSTRAINT payroll_entries_pkey PRIMARY KEY (id);


--
-- Name: payroll_periods payroll_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_periods
    ADD CONSTRAINT payroll_periods_pkey PRIMARY KEY (id);


--
-- Name: printer_config printer_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.printer_config
    ADD CONSTRAINT printer_config_pkey PRIMARY KEY (id);


--
-- Name: product_suppliers product_suppliers_inventory_item_id_supplier_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_suppliers
    ADD CONSTRAINT product_suppliers_inventory_item_id_supplier_id_key UNIQUE (inventory_item_id, supplier_id);


--
-- Name: product_suppliers product_suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_suppliers
    ADD CONSTRAINT product_suppliers_pkey PRIMARY KEY (id);


--
-- Name: production_batch_ingredients production_batch_ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_batch_ingredients
    ADD CONSTRAINT production_batch_ingredients_pkey PRIMARY KEY (id);


--
-- Name: production_batch_outputs production_batch_outputs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_batch_outputs
    ADD CONSTRAINT production_batch_outputs_pkey PRIMARY KEY (id);


--
-- Name: production_batches production_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_batches
    ADD CONSTRAINT production_batches_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: purchase_order_lines purchase_order_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_lines
    ADD CONSTRAINT purchase_order_lines_pkey PRIMARY KEY (id);


--
-- Name: purchase_orders purchase_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (id);


--
-- Name: purchase_orders purchase_orders_po_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_po_number_key UNIQUE (po_number);


--
-- Name: purchase_sale_agreement purchase_sale_agreement_agreement_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_sale_agreement
    ADD CONSTRAINT purchase_sale_agreement_agreement_number_key UNIQUE (agreement_number);


--
-- Name: purchase_sale_agreement purchase_sale_agreement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_sale_agreement
    ADD CONSTRAINT purchase_sale_agreement_pkey PRIMARY KEY (id);


--
-- Name: purchase_sale_agreements purchase_sale_agreements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_sale_agreements
    ADD CONSTRAINT purchase_sale_agreements_pkey PRIMARY KEY (id);


--
-- Name: purchase_sale_payments purchase_sale_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_sale_payments
    ADD CONSTRAINT purchase_sale_payments_pkey PRIMARY KEY (id);


--
-- Name: recipe_ingredients recipe_ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_ingredients
    ADD CONSTRAINT recipe_ingredients_pkey PRIMARY KEY (id);


--
-- Name: recipes recipes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes
    ADD CONSTRAINT recipes_pkey PRIMARY KEY (id);


--
-- Name: reorder_recommendations reorder_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reorder_recommendations
    ADD CONSTRAINT reorder_recommendations_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_role_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_name_key UNIQUE (role_name);


--
-- Name: sales_transactions sales_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_transactions
    ADD CONSTRAINT sales_transactions_pkey PRIMARY KEY (id);


--
-- Name: sales_transactions sales_transactions_receipt_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_transactions
    ADD CONSTRAINT sales_transactions_receipt_number_key UNIQUE (receipt_number);


--
-- Name: scale_config scale_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scale_config
    ADD CONSTRAINT scale_config_pkey PRIMARY KEY (id);


--
-- Name: shrinkage_alerts shrinkage_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shrinkage_alerts
    ADD CONSTRAINT shrinkage_alerts_pkey PRIMARY KEY (id);


--
-- Name: sponsorships sponsorships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sponsorships
    ADD CONSTRAINT sponsorships_pkey PRIMARY KEY (id);


--
-- Name: staff_awol_records staff_awol_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_awol_records
    ADD CONSTRAINT staff_awol_records_pkey PRIMARY KEY (id);


--
-- Name: staff_credit staff_credit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_credit
    ADD CONSTRAINT staff_credit_pkey PRIMARY KEY (id);


--
-- Name: staff_credits staff_credits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_credits
    ADD CONSTRAINT staff_credits_pkey PRIMARY KEY (id);


--
-- Name: staff_documents staff_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_documents
    ADD CONSTRAINT staff_documents_pkey PRIMARY KEY (id);


--
-- Name: staff_loans staff_loans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_loans
    ADD CONSTRAINT staff_loans_pkey PRIMARY KEY (id);


--
-- Name: staff_profiles staff_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_profiles
    ADD CONSTRAINT staff_profiles_pkey PRIMARY KEY (id);


--
-- Name: stock_locations stock_locations_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_locations
    ADD CONSTRAINT stock_locations_name_key UNIQUE (name);


--
-- Name: stock_locations stock_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_locations
    ADD CONSTRAINT stock_locations_pkey PRIMARY KEY (id);


--
-- Name: stock_movements stock_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_pkey PRIMARY KEY (id);


--
-- Name: stock_take_entries stock_take_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_take_entries
    ADD CONSTRAINT stock_take_entries_pkey PRIMARY KEY (id);


--
-- Name: stock_take_entries stock_take_entries_session_id_item_id_location_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_take_entries
    ADD CONSTRAINT stock_take_entries_session_id_item_id_location_id_key UNIQUE (session_id, item_id, location_id);


--
-- Name: stock_take_sessions stock_take_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_take_sessions
    ADD CONSTRAINT stock_take_sessions_pkey PRIMARY KEY (id);


--
-- Name: stock_takes stock_takes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_takes
    ADD CONSTRAINT stock_takes_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: system_config system_config_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_config
    ADD CONSTRAINT system_config_key_key UNIQUE (key);


--
-- Name: system_config system_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_config
    ADD CONSTRAINT system_config_pkey PRIMARY KEY (id);


--
-- Name: tax_rules tax_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tax_rules
    ADD CONSTRAINT tax_rules_pkey PRIMARY KEY (id);


--
-- Name: timecards timecards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timecards
    ADD CONSTRAINT timecards_pkey PRIMARY KEY (id);


--
-- Name: transaction_items transaction_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_items
    ADD CONSTRAINT transaction_items_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: yield_template_cuts yield_template_cuts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yield_template_cuts
    ADD CONSTRAINT yield_template_cuts_pkey PRIMARY KEY (id);


--
-- Name: yield_templates yield_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yield_templates
    ADD CONSTRAINT yield_templates_pkey PRIMARY KEY (id);


--
-- Name: idx_acctxn_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_acctxn_account ON public.account_transactions USING btree (account_id);


--
-- Name: idx_acctxn_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_acctxn_date ON public.account_transactions USING btree (transaction_date);


--
-- Name: idx_acctxn_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_acctxn_type ON public.account_transactions USING btree (transaction_type);


--
-- Name: idx_announcements_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_announcements_active ON public.announcements USING btree (is_active);


--
-- Name: idx_audit_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_action ON public.audit_log USING btree (action);


--
-- Name: idx_audit_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_date ON public.audit_log USING btree (created_at);


--
-- Name: idx_audit_log_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_action ON public.audit_log USING btree (action);


--
-- Name: idx_audit_log_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_created_at ON public.audit_log USING btree (created_at DESC);


--
-- Name: idx_audit_severity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_severity ON public.audit_log USING btree (severity);


--
-- Name: idx_audit_staff; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_staff ON public.audit_log USING btree (staff_id);


--
-- Name: idx_awol_records_awol_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_awol_records_awol_date ON public.awol_records USING btree (awol_date);


--
-- Name: idx_awol_records_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_awol_records_created_at ON public.awol_records USING btree (created_at);


--
-- Name: idx_awol_records_resolved; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_awol_records_resolved ON public.awol_records USING btree (resolved);


--
-- Name: idx_awol_records_staff_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_awol_records_staff_id ON public.awol_records USING btree (staff_id);


--
-- Name: idx_business_accounts_account_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_accounts_account_type ON public.business_accounts USING btree (account_type);


--
-- Name: idx_business_accounts_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_accounts_active ON public.business_accounts USING btree (active);


--
-- Name: idx_business_accounts_balance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_accounts_balance ON public.business_accounts USING btree (balance);


--
-- Name: idx_business_accounts_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_accounts_is_active ON public.business_accounts USING btree (is_active);


--
-- Name: idx_business_accounts_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_business_accounts_name ON public.business_accounts USING btree (name);


--
-- Name: idx_carcass_breakdown_sessions_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_carcass_breakdown_sessions_status ON public.carcass_breakdown_sessions USING btree (status);


--
-- Name: idx_carcass_cuts_carcass_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_carcass_cuts_carcass_id ON public.carcass_cuts USING btree (carcass_id);


--
-- Name: idx_carcass_cuts_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_carcass_cuts_created_at ON public.carcass_cuts USING btree (created_at);


--
-- Name: idx_carcass_cuts_cut_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_carcass_cuts_cut_name ON public.carcass_cuts USING btree (cut_name);


--
-- Name: idx_carcass_cuts_inventory_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_carcass_cuts_inventory_item_id ON public.carcass_cuts USING btree (inventory_item_id);


--
-- Name: idx_carcass_intakes_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_carcass_intakes_created_at ON public.carcass_intakes USING btree (created_at);


--
-- Name: idx_carcass_intakes_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_carcass_intakes_date ON public.carcass_intakes USING btree (intake_date);


--
-- Name: idx_carcass_intakes_hunter_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_carcass_intakes_hunter_job_id ON public.carcass_intakes USING btree (hunter_job_id);


--
-- Name: idx_carcass_intakes_intake_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_carcass_intakes_intake_date ON public.carcass_intakes USING btree (intake_date);


--
-- Name: idx_carcass_intakes_job_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_carcass_intakes_job_type ON public.carcass_intakes USING btree (job_type);


--
-- Name: idx_carcass_intakes_species; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_carcass_intakes_species ON public.carcass_intakes USING btree (species);


--
-- Name: idx_carcass_intakes_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_carcass_intakes_status ON public.carcass_intakes USING btree (status);


--
-- Name: idx_carcass_intakes_supplier_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_carcass_intakes_supplier_id ON public.carcass_intakes USING btree (supplier_id);


--
-- Name: idx_chart_of_accounts_account_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_chart_of_accounts_account_type ON public.chart_of_accounts USING btree (account_type);


--
-- Name: idx_chart_of_accounts_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_chart_of_accounts_code ON public.chart_of_accounts USING btree (code);


--
-- Name: idx_chart_of_accounts_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_chart_of_accounts_is_active ON public.chart_of_accounts USING btree (is_active);


--
-- Name: idx_chart_of_accounts_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_chart_of_accounts_parent_id ON public.chart_of_accounts USING btree (parent_id);


--
-- Name: idx_compliance_records_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_compliance_records_created_at ON public.compliance_records USING btree (created_at);


--
-- Name: idx_compliance_records_document_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_compliance_records_document_type ON public.compliance_records USING btree (document_type);


--
-- Name: idx_compliance_records_expiry_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_compliance_records_expiry_date ON public.compliance_records USING btree (expiry_date);


--
-- Name: idx_compliance_records_is_verified; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_compliance_records_is_verified ON public.compliance_records USING btree (is_verified);


--
-- Name: idx_compliance_records_staff_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_compliance_records_staff_id ON public.compliance_records USING btree (staff_id);


--
-- Name: idx_compliance_records_verified_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_compliance_records_verified_by ON public.compliance_records USING btree (verified_by);


--
-- Name: idx_customer_announcements_channel; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_announcements_channel ON public.customer_announcements USING btree (channel);


--
-- Name: idx_customer_announcements_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_announcements_created_at ON public.customer_announcements USING btree (created_at);


--
-- Name: idx_customer_announcements_sent_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_announcements_sent_at ON public.customer_announcements USING btree (sent_at);


--
-- Name: idx_customer_announcements_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_announcements_status ON public.customer_announcements USING btree (status);


--
-- Name: idx_dryer_batches_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dryer_batches_created_at ON public.dryer_batches USING btree (created_at);


--
-- Name: idx_dryer_batches_end_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dryer_batches_end_date ON public.dryer_batches USING btree (end_date);


--
-- Name: idx_dryer_batches_start_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dryer_batches_start_date ON public.dryer_batches USING btree (start_date);


--
-- Name: idx_dryer_batches_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dryer_batches_status ON public.dryer_batches USING btree (status);


--
-- Name: idx_equipment_assets_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_equipment_assets_created_at ON public.equipment_assets USING btree (created_at);


--
-- Name: idx_equipment_assets_depreciation_method; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_equipment_assets_depreciation_method ON public.equipment_assets USING btree (depreciation_method);


--
-- Name: idx_equipment_assets_purchase_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_equipment_assets_purchase_date ON public.equipment_assets USING btree (purchase_date);


--
-- Name: idx_equipment_assets_serial_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_equipment_assets_serial_number ON public.equipment_assets USING btree (serial_number);


--
-- Name: idx_equipment_assets_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_equipment_assets_status ON public.equipment_assets USING btree (status);


--
-- Name: idx_event_sales_history_event_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_sales_history_event_date ON public.event_sales_history USING btree (event_id, date);


--
-- Name: idx_event_tags_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_tags_created_at ON public.event_tags USING btree (created_at);


--
-- Name: idx_event_tags_event_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_tags_event_date ON public.event_tags USING btree (event_date);


--
-- Name: idx_event_tags_event_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_tags_event_name ON public.event_tags USING btree (event_name);


--
-- Name: idx_hunter_jobs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hunter_jobs_created_at ON public.hunter_jobs USING btree (created_at);


--
-- Name: idx_hunter_jobs_hunter_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hunter_jobs_hunter_name ON public.hunter_jobs USING btree (hunter_name);


--
-- Name: idx_hunter_jobs_job_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hunter_jobs_job_date ON public.hunter_jobs USING btree (job_date);


--
-- Name: idx_hunter_jobs_paid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hunter_jobs_paid ON public.hunter_jobs USING btree (paid);


--
-- Name: idx_hunter_jobs_species; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hunter_jobs_species ON public.hunter_jobs USING btree (species);


--
-- Name: idx_hunter_jobs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hunter_jobs_status ON public.hunter_jobs USING btree (status);


--
-- Name: idx_hunter_service_config_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hunter_service_config_is_active ON public.hunter_service_config USING btree (is_active);


--
-- Name: idx_hunter_service_config_species; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hunter_service_config_species ON public.hunter_service_config USING btree (species);


--
-- Name: idx_inventory_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_active ON public.inventory_items USING btree (is_active);


--
-- Name: idx_inventory_barcode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_barcode ON public.inventory_items USING btree (barcode);


--
-- Name: idx_inventory_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_category ON public.inventory_items USING btree (category);


--
-- Name: idx_inventory_items_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_items_active ON public.inventory_items USING btree (is_active);


--
-- Name: idx_inventory_items_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_items_category ON public.inventory_items USING btree (category_id);


--
-- Name: idx_inventory_items_plu; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_items_plu ON public.inventory_items USING btree (plu_code);


--
-- Name: idx_inventory_plu; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_plu ON public.inventory_items USING btree (plu_code);


--
-- Name: idx_invoices_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invoices_account_id ON public.invoices USING btree (account_id);


--
-- Name: idx_invoices_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invoices_created_at ON public.invoices USING btree (created_at);


--
-- Name: idx_invoices_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invoices_created_by ON public.invoices USING btree (created_by);


--
-- Name: idx_invoices_due_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invoices_due_date ON public.invoices USING btree (due_date);


--
-- Name: idx_invoices_invoice_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invoices_invoice_date ON public.invoices USING btree (invoice_date);


--
-- Name: idx_invoices_invoice_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invoices_invoice_number ON public.invoices USING btree (invoice_number);


--
-- Name: idx_invoices_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invoices_status ON public.invoices USING btree (status);


--
-- Name: idx_leave_requests_approved_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leave_requests_approved_by ON public.leave_requests USING btree (approved_by);


--
-- Name: idx_leave_requests_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leave_requests_created_at ON public.leave_requests USING btree (created_at);


--
-- Name: idx_leave_requests_employee; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leave_requests_employee ON public.leave_requests USING btree (employee_id);


--
-- Name: idx_leave_requests_end_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leave_requests_end_date ON public.leave_requests USING btree (end_date);


--
-- Name: idx_leave_requests_leave_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leave_requests_leave_type ON public.leave_requests USING btree (leave_type);


--
-- Name: idx_leave_requests_staff_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leave_requests_staff_id ON public.leave_requests USING btree (staff_id);


--
-- Name: idx_leave_requests_start_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leave_requests_start_date ON public.leave_requests USING btree (start_date);


--
-- Name: idx_leave_requests_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leave_requests_status ON public.leave_requests USING btree (status);


--
-- Name: idx_ledger_entries_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ledger_entries_account_id ON public.ledger_entries USING btree (account_id);


--
-- Name: idx_ledger_entries_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ledger_entries_created_at ON public.ledger_entries USING btree (created_at);


--
-- Name: idx_ledger_entries_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ledger_entries_created_by ON public.ledger_entries USING btree (created_by);


--
-- Name: idx_ledger_entries_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ledger_entries_date ON public.ledger_entries USING btree (entry_date);


--
-- Name: idx_ledger_entries_entry_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ledger_entries_entry_date ON public.ledger_entries USING btree (entry_date);


--
-- Name: idx_ledger_entries_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ledger_entries_source ON public.ledger_entries USING btree (source);


--
-- Name: idx_loyalty_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_loyalty_phone ON public.loyalty_customers USING btree (phone);


--
-- Name: idx_loyalty_tier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_loyalty_tier ON public.loyalty_customers USING btree (loyalty_tier);


--
-- Name: idx_message_logs_sent_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_message_logs_sent_at ON public.message_logs USING btree (sent_at DESC);


--
-- Name: idx_message_logs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_message_logs_status ON public.message_logs USING btree (status);


--
-- Name: idx_payroll_entries_approved_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_entries_approved_by ON public.payroll_entries USING btree (approved_by);


--
-- Name: idx_payroll_entries_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_entries_created_at ON public.payroll_entries USING btree (created_at);


--
-- Name: idx_payroll_entries_pay_frequency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_entries_pay_frequency ON public.payroll_entries USING btree (pay_frequency);


--
-- Name: idx_payroll_entries_pay_period_end; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_entries_pay_period_end ON public.payroll_entries USING btree (pay_period_end);


--
-- Name: idx_payroll_entries_pay_period_start; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_entries_pay_period_start ON public.payroll_entries USING btree (pay_period_start);


--
-- Name: idx_payroll_entries_staff_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_entries_staff_id ON public.payroll_entries USING btree (staff_id);


--
-- Name: idx_payroll_entries_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payroll_entries_status ON public.payroll_entries USING btree (status);


--
-- Name: idx_po_lines_po; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_po_lines_po ON public.purchase_order_lines USING btree (purchase_order_id);


--
-- Name: idx_po_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_po_status ON public.purchase_orders USING btree (status);


--
-- Name: idx_po_supplier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_po_supplier ON public.purchase_orders USING btree (supplier_id);


--
-- Name: idx_product_suppliers_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_suppliers_item ON public.product_suppliers USING btree (inventory_item_id);


--
-- Name: idx_product_suppliers_supplier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_suppliers_supplier ON public.product_suppliers USING btree (supplier_id);


--
-- Name: idx_production_batches_batch_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_production_batches_batch_date ON public.production_batches USING btree (batch_date);


--
-- Name: idx_production_batches_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_production_batches_created_at ON public.production_batches USING btree (created_at);


--
-- Name: idx_production_batches_recipe_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_production_batches_recipe_id ON public.production_batches USING btree (recipe_id);


--
-- Name: idx_production_batches_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_production_batches_status ON public.production_batches USING btree (status);


--
-- Name: idx_profiles_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_active ON public.profiles USING btree (is_active);


--
-- Name: idx_profiles_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profiles_role ON public.profiles USING btree (role);


--
-- Name: idx_purchase_sale_agreement_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_sale_agreement_account_id ON public.purchase_sale_agreement USING btree (account_id);


--
-- Name: idx_purchase_sale_agreements_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_sale_agreements_account_id ON public.purchase_sale_agreements USING btree (account_id);


--
-- Name: idx_purchase_sale_agreements_agreement_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_sale_agreements_agreement_date ON public.purchase_sale_agreements USING btree (agreement_date);


--
-- Name: idx_purchase_sale_agreements_agreement_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_sale_agreements_agreement_type ON public.purchase_sale_agreements USING btree (agreement_type);


--
-- Name: idx_purchase_sale_agreements_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_sale_agreements_created_at ON public.purchase_sale_agreements USING btree (created_at);


--
-- Name: idx_purchase_sale_agreements_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_sale_agreements_status ON public.purchase_sale_agreements USING btree (status);


--
-- Name: idx_recipes_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recipes_category ON public.recipes USING btree (category);


--
-- Name: idx_recipes_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recipes_created_at ON public.recipes USING btree (created_at);


--
-- Name: idx_recipes_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recipes_is_active ON public.recipes USING btree (is_active);


--
-- Name: idx_recipes_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recipes_name ON public.recipes USING btree (name);


--
-- Name: idx_reorder_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reorder_item ON public.reorder_recommendations USING btree (item_id);


--
-- Name: idx_reorder_recommendations_auto_resolved; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reorder_recommendations_auto_resolved ON public.reorder_recommendations USING btree (auto_resolved);


--
-- Name: idx_reorder_recommendations_days_of_stock; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reorder_recommendations_days_of_stock ON public.reorder_recommendations USING btree (days_of_stock);


--
-- Name: idx_reorder_recommendations_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reorder_recommendations_item_id ON public.reorder_recommendations USING btree (item_id);


--
-- Name: idx_reorder_recommendations_resolved; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reorder_recommendations_resolved ON public.reorder_recommendations USING btree (auto_resolved);


--
-- Name: idx_reorder_urgency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reorder_urgency ON public.reorder_recommendations USING btree (urgency);


--
-- Name: idx_sales_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_created_at ON public.sales_transactions USING btree (created_at);


--
-- Name: idx_sales_total_amount; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_total_amount ON public.sales_transactions USING btree (total_amount);


--
-- Name: idx_scale_config_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scale_config_updated_at ON public.scale_config USING btree (updated_at DESC);


--
-- Name: idx_shrinkage_alerts_acknowledged; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shrinkage_alerts_acknowledged ON public.shrinkage_alerts USING btree (acknowledged);


--
-- Name: idx_shrinkage_alerts_acknowledged_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shrinkage_alerts_acknowledged_by ON public.shrinkage_alerts USING btree (acknowledged_by);


--
-- Name: idx_shrinkage_alerts_alert_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shrinkage_alerts_alert_date ON public.shrinkage_alerts USING btree (alert_date);


--
-- Name: idx_shrinkage_alerts_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shrinkage_alerts_created_at ON public.shrinkage_alerts USING btree (created_at);


--
-- Name: idx_shrinkage_alerts_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shrinkage_alerts_item_id ON public.shrinkage_alerts USING btree (item_id);


--
-- Name: idx_shrinkage_alerts_resolved; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shrinkage_alerts_resolved ON public.shrinkage_alerts USING btree (resolved);


--
-- Name: idx_shrinkage_alerts_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shrinkage_alerts_status ON public.shrinkage_alerts USING btree (status);


--
-- Name: idx_staff_awol_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staff_awol_date ON public.staff_awol_records USING btree (awol_date);


--
-- Name: idx_staff_awol_resolution; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staff_awol_resolution ON public.staff_awol_records USING btree (resolution);


--
-- Name: idx_staff_awol_staff_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staff_awol_staff_id ON public.staff_awol_records USING btree (staff_id);


--
-- Name: idx_staff_credits_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staff_credits_created_at ON public.staff_credits USING btree (created_at);


--
-- Name: idx_staff_credits_credit_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staff_credits_credit_date ON public.staff_credits USING btree (credit_date);


--
-- Name: idx_staff_credits_staff_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staff_credits_staff_id ON public.staff_credits USING btree (staff_id);


--
-- Name: idx_staff_profiles_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staff_profiles_is_active ON public.staff_profiles USING btree (is_active);


--
-- Name: idx_staff_profiles_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staff_profiles_role ON public.staff_profiles USING btree (role);


--
-- Name: idx_stock_movements_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_movements_date ON public.stock_movements USING btree (created_at);


--
-- Name: idx_stock_movements_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_movements_item ON public.stock_movements USING btree (item_id);


--
-- Name: idx_stock_movements_item_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_movements_item_type ON public.stock_movements USING btree (item_id, movement_type);


--
-- Name: idx_stock_movements_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_movements_type ON public.stock_movements USING btree (movement_type);


--
-- Name: idx_stock_take_entries_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_take_entries_item ON public.stock_take_entries USING btree (item_id);


--
-- Name: idx_stock_take_entries_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_take_entries_session ON public.stock_take_entries USING btree (session_id);


--
-- Name: idx_stock_take_sessions_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_take_sessions_status ON public.stock_take_sessions USING btree (status);


--
-- Name: idx_stock_takes_approved_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_takes_approved_by ON public.stock_takes USING btree (approved_by);


--
-- Name: idx_stock_takes_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_takes_created_at ON public.stock_takes USING btree (created_at);


--
-- Name: idx_stock_takes_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_takes_status ON public.stock_takes USING btree (status);


--
-- Name: idx_stock_takes_take_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_takes_take_date ON public.stock_takes USING btree (take_date);


--
-- Name: idx_suppliers_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_suppliers_is_active ON public.suppliers USING btree (is_active);


--
-- Name: idx_suppliers_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_suppliers_name ON public.suppliers USING btree (name);


--
-- Name: idx_system_config_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_config_is_active ON public.system_config USING btree (is_active);


--
-- Name: idx_system_config_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_system_config_key ON public.system_config USING btree (key);


--
-- Name: idx_tax_rules_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tax_rules_name ON public.tax_rules USING btree (name);


--
-- Name: idx_timecards_clock_in; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_timecards_clock_in ON public.timecards USING btree (clock_in);


--
-- Name: idx_timecards_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_timecards_created_at ON public.timecards USING btree (created_at);


--
-- Name: idx_timecards_employee; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_timecards_employee ON public.timecards USING btree (employee_id);


--
-- Name: idx_timecards_shift_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_timecards_shift_date ON public.timecards USING btree (shift_date);


--
-- Name: idx_timecards_staff_clock; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_timecards_staff_clock ON public.timecards USING btree (staff_id, clock_in);


--
-- Name: idx_timecards_staff_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_timecards_staff_id ON public.timecards USING btree (staff_id);


--
-- Name: idx_transaction_items_inventory_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_items_inventory_item_id ON public.transaction_items USING btree (inventory_item_id);


--
-- Name: idx_transaction_items_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_items_product_id ON public.transaction_items USING btree (inventory_item_id);


--
-- Name: idx_transaction_items_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_items_transaction_id ON public.transaction_items USING btree (transaction_id);


--
-- Name: idx_transactions_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_created_at ON public.transactions USING btree (created_at);


--
-- Name: idx_transactions_total_amount; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_total_amount ON public.transactions USING btree (total_amount);


--
-- Name: idx_yield_templates_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_yield_templates_created_at ON public.yield_templates USING btree (created_at);


--
-- Name: idx_yield_templates_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_yield_templates_name ON public.yield_templates USING btree (name);


--
-- Name: idx_yield_templates_species; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_yield_templates_species ON public.yield_templates USING btree (species);


--
-- Name: leave_balances_employee_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX leave_balances_employee_unique ON public.leave_balances USING btree (employee_id);


--
-- Name: awol_records audit_trigger_awol_records; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_awol_records AFTER INSERT OR DELETE OR UPDATE ON public.awol_records FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: carcass_intakes audit_trigger_carcass_intakes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_carcass_intakes AFTER INSERT OR DELETE OR UPDATE ON public.carcass_intakes FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: chart_of_accounts audit_trigger_chart_of_accounts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_chart_of_accounts AFTER INSERT OR DELETE OR UPDATE ON public.chart_of_accounts FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: compliance_records audit_trigger_compliance_records; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_compliance_records AFTER INSERT OR DELETE OR UPDATE ON public.compliance_records FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: equipment_assets audit_trigger_equipment_assets; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_equipment_assets AFTER INSERT OR DELETE OR UPDATE ON public.equipment_assets FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: hunter_jobs audit_trigger_hunter_jobs; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_hunter_jobs AFTER INSERT OR DELETE OR UPDATE ON public.hunter_jobs FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: invoices audit_trigger_invoices; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_invoices AFTER INSERT OR DELETE OR UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: leave_requests audit_trigger_leave_requests; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_leave_requests AFTER INSERT OR DELETE OR UPDATE ON public.leave_requests FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: ledger_entries audit_trigger_ledger_entries; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_ledger_entries AFTER INSERT OR DELETE OR UPDATE ON public.ledger_entries FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: payroll_entries audit_trigger_payroll_entries; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_payroll_entries AFTER INSERT OR DELETE OR UPDATE ON public.payroll_entries FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: production_batches audit_trigger_production_batches; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_production_batches AFTER INSERT OR DELETE OR UPDATE ON public.production_batches FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: purchase_sale_agreements audit_trigger_purchase_sale_agreements; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_purchase_sale_agreements AFTER INSERT OR DELETE OR UPDATE ON public.purchase_sale_agreements FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: shrinkage_alerts audit_trigger_shrinkage_alerts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_shrinkage_alerts AFTER INSERT OR DELETE OR UPDATE ON public.shrinkage_alerts FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: staff_credits audit_trigger_staff_credits; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_staff_credits AFTER INSERT OR DELETE OR UPDATE ON public.staff_credits FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: staff_profiles audit_trigger_staff_profiles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_staff_profiles AFTER INSERT OR DELETE OR UPDATE ON public.staff_profiles FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: stock_takes audit_trigger_stock_takes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stock_takes AFTER INSERT OR DELETE OR UPDATE ON public.stock_takes FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: timecards audit_trigger_timecards; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_timecards AFTER INSERT OR DELETE OR UPDATE ON public.timecards FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_function();


--
-- Name: account_awol_records trigger_awol_detection; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_awol_detection AFTER INSERT ON public.account_awol_records FOR EACH ROW EXECUTE FUNCTION public.detect_awol_pattern();


--
-- Name: transaction_items trigger_deduct_stock_on_sale; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_deduct_stock_on_sale AFTER INSERT ON public.transaction_items FOR EACH ROW EXECUTE FUNCTION public.deduct_stock_on_sale();


--
-- Name: transactions trigger_post_transaction_to_ledger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_post_transaction_to_ledger AFTER INSERT ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.post_pos_sale_to_ledger();


--
-- Name: stock_movements trigger_reorder_check; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_reorder_check AFTER INSERT OR UPDATE ON public.stock_movements FOR EACH ROW WHEN ((new.movement_type = ANY (ARRAY['out'::text, 'adjustment'::text]))) EXECUTE FUNCTION public.check_reorder_threshold();


--
-- Name: production_batches trigger_shrinkage_check; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_shrinkage_check AFTER UPDATE ON public.production_batches FOR EACH ROW EXECUTE FUNCTION public.check_shrinkage_threshold();


--
-- Name: announcements update_announcements_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON public.announcements FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: awol_records update_awol_records_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_awol_records_updated_at BEFORE UPDATE ON public.awol_records FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: business_accounts update_business_accounts_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_business_accounts_updated_at BEFORE UPDATE ON public.business_accounts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: carcass_cuts update_carcass_cuts_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_carcass_cuts_updated_at BEFORE UPDATE ON public.carcass_cuts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: carcass_intakes update_carcass_intakes_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_carcass_intakes_updated_at BEFORE UPDATE ON public.carcass_intakes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: chart_of_accounts update_chart_of_accounts_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_chart_of_accounts_updated_at BEFORE UPDATE ON public.chart_of_accounts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: compliance_records update_compliance_records_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_compliance_records_updated_at BEFORE UPDATE ON public.compliance_records FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: customer_announcements update_customer_announcements_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_customer_announcements_updated_at BEFORE UPDATE ON public.customer_announcements FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: dryer_batches update_dryer_batches_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_dryer_batches_updated_at BEFORE UPDATE ON public.dryer_batches FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: equipment_assets update_equipment_assets_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_equipment_assets_updated_at BEFORE UPDATE ON public.equipment_assets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: event_tags update_event_tags_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_event_tags_updated_at BEFORE UPDATE ON public.event_tags FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: hunter_jobs update_hunter_jobs_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_hunter_jobs_updated_at BEFORE UPDATE ON public.hunter_jobs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: hunter_service_config update_hunter_service_config_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_hunter_service_config_updated_at BEFORE UPDATE ON public.hunter_service_config FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: inventory_items update_inventory_items_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_inventory_items_updated_at BEFORE UPDATE ON public.inventory_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: invoices update_invoices_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: leave_requests update_leave_requests_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_leave_requests_updated_at BEFORE UPDATE ON public.leave_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: ledger_entries update_ledger_entries_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_ledger_entries_updated_at BEFORE UPDATE ON public.ledger_entries FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: loyalty_customers update_loyalty_customers_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_loyalty_customers_updated_at BEFORE UPDATE ON public.loyalty_customers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: payroll_entries update_payroll_entries_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_payroll_entries_updated_at BEFORE UPDATE ON public.payroll_entries FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: production_batches update_production_batches_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_production_batches_updated_at BEFORE UPDATE ON public.production_batches FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: purchase_sale_agreements update_purchase_sale_agreements_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_purchase_sale_agreements_updated_at BEFORE UPDATE ON public.purchase_sale_agreements FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: recipes update_recipes_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_recipes_updated_at BEFORE UPDATE ON public.recipes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: shrinkage_alerts update_shrinkage_alerts_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_shrinkage_alerts_updated_at BEFORE UPDATE ON public.shrinkage_alerts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: staff_credits update_staff_credits_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_staff_credits_updated_at BEFORE UPDATE ON public.staff_credits FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: staff_profiles update_staff_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_staff_profiles_updated_at BEFORE UPDATE ON public.staff_profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: stock_takes update_stock_takes_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_stock_takes_updated_at BEFORE UPDATE ON public.stock_takes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: suppliers update_suppliers_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON public.suppliers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: timecards update_timecards_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_timecards_updated_at BEFORE UPDATE ON public.timecards FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: yield_templates update_yield_templates_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_yield_templates_updated_at BEFORE UPDATE ON public.yield_templates FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: timecards validate_timecard_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER validate_timecard_trigger BEFORE INSERT OR UPDATE ON public.timecards FOR EACH ROW EXECUTE FUNCTION public.validate_timecard();


--
-- Name: account_awol_records account_awol_records_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_awol_records
    ADD CONSTRAINT account_awol_records_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.business_accounts(id) ON DELETE CASCADE;


--
-- Name: account_awol_records account_awol_records_recorded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_awol_records
    ADD CONSTRAINT account_awol_records_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.profiles(id);


--
-- Name: account_transactions account_transactions_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions
    ADD CONSTRAINT account_transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.business_accounts(id) ON DELETE CASCADE;


--
-- Name: account_transactions account_transactions_recorded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions
    ADD CONSTRAINT account_transactions_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.profiles(id);


--
-- Name: announcements announcements_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);


--
-- Name: audit_log audit_log_authorised_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_authorised_by_fkey FOREIGN KEY (authorised_by) REFERENCES public.profiles(id);


--
-- Name: audit_log audit_log_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.profiles(id);


--
-- Name: awol_records awol_records_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awol_records
    ADD CONSTRAINT awol_records_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff_profiles(id) ON DELETE RESTRICT;


--
-- Name: carcass_breakdown_sessions carcass_breakdown_sessions_intake_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carcass_breakdown_sessions
    ADD CONSTRAINT carcass_breakdown_sessions_intake_id_fkey FOREIGN KEY (intake_id) REFERENCES public.carcass_intakes(id) ON DELETE CASCADE;


--
-- Name: carcass_breakdown_sessions carcass_breakdown_sessions_processed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carcass_breakdown_sessions
    ADD CONSTRAINT carcass_breakdown_sessions_processed_by_fkey FOREIGN KEY (processed_by) REFERENCES public.profiles(id);


--
-- Name: carcass_breakdown_sessions carcass_breakdown_sessions_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carcass_breakdown_sessions
    ADD CONSTRAINT carcass_breakdown_sessions_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.yield_templates(id);


--
-- Name: carcass_cuts carcass_cuts_carcass_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carcass_cuts
    ADD CONSTRAINT carcass_cuts_carcass_id_fkey FOREIGN KEY (carcass_id) REFERENCES public.carcass_intakes(id) ON DELETE CASCADE;


--
-- Name: carcass_cuts carcass_cuts_intake_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carcass_cuts
    ADD CONSTRAINT carcass_cuts_intake_id_fkey FOREIGN KEY (intake_id) REFERENCES public.carcass_intakes(id);


--
-- Name: carcass_intakes carcass_intakes_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carcass_intakes
    ADD CONSTRAINT carcass_intakes_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id) ON DELETE SET NULL;


--
-- Name: carcass_intakes carcass_intakes_yield_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carcass_intakes
    ADD CONSTRAINT carcass_intakes_yield_template_id_fkey FOREIGN KEY (yield_template_id) REFERENCES public.yield_templates(id);


--
-- Name: chart_of_accounts chart_of_accounts_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chart_of_accounts
    ADD CONSTRAINT chart_of_accounts_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.chart_of_accounts(id) ON DELETE SET NULL;


--
-- Name: compliance_records compliance_records_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compliance_records
    ADD CONSTRAINT compliance_records_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff_profiles(id) ON DELETE RESTRICT;


--
-- Name: compliance_records compliance_records_verified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.compliance_records
    ADD CONSTRAINT compliance_records_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES public.staff_profiles(id) ON DELETE SET NULL;


--
-- Name: donations donations_recorded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.profiles(id);


--
-- Name: dryer_batch_ingredients dryer_batch_ingredients_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dryer_batch_ingredients
    ADD CONSTRAINT dryer_batch_ingredients_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.dryer_batches(id) ON DELETE CASCADE;


--
-- Name: dryer_batch_ingredients dryer_batch_ingredients_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dryer_batch_ingredients
    ADD CONSTRAINT dryer_batch_ingredients_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id);


--
-- Name: dryer_batches dryer_batches_input_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dryer_batches
    ADD CONSTRAINT dryer_batches_input_product_id_fkey FOREIGN KEY (input_product_id) REFERENCES public.inventory_items(id);


--
-- Name: dryer_batches dryer_batches_output_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dryer_batches
    ADD CONSTRAINT dryer_batches_output_product_id_fkey FOREIGN KEY (output_product_id) REFERENCES public.inventory_items(id);


--
-- Name: dryer_batches dryer_batches_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dryer_batches
    ADD CONSTRAINT dryer_batches_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id);


--
-- Name: equipment_register equipment_register_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipment_register
    ADD CONSTRAINT equipment_register_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.profiles(id);


--
-- Name: event_sales_history event_sales_history_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_sales_history
    ADD CONSTRAINT event_sales_history_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event_tags(id) ON DELETE CASCADE;


--
-- Name: carcass_intakes fk_carcass_intakes_hunter_job; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.carcass_intakes
    ADD CONSTRAINT fk_carcass_intakes_hunter_job FOREIGN KEY (hunter_job_id) REFERENCES public.hunter_jobs(id) ON DELETE SET NULL;


--
-- Name: hunter_job_processes hunter_job_processes_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hunter_job_processes
    ADD CONSTRAINT hunter_job_processes_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.hunter_jobs(id) ON DELETE CASCADE;


--
-- Name: hunter_job_processes hunter_job_processes_processed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hunter_job_processes
    ADD CONSTRAINT hunter_job_processes_processed_by_fkey FOREIGN KEY (processed_by) REFERENCES public.profiles(id);


--
-- Name: hunter_process_materials hunter_process_materials_process_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hunter_process_materials
    ADD CONSTRAINT hunter_process_materials_process_id_fkey FOREIGN KEY (process_id) REFERENCES public.hunter_job_processes(id) ON DELETE CASCADE;


--
-- Name: inventory_items inventory_items_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: inventory_items inventory_items_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id);


--
-- Name: invoice_line_items invoice_line_items_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_line_items
    ADD CONSTRAINT invoice_line_items_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoices(id) ON DELETE CASCADE;


--
-- Name: invoices invoices_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.business_accounts(id) ON DELETE RESTRICT;


--
-- Name: invoices invoices_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff_profiles(id) ON DELETE SET NULL;


--
-- Name: invoices invoices_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id);


--
-- Name: leave_balances leave_balances_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: leave_requests leave_requests_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT leave_requests_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.staff_profiles(id) ON DELETE SET NULL;


--
-- Name: leave_requests leave_requests_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT leave_requests_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: leave_requests leave_requests_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_requests
    ADD CONSTRAINT leave_requests_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff_profiles(id) ON DELETE RESTRICT;


--
-- Name: ledger_entries ledger_entries_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT ledger_entries_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.business_accounts(id) ON DELETE RESTRICT;


--
-- Name: ledger_entries ledger_entries_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT ledger_entries_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff_profiles(id) ON DELETE SET NULL;


--
-- Name: ledger_entries ledger_entries_recorded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ledger_entries
    ADD CONSTRAINT ledger_entries_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.profiles(id);


--
-- Name: modifier_items modifier_items_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifier_items
    ADD CONSTRAINT modifier_items_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id);


--
-- Name: modifier_items modifier_items_linked_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifier_items
    ADD CONSTRAINT modifier_items_linked_item_id_fkey FOREIGN KEY (linked_item_id) REFERENCES public.inventory_items(id);


--
-- Name: modifier_items modifier_items_modifier_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modifier_items
    ADD CONSTRAINT modifier_items_modifier_group_id_fkey FOREIGN KEY (modifier_group_id) REFERENCES public.modifier_groups(id) ON DELETE CASCADE;


--
-- Name: payroll_entries payroll_entries_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_entries
    ADD CONSTRAINT payroll_entries_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.staff_profiles(id) ON DELETE SET NULL;


--
-- Name: payroll_entries payroll_entries_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_entries
    ADD CONSTRAINT payroll_entries_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff_profiles(id) ON DELETE RESTRICT;


--
-- Name: payroll_periods payroll_periods_processed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payroll_periods
    ADD CONSTRAINT payroll_periods_processed_by_fkey FOREIGN KEY (processed_by) REFERENCES public.profiles(id);


--
-- Name: product_suppliers product_suppliers_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_suppliers
    ADD CONSTRAINT product_suppliers_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE CASCADE;


--
-- Name: product_suppliers product_suppliers_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_suppliers
    ADD CONSTRAINT product_suppliers_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id) ON DELETE CASCADE;


--
-- Name: production_batch_ingredients production_batch_ingredients_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_batch_ingredients
    ADD CONSTRAINT production_batch_ingredients_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.production_batches(id) ON DELETE CASCADE;


--
-- Name: production_batch_ingredients production_batch_ingredients_ingredient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_batch_ingredients
    ADD CONSTRAINT production_batch_ingredients_ingredient_id_fkey FOREIGN KEY (ingredient_id) REFERENCES public.recipe_ingredients(id);


--
-- Name: production_batch_outputs production_batch_outputs_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_batch_outputs
    ADD CONSTRAINT production_batch_outputs_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.production_batches(id) ON DELETE CASCADE;


--
-- Name: production_batch_outputs production_batch_outputs_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_batch_outputs
    ADD CONSTRAINT production_batch_outputs_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id);


--
-- Name: production_batches production_batches_output_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_batches
    ADD CONSTRAINT production_batches_output_product_id_fkey FOREIGN KEY (output_product_id) REFERENCES public.inventory_items(id);


--
-- Name: production_batches production_batches_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_batches
    ADD CONSTRAINT production_batches_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id) ON DELETE SET NULL;


--
-- Name: purchase_order_lines purchase_order_lines_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_lines
    ADD CONSTRAINT purchase_order_lines_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id) ON DELETE RESTRICT;


--
-- Name: purchase_order_lines purchase_order_lines_purchase_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order_lines
    ADD CONSTRAINT purchase_order_lines_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES public.purchase_orders(id) ON DELETE CASCADE;


--
-- Name: purchase_orders purchase_orders_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);


--
-- Name: purchase_orders purchase_orders_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id) ON DELETE RESTRICT;


--
-- Name: purchase_sale_agreement purchase_sale_agreement_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_sale_agreement
    ADD CONSTRAINT purchase_sale_agreement_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.business_accounts(id);


--
-- Name: purchase_sale_agreement purchase_sale_agreement_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_sale_agreement
    ADD CONSTRAINT purchase_sale_agreement_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);


--
-- Name: purchase_sale_agreements purchase_sale_agreements_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_sale_agreements
    ADD CONSTRAINT purchase_sale_agreements_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.business_accounts(id) ON DELETE RESTRICT;


--
-- Name: purchase_sale_payments purchase_sale_payments_agreement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_sale_payments
    ADD CONSTRAINT purchase_sale_payments_agreement_id_fkey FOREIGN KEY (agreement_id) REFERENCES public.purchase_sale_agreement(id) ON DELETE CASCADE;


--
-- Name: purchase_sale_payments purchase_sale_payments_recorded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_sale_payments
    ADD CONSTRAINT purchase_sale_payments_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.profiles(id);


--
-- Name: recipe_ingredients recipe_ingredients_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_ingredients
    ADD CONSTRAINT recipe_ingredients_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id);


--
-- Name: recipe_ingredients recipe_ingredients_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_ingredients
    ADD CONSTRAINT recipe_ingredients_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id) ON DELETE CASCADE;


--
-- Name: recipes recipes_output_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes
    ADD CONSTRAINT recipes_output_product_id_fkey FOREIGN KEY (output_product_id) REFERENCES public.inventory_items(id);


--
-- Name: reorder_recommendations reorder_recommendations_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reorder_recommendations
    ADD CONSTRAINT reorder_recommendations_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.inventory_items(id);


--
-- Name: shrinkage_alerts shrinkage_alerts_acknowledged_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shrinkage_alerts
    ADD CONSTRAINT shrinkage_alerts_acknowledged_by_fkey FOREIGN KEY (acknowledged_by) REFERENCES public.staff_profiles(id) ON DELETE SET NULL;


--
-- Name: shrinkage_alerts shrinkage_alerts_batch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shrinkage_alerts
    ADD CONSTRAINT shrinkage_alerts_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES public.production_batches(id) ON DELETE SET NULL;


--
-- Name: shrinkage_alerts shrinkage_alerts_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shrinkage_alerts
    ADD CONSTRAINT shrinkage_alerts_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.inventory_items(id) ON DELETE SET NULL;


--
-- Name: shrinkage_alerts shrinkage_alerts_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shrinkage_alerts
    ADD CONSTRAINT shrinkage_alerts_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.profiles(id);


--
-- Name: sponsorships sponsorships_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sponsorships
    ADD CONSTRAINT sponsorships_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);


--
-- Name: staff_awol_records staff_awol_records_recorded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_awol_records
    ADD CONSTRAINT staff_awol_records_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.profiles(id);


--
-- Name: staff_awol_records staff_awol_records_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_awol_records
    ADD CONSTRAINT staff_awol_records_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: staff_credit staff_credit_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_credit
    ADD CONSTRAINT staff_credit_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.profiles(id);


--
-- Name: staff_credit staff_credit_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_credit
    ADD CONSTRAINT staff_credit_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: staff_credits staff_credits_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_credits
    ADD CONSTRAINT staff_credits_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff_profiles(id) ON DELETE RESTRICT;


--
-- Name: staff_documents staff_documents_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_documents
    ADD CONSTRAINT staff_documents_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: staff_documents staff_documents_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_documents
    ADD CONSTRAINT staff_documents_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.profiles(id);


--
-- Name: staff_loans staff_loans_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_loans
    ADD CONSTRAINT staff_loans_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.profiles(id);


--
-- Name: staff_loans staff_loans_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_loans
    ADD CONSTRAINT staff_loans_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: stock_movements stock_movements_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.inventory_items(id);


--
-- Name: stock_movements stock_movements_location_from_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_location_from_fkey FOREIGN KEY (location_from) REFERENCES public.stock_locations(id);


--
-- Name: stock_movements stock_movements_location_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_location_to_fkey FOREIGN KEY (location_to) REFERENCES public.stock_locations(id);


--
-- Name: stock_movements stock_movements_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.profiles(id);


--
-- Name: stock_take_entries stock_take_entries_counted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_take_entries
    ADD CONSTRAINT stock_take_entries_counted_by_fkey FOREIGN KEY (counted_by) REFERENCES public.profiles(id);


--
-- Name: stock_take_entries stock_take_entries_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_take_entries
    ADD CONSTRAINT stock_take_entries_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.inventory_items(id) ON DELETE CASCADE;


--
-- Name: stock_take_entries stock_take_entries_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_take_entries
    ADD CONSTRAINT stock_take_entries_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.stock_locations(id);


--
-- Name: stock_take_entries stock_take_entries_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_take_entries
    ADD CONSTRAINT stock_take_entries_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.stock_take_sessions(id) ON DELETE CASCADE;


--
-- Name: stock_take_sessions stock_take_sessions_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_take_sessions
    ADD CONSTRAINT stock_take_sessions_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.profiles(id);


--
-- Name: stock_take_sessions stock_take_sessions_started_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_take_sessions
    ADD CONSTRAINT stock_take_sessions_started_by_fkey FOREIGN KEY (started_by) REFERENCES public.profiles(id);


--
-- Name: stock_takes stock_takes_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_takes
    ADD CONSTRAINT stock_takes_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.staff_profiles(id) ON DELETE SET NULL;


--
-- Name: timecards timecards_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timecards
    ADD CONSTRAINT timecards_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: timecards timecards_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timecards
    ADD CONSTRAINT timecards_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff_profiles(id) ON DELETE RESTRICT;


--
-- Name: transaction_items transaction_items_inventory_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_items
    ADD CONSTRAINT transaction_items_inventory_item_id_fkey FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id);


--
-- Name: transaction_items transaction_items_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_items
    ADD CONSTRAINT transaction_items_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id) ON DELETE CASCADE;


--
-- Name: transactions transactions_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.business_accounts(id);


--
-- Name: transactions transactions_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.profiles(id);


--
-- Name: yield_template_cuts yield_template_cuts_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.yield_template_cuts
    ADD CONSTRAINT yield_template_cuts_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.yield_templates(id) ON DELETE CASCADE;


--
-- Name: awol_records Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.awol_records TO anon USING (true) WITH CHECK (true);


--
-- Name: business_accounts Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.business_accounts TO anon USING (true) WITH CHECK (true);


--
-- Name: business_settings Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.business_settings TO anon USING (true) WITH CHECK (true);


--
-- Name: carcass_cuts Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.carcass_cuts TO anon USING (true) WITH CHECK (true);


--
-- Name: carcass_intakes Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.carcass_intakes TO anon USING (true) WITH CHECK (true);


--
-- Name: categories Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.categories TO anon USING (true) WITH CHECK (true);


--
-- Name: chart_of_accounts Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.chart_of_accounts TO anon USING (true) WITH CHECK (true);


--
-- Name: compliance_records Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.compliance_records TO anon USING (true) WITH CHECK (true);


--
-- Name: customer_announcements Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.customer_announcements TO anon USING (true) WITH CHECK (true);


--
-- Name: dryer_batches Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.dryer_batches TO anon USING (true) WITH CHECK (true);


--
-- Name: equipment_assets Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.equipment_assets TO anon USING (true) WITH CHECK (true);


--
-- Name: event_tags Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.event_tags TO anon USING (true) WITH CHECK (true);


--
-- Name: hunter_jobs Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.hunter_jobs TO anon USING (true) WITH CHECK (true);


--
-- Name: hunter_service_config Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.hunter_service_config TO anon USING (true) WITH CHECK (true);


--
-- Name: inventory_items Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.inventory_items TO anon USING (true) WITH CHECK (true);


--
-- Name: invoices Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.invoices TO anon USING (true) WITH CHECK (true);


--
-- Name: leave_balances Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.leave_balances TO anon USING (true) WITH CHECK (true);


--
-- Name: leave_requests Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.leave_requests TO anon USING (true) WITH CHECK (true);


--
-- Name: ledger_entries Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.ledger_entries TO anon USING (true) WITH CHECK (true);


--
-- Name: loyalty_customers Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.loyalty_customers TO anon USING (true) WITH CHECK (true);


--
-- Name: modifier_groups Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.modifier_groups TO anon USING (true) WITH CHECK (true);


--
-- Name: modifier_items Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.modifier_items TO anon USING (true) WITH CHECK (true);


--
-- Name: payroll_entries Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.payroll_entries TO anon USING (true) WITH CHECK (true);


--
-- Name: production_batches Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.production_batches TO anon USING (true) WITH CHECK (true);


--
-- Name: profiles Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.profiles TO anon USING (true) WITH CHECK (true);


--
-- Name: purchase_sale_agreements Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.purchase_sale_agreements TO anon USING (true) WITH CHECK (true);


--
-- Name: recipes Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.recipes TO anon USING (true) WITH CHECK (true);


--
-- Name: reorder_recommendations Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.reorder_recommendations TO anon USING (true) WITH CHECK (true);


--
-- Name: shrinkage_alerts Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.shrinkage_alerts TO anon USING (true) WITH CHECK (true);


--
-- Name: staff_documents Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.staff_documents TO anon USING (true) WITH CHECK (true);


--
-- Name: staff_profiles Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.staff_profiles TO anon USING (true) WITH CHECK (true);


--
-- Name: stock_locations Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.stock_locations TO anon USING (true) WITH CHECK (true);


--
-- Name: stock_movements Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.stock_movements TO anon USING (true) WITH CHECK (true);


--
-- Name: stock_takes Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.stock_takes TO anon USING (true) WITH CHECK (true);


--
-- Name: suppliers Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.suppliers TO anon USING (true) WITH CHECK (true);


--
-- Name: timecards Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.timecards TO anon USING (true) WITH CHECK (true);


--
-- Name: yield_templates Allow all for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow all for anon" ON public.yield_templates TO anon USING (true) WITH CHECK (true);


--
-- Name: audit_log Allow insert for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow insert for anon" ON public.audit_log FOR INSERT TO anon WITH CHECK (true);


--
-- Name: audit_log Allow select for anon; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow select for anon" ON public.audit_log FOR SELECT TO anon USING (true);


--
-- Name: account_awol_records; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.account_awol_records ENABLE ROW LEVEL SECURITY;

--
-- Name: account_transactions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.account_transactions ENABLE ROW LEVEL SECURITY;

--
-- Name: announcements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_log; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

--
-- Name: production_batch_outputs auth users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "auth users" ON public.production_batch_outputs TO authenticated USING (true) WITH CHECK (true);


--
-- Name: awol_records; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.awol_records ENABLE ROW LEVEL SECURITY;

--
-- Name: awol_records awol_records_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY awol_records_auth_policy ON public.awol_records USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: business_accounts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.business_accounts ENABLE ROW LEVEL SECURITY;

--
-- Name: business_accounts business_accounts_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY business_accounts_auth_policy ON public.business_accounts USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: business_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.business_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: carcass_breakdown_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.carcass_breakdown_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: carcass_cuts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.carcass_cuts ENABLE ROW LEVEL SECURITY;

--
-- Name: carcass_cuts carcass_cuts_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY carcass_cuts_auth_policy ON public.carcass_cuts USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: carcass_intakes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.carcass_intakes ENABLE ROW LEVEL SECURITY;

--
-- Name: carcass_intakes carcass_intakes_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY carcass_intakes_auth_policy ON public.carcass_intakes USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

--
-- Name: chart_of_accounts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.chart_of_accounts ENABLE ROW LEVEL SECURITY;

--
-- Name: chart_of_accounts chart_of_accounts_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY chart_of_accounts_auth_policy ON public.chart_of_accounts USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: compliance_records; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.compliance_records ENABLE ROW LEVEL SECURITY;

--
-- Name: compliance_records compliance_records_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY compliance_records_auth_policy ON public.compliance_records USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: customer_announcements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.customer_announcements ENABLE ROW LEVEL SECURITY;

--
-- Name: customer_announcements customer_announcements_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY customer_announcements_auth_policy ON public.customer_announcements USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: donations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;

--
-- Name: dryer_batch_ingredients; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.dryer_batch_ingredients ENABLE ROW LEVEL SECURITY;

--
-- Name: dryer_batches; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.dryer_batches ENABLE ROW LEVEL SECURITY;

--
-- Name: dryer_batches dryer_batches_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY dryer_batches_auth_policy ON public.dryer_batches USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: equipment_assets; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.equipment_assets ENABLE ROW LEVEL SECURITY;

--
-- Name: equipment_assets equipment_assets_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY equipment_assets_auth_policy ON public.equipment_assets USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: equipment_register; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.equipment_register ENABLE ROW LEVEL SECURITY;

--
-- Name: event_sales_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.event_sales_history ENABLE ROW LEVEL SECURITY;

--
-- Name: event_tags; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.event_tags ENABLE ROW LEVEL SECURITY;

--
-- Name: event_tags event_tags_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY event_tags_auth_policy ON public.event_tags USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: hunter_job_processes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hunter_job_processes ENABLE ROW LEVEL SECURITY;

--
-- Name: hunter_jobs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hunter_jobs ENABLE ROW LEVEL SECURITY;

--
-- Name: hunter_jobs hunter_jobs_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY hunter_jobs_auth_policy ON public.hunter_jobs USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: hunter_process_materials; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hunter_process_materials ENABLE ROW LEVEL SECURITY;

--
-- Name: hunter_service_config; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hunter_service_config ENABLE ROW LEVEL SECURITY;

--
-- Name: hunter_service_config hunter_service_config_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY hunter_service_config_auth_policy ON public.hunter_service_config USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: hunter_services; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.hunter_services ENABLE ROW LEVEL SECURITY;

--
-- Name: inventory_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;

--
-- Name: invoice_line_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.invoice_line_items ENABLE ROW LEVEL SECURITY;

--
-- Name: invoices; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

--
-- Name: invoices invoices_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY invoices_auth_policy ON public.invoices USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: leave_balances; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.leave_balances ENABLE ROW LEVEL SECURITY;

--
-- Name: leave_requests; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;

--
-- Name: leave_requests leave_requests_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY leave_requests_auth_policy ON public.leave_requests USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: ledger_entries; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ledger_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: ledger_entries ledger_entries_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY ledger_entries_auth_policy ON public.ledger_entries USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: loyalty_customers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.loyalty_customers ENABLE ROW LEVEL SECURITY;

--
-- Name: message_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.message_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: modifier_groups; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.modifier_groups ENABLE ROW LEVEL SECURITY;

--
-- Name: modifier_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.modifier_items ENABLE ROW LEVEL SECURITY;

--
-- Name: payroll_entries; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payroll_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: payroll_entries payroll_entries_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY payroll_entries_auth_policy ON public.payroll_entries USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: payroll_periods; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payroll_periods ENABLE ROW LEVEL SECURITY;

--
-- Name: printer_config; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.printer_config ENABLE ROW LEVEL SECURITY;

--
-- Name: product_suppliers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.product_suppliers ENABLE ROW LEVEL SECURITY;

--
-- Name: production_batch_ingredients; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.production_batch_ingredients ENABLE ROW LEVEL SECURITY;

--
-- Name: production_batch_outputs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.production_batch_outputs ENABLE ROW LEVEL SECURITY;

--
-- Name: production_batches; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.production_batches ENABLE ROW LEVEL SECURITY;

--
-- Name: production_batches production_batches_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY production_batches_auth_policy ON public.production_batches USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: purchase_order_lines; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.purchase_order_lines ENABLE ROW LEVEL SECURITY;

--
-- Name: purchase_orders; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.purchase_orders ENABLE ROW LEVEL SECURITY;

--
-- Name: purchase_sale_agreement; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.purchase_sale_agreement ENABLE ROW LEVEL SECURITY;

--
-- Name: purchase_sale_agreements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.purchase_sale_agreements ENABLE ROW LEVEL SECURITY;

--
-- Name: purchase_sale_agreements purchase_sale_agreements_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY purchase_sale_agreements_auth_policy ON public.purchase_sale_agreements USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: purchase_sale_payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.purchase_sale_payments ENABLE ROW LEVEL SECURITY;

--
-- Name: recipe_ingredients; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.recipe_ingredients ENABLE ROW LEVEL SECURITY;

--
-- Name: recipes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;

--
-- Name: recipes recipes_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY recipes_auth_policy ON public.recipes USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: reorder_recommendations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.reorder_recommendations ENABLE ROW LEVEL SECURITY;

--
-- Name: role_permissions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;

--
-- Name: sales_transactions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sales_transactions ENABLE ROW LEVEL SECURITY;

--
-- Name: scale_config; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.scale_config ENABLE ROW LEVEL SECURITY;

--
-- Name: shrinkage_alerts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.shrinkage_alerts ENABLE ROW LEVEL SECURITY;

--
-- Name: shrinkage_alerts shrinkage_alerts_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY shrinkage_alerts_auth_policy ON public.shrinkage_alerts USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: sponsorships; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sponsorships ENABLE ROW LEVEL SECURITY;

--
-- Name: staff_awol_records; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.staff_awol_records ENABLE ROW LEVEL SECURITY;

--
-- Name: staff_credit; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.staff_credit ENABLE ROW LEVEL SECURITY;

--
-- Name: staff_credits; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.staff_credits ENABLE ROW LEVEL SECURITY;

--
-- Name: staff_credits staff_credits_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY staff_credits_auth_policy ON public.staff_credits USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: staff_documents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.staff_documents ENABLE ROW LEVEL SECURITY;

--
-- Name: staff_loans; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.staff_loans ENABLE ROW LEVEL SECURITY;

--
-- Name: staff_profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.staff_profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: staff_profiles staff_profiles_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY staff_profiles_auth_policy ON public.staff_profiles USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: stock_locations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.stock_locations ENABLE ROW LEVEL SECURITY;

--
-- Name: stock_movements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;

--
-- Name: stock_take_entries; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.stock_take_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: stock_take_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.stock_take_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: stock_takes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.stock_takes ENABLE ROW LEVEL SECURITY;

--
-- Name: stock_takes stock_takes_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY stock_takes_auth_policy ON public.stock_takes USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: suppliers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;

--
-- Name: suppliers suppliers_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY suppliers_auth_policy ON public.suppliers USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: system_config; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.system_config ENABLE ROW LEVEL SECURITY;

--
-- Name: tax_rules; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tax_rules ENABLE ROW LEVEL SECURITY;

--
-- Name: timecards; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.timecards ENABLE ROW LEVEL SECURITY;

--
-- Name: timecards timecards_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY timecards_auth_policy ON public.timecards USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: transaction_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.transaction_items ENABLE ROW LEVEL SECURITY;

--
-- Name: transactions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

--
-- Name: yield_template_cuts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.yield_template_cuts ENABLE ROW LEVEL SECURITY;

--
-- Name: yield_templates; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.yield_templates ENABLE ROW LEVEL SECURITY;

--
-- Name: yield_templates yield_templates_auth_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY yield_templates_auth_policy ON public.yield_templates USING ((auth.uid() IS NOT NULL)) WITH CHECK ((auth.uid() IS NOT NULL));


--
-- PostgreSQL database dump complete
--

\unrestrict Ex4xvBrmSQRNKWKnMsTNkkB9wQkqotFgsI5GeVBjtO0aWOu5DOhlMWGe6nfn68p

