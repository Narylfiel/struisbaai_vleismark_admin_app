-- fix_missing_schema_from_blueprint.sql
-- Idempotent SQL migration strictly creating missing tables required by the blueprint

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

-- Note: In older modules, missing references to accounts, customers, carcass_intake, and audit_logs
-- have been mapped to their existing Supabase counterparts (business_accounts, loyalty_customers, 
-- carcass_intakes, audit_log) within the Dart application code. No structural changes needed for them.
