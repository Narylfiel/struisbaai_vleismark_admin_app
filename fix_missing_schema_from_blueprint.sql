-- fix_missing_schema_from_blueprint.sql
-- Idempotent SQL migration strictly creating missing tables required by the blueprint

-- Base tables that already existed or were identified in previous schema pass
CREATE TABLE IF NOT EXISTS public.sales_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    receipt_number TEXT UNIQUE,
    total_amount NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    tax_amount NUMERIC(10,2) DEFAULT 0.00,
    payment_method TEXT,
    staff_id UUID,
    status TEXT DEFAULT 'completed',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.tax_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    percentage NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.system_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL,
    description TEXT,
    value JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.scale_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    primary_mode TEXT DEFAULT 'Price-embedded',
    plu_digits INTEGER DEFAULT 4,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.printer_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT,
    ip_address TEXT,
    port INTEGER DEFAULT 9100,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name TEXT UNIQUE NOT NULL,
    permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ==================================================================
-- PHASE 2: MISSING SCHEMAS FROM THE BLUEPRINT AUDIT
-- ==================================================================

-- 1. HR & Staff
CREATE TABLE IF NOT EXISTS public.staff_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID, -- References public.profiles(id)
    document_type TEXT NOT NULL,
    document_url TEXT NOT NULL,
    expiry_date DATE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.staff_credit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID,
    amount NUMERIC(10,2) NOT NULL,
    transaction_type TEXT NOT NULL, -- 'purchase', 'payment', 'adjustment'
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.staff_loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID,
    principal_amount NUMERIC(10,2) NOT NULL,
    remaining_amount NUMERIC(10,2) NOT NULL,
    installment_amount NUMERIC(10,2) NOT NULL,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.account_awol_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID,
    date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.payroll_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status TEXT DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.payroll_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    period_id UUID REFERENCES public.payroll_periods(id) ON DELETE CASCADE,
    staff_id UUID,
    basic_pay NUMERIC(10,2) DEFAULT 0,
    overtime_pay NUMERIC(10,2) DEFAULT 0,
    deductions NUMERIC(10,2) DEFAULT 0,
    net_pay NUMERIC(10,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Business Settings & Locations
CREATE TABLE IF NOT EXISTS public.business_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key TEXT UNIQUE NOT NULL,
    setting_value JSONB,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.stock_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- 'fridge', 'freezer', 'display', 'store'
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.equipment_register (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    serial_number TEXT,
    purchase_date DATE,
    purchase_price NUMERIC(10,2),
    status TEXT DEFAULT 'active',
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Inventory & Recipes
CREATE TABLE IF NOT EXISTS public.modifier_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    is_required BOOLEAN DEFAULT false,
    allow_multiple BOOLEAN DEFAULT false,
    max_selections INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.modifier_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES public.modifier_groups(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    price_adjustment NUMERIC(10,2) DEFAULT 0.00,
    linked_product_id TEXT, -- References physical inventory item if applicable
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id TEXT NOT NULL,
    location_id UUID REFERENCES public.stock_locations(id),
    quantity_changed NUMERIC(10,3) NOT NULL,
    movement_type TEXT NOT NULL, -- 'sale', 'intake', 'waste', 'transfer', 'production'
    reference_id TEXT,
    staff_id UUID,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    output_product_id TEXT NOT NULL,
    expected_yield_qty NUMERIC(10,3),
    instructions TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.recipe_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID REFERENCES public.recipes(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    quantity_required NUMERIC(10,3) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Production
CREATE TABLE IF NOT EXISTS public.yield_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    carcass_type TEXT NOT NULL,
    expected_input_weight NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.yield_template_cuts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES public.yield_templates(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    expected_yield_percentage NUMERIC(5,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.carcass_intakes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id TEXT,
    carcass_type TEXT NOT NULL,
    total_weight NUMERIC(10,2) NOT NULL,
    cost NUMERIC(10,2) NOT NULL,
    status TEXT DEFAULT 'pending_breakdown',
    received_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.carcass_breakdown_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    intake_id UUID REFERENCES public.carcass_intakes(id),
    template_id UUID REFERENCES public.yield_templates(id),
    staff_id UUID,
    start_time TIMESTAMPTZ DEFAULT now(),
    end_time TIMESTAMPTZ,
    status TEXT DEFAULT 'in_progress',
    total_yield_weight NUMERIC(10,2) DEFAULT 0,
    waste_weight NUMERIC(10,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.production_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID REFERENCES public.recipes(id),
    staff_id UUID,
    status TEXT DEFAULT 'planned',
    actual_yield_qty NUMERIC(10,3),
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.production_batch_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID REFERENCES public.production_batches(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    quantity_used NUMERIC(10,3) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.dryer_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id TEXT NOT NULL,
    wet_weight NUMERIC(10,2) NOT NULL,
    dry_weight NUMERIC(10,2),
    start_date DATE NOT NULL,
    expected_end_date DATE,
    actual_end_date DATE,
    status TEXT DEFAULT 'drying',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.dryer_batch_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID REFERENCES public.dryer_batches(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    quantity_used NUMERIC(10,3) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Hunter Module
CREATE TABLE IF NOT EXISTS public.hunter_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    price_per_kg NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.hunter_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_name TEXT NOT NULL,
    customer_phone TEXT,
    carcass_type TEXT NOT NULL,
    intake_weight NUMERIC(10,2) NOT NULL,
    status TEXT DEFAULT 'pending',
    total_cost NUMERIC(10,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.hunter_job_processes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID REFERENCES public.hunter_jobs(id) ON DELETE CASCADE,
    service_id UUID REFERENCES public.hunter_services(id),
    weight_allocated NUMERIC(10,2) NOT NULL,
    cost NUMERIC(10,2) NOT NULL,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.hunter_process_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    process_id UUID REFERENCES public.hunter_job_processes(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    quantity_used NUMERIC(10,3) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Accounting & Sales
CREATE TABLE IF NOT EXISTS public.chart_of_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- 'asset', 'liability', 'equity', 'revenue', 'expense'
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ledger_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID REFERENCES public.chart_of_accounts(id),
    transaction_date DATE NOT NULL,
    description TEXT,
    debit NUMERIC(12,2) DEFAULT 0,
    credit NUMERIC(12,2) DEFAULT 0,
    reference_id TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id TEXT,
    invoice_number TEXT UNIQUE NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    subtotal NUMERIC(10,2) DEFAULT 0,
    tax_amount NUMERIC(10,2) DEFAULT 0,
    total_amount NUMERIC(10,2) DEFAULT 0,
    status TEXT DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.invoice_line_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID REFERENCES public.invoices(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    quantity NUMERIC(10,3) NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    total_price NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.purchase_sale_agreement (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_name TEXT NOT NULL,
    total_value NUMERIC(12,2) NOT NULL,
    agreement_date DATE NOT NULL,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.purchase_sale_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agreement_id UUID REFERENCES public.purchase_sale_agreement(id),
    payment_date DATE NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.sponsorships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_name TEXT NOT NULL,
    event_details TEXT,
    value NUMERIC(10,2) NOT NULL,
    sponsorship_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_name TEXT NOT NULL,
    description TEXT,
    value NUMERIC(10,2) NOT NULL,
    donation_date DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 7. Customers & Marketing
CREATE TABLE IF NOT EXISTS public.loyalty_customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT UNIQUE,
    email TEXT UNIQUE,
    points NUMERIC(10,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    target_audience TEXT,
    status TEXT DEFAULT 'draft',
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.event_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.event_sales_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_tag_id UUID REFERENCES public.event_tags(id),
    sale_date DATE NOT NULL,
    revenue NUMERIC(10,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

--------------------------------------------------------------------------------
-- INDEXES
--------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_stock_movements_product ON public.stock_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_ledger_entries_account ON public.ledger_entries(account_id);
CREATE INDEX IF NOT EXISTS idx_invoices_customer ON public.invoices(customer_id);
CREATE INDEX IF NOT EXISTS idx_staff_documents_staff ON public.staff_documents(staff_id);

--------------------------------------------------------------------------------
-- TRIGGERS & RPC FUNCTIONS
--------------------------------------------------------------------------------

-- 1. Reorder Alerts
CREATE OR REPLACE FUNCTION public.check_reorder_levels()
RETURNS trigger AS $$
BEGIN
    -- Logic placeholder to insert into shrinkage_alerts or reorder_recommendations
    -- if NEW.stock_on_hand < NEW.reorder_threshold
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Shrinkage Detection
CREATE OR REPLACE FUNCTION public.detect_shrinkage()
RETURNS trigger AS $$
BEGIN
    -- Logic placeholder
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Account Suspension
CREATE OR REPLACE FUNCTION public.check_account_suspension()
RETURNS trigger AS $$
BEGIN
    -- Logic placeholder to suspend account if balance > limit
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. AWOL Detection
CREATE OR REPLACE FUNCTION public.detect_awol()
RETURNS void AS $$
BEGIN
    -- Logic placeholder for daily cron job
END;
$$ LANGUAGE plpgsql;

-- 5. Production Yield Calculation
CREATE OR REPLACE FUNCTION public.calculate_production_yield(breakdown_id UUID)
RETURNS NUMERIC AS $$
DECLARE
    total_yield NUMERIC;
BEGIN
    SELECT COALESCE(SUM(weight), 0) INTO total_yield 
    FROM stock_movements 
    WHERE reference_id = breakdown_id::TEXT AND movement_type = 'production';
    RETURN total_yield;
END;
$$ LANGUAGE plpgsql;
