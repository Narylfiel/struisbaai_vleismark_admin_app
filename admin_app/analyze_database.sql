-- Comprehensive Database Analysis
-- This will show us exactly what tables and columns exist

-- First, let's see ALL tables in the database
SELECT
    schemaname as schema_name,
    tablename as table_name,
    tableowner as owner
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, tablename;

-- Now let's check columns for tables that might be related to our admin app
-- Check for any table that might contain user/profile information
SELECT
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
WHERE t.table_schema = 'public'
AND t.table_name LIKE '%profile%' OR t.table_name LIKE '%user%' OR t.table_name LIKE '%staff%'
ORDER BY t.table_name, c.ordinal_position;

-- Check for inventory-related tables
SELECT
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
WHERE t.table_schema = 'public'
AND t.table_name LIKE '%inventory%' OR t.table_name LIKE '%item%' OR t.table_name LIKE '%product%'
ORDER BY t.table_name, c.ordinal_position;

-- Check for category-related tables
SELECT
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
WHERE t.table_schema = 'public'
AND t.table_name LIKE '%categor%'
ORDER BY t.table_name, c.ordinal_position;

-- Check for sales/transaction related tables
SELECT
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
WHERE t.table_schema = 'public'
AND t.table_name LIKE '%sale%' OR t.table_name LIKE '%transaction%'
ORDER BY t.table_name, c.ordinal_position;

-- Check for account/business related tables
SELECT
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
WHERE t.table_schema = 'public'
AND t.table_name LIKE '%account%' OR t.table_name LIKE '%business%'
ORDER BY t.table_name, c.ordinal_position;

-- Check for invoice related tables
SELECT
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
WHERE t.table_schema = 'public'
AND t.table_name LIKE '%invoice%'
ORDER BY t.table_name, c.ordinal_position;