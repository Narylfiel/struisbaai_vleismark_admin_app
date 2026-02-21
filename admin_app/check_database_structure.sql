-- Database Structure Analysis Script
-- Run this first to understand what tables and columns exist

-- 1. Check what tables exist in the public schema
SELECT
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- 2. Check structure of key tables that the migration references
-- Check if profiles table exists and its structure
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'profiles'
ORDER BY ordinal_position;

-- Check if inventory_items table exists and its structure
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'inventory_items'
ORDER BY ordinal_position;

-- Check if categories table exists and its structure
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'categories'
ORDER BY ordinal_position;

-- Check if sales_transactions table exists and its structure
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'sales_transactions'
ORDER BY ordinal_position;

-- Check if transaction_items table exists and its structure
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'transaction_items'
ORDER BY ordinal_position;

-- Check if business_accounts table exists and its structure
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'business_accounts'
ORDER BY ordinal_position;

-- Check if invoices table exists and its structure
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'invoices'
ORDER BY ordinal_position;