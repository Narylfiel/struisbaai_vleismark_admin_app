-- ═══════════════════════════════════════════════════════════════════════════════
-- FULL SCHEMA AUDIT — Admin App (APP 2)
-- Run this in Supabase Dashboard → SQL Editor to verify the entire public schema.
-- Compare results with admin_app/supabase/migrations/ (001–032) and app .from('table') usage.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ── 1. All tables in public schema ───────────────────────────────────────────
SELECT
  table_name,
  (SELECT count(*) FROM information_schema.columns c
   WHERE c.table_schema = t.table_schema AND c.table_name = t.table_name) AS column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;


-- ── 2. All columns (full schema) — table, column, type, nullable, default ────
SELECT
  table_name,
  column_name,
  data_type,
  character_maximum_length,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;


-- ── 3. Primary keys ──────────────────────────────────────────────────────────
SELECT
  tc.table_name,
  kcu.column_name,
  tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
WHERE tc.table_schema = 'public'
  AND tc.constraint_type = 'PRIMARY KEY'
ORDER BY tc.table_name, kcu.ordinal_position;


-- ── 4. Foreign keys (references) ─────────────────────────────────────────────
SELECT
  tc.table_name AS from_table,
  kcu.column_name AS from_column,
  ccu.table_name AS to_table,
  ccu.column_name AS to_column,
  tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON tc.constraint_name = ccu.constraint_name
  AND tc.table_schema = ccu.table_schema
WHERE tc.table_schema = 'public'
  AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_name, kcu.ordinal_position;


-- ── 5. Unique constraints ────────────────────────────────────────────────────
SELECT
  tc.table_name,
  kcu.column_name,
  tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
WHERE tc.table_schema = 'public'
  AND tc.constraint_type = 'UNIQUE'
ORDER BY tc.table_name, kcu.ordinal_position;


-- ── 6. Check constraints ─────────────────────────────────────────────────────
SELECT
  tc.table_name,
  tc.constraint_name,
  cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc
  ON tc.constraint_name = cc.constraint_name
  AND tc.table_schema = cc.constraint_schema
WHERE tc.table_schema = 'public'
  AND tc.constraint_type = 'CHECK'
ORDER BY tc.table_name;


-- ── 7. Indexes (non-PK, non-unique) ─────────────────────────────────────────
SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;


-- ── 8. Row counts per table (optional — can be slow on large DBs) ─────────────
-- Uncomment to run:
/*
SELECT
  relname AS table_name,
  n_live_tup AS row_estimate
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY relname;
*/
