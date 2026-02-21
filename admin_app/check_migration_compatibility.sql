-- Migration Compatibility Check
-- This script checks exactly what the migration expects vs what exists

-- Check existence of specific tables referenced in migration
SELECT 'Checking table existence...' as status;

SELECT
    table_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = t.table_name
    ) THEN 'EXISTS' ELSE 'MISSING' END as status
FROM (VALUES
    ('profiles'),
    ('inventory_items'),
    ('categories'),
    ('sales_transactions'),
    ('transaction_items'),
    ('business_accounts'),
    ('leave_requests'),
    ('payroll_entries'),
    ('shrinkage_alerts'),
    ('reorder_recommendations'),
    ('carcass_intakes'),
    ('carcass_breakdown_sessions'),
    ('stock_movements'),
    ('production_batches'),
    ('hunter_jobs'),
    ('invoices'),
    ('ledger_entries'),
    ('loyalty_customers'),
    ('announcements'),
    ('event_sales_history'),
    ('account_awol_records'),
    ('payroll_periods'),
    ('recipes'),
    ('recipe_ingredients')
) AS t(table_name);

-- Check specific columns that the migration tries to index
SELECT 'Checking column existence for indexing...' as status;

-- Profiles table columns
SELECT
    'profiles' as table_name,
    'is_active' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'is_active'
    ) THEN 'EXISTS' ELSE 'MISSING' END as status
UNION ALL
SELECT
    'profiles' as table_name,
    'role' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'role'
    ) THEN 'EXISTS' ELSE 'MISSING' END as status
UNION ALL
-- Inventory items columns
SELECT
    'inventory_items' as table_name,
    'category_id' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'inventory_items' AND column_name = 'category_id'
    ) THEN 'EXISTS' ELSE 'MISSING' END as status
UNION ALL
SELECT
    'inventory_items' as table_name,
    'is_active' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'inventory_items' AND column_name = 'is_active'
    ) THEN 'EXISTS' ELSE 'MISSING' END as status
UNION ALL
SELECT
    'inventory_items' as table_name,
    'plu_code' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'inventory_items' AND column_name = 'plu_code'
    ) THEN 'EXISTS' ELSE 'MISSING' END as status
UNION ALL
-- Categories columns
SELECT
    'categories' as table_name,
    'is_active' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'categories' AND column_name = 'is_active'
    ) THEN 'EXISTS' ELSE 'MISSING' END as status
UNION ALL
-- Business accounts columns
SELECT
    'business_accounts' as table_name,
    'active' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'business_accounts' AND column_name = 'active'
    ) THEN 'EXISTS' ELSE 'MISSING' END as status
UNION ALL
SELECT
    'business_accounts' as table_name,
    'balance' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'business_accounts' AND column_name = 'balance'
    ) THEN 'EXISTS' ELSE 'MISSING' END as status;