-- 062: calculate_supplier_spend RPC
-- Created live via Supabase MCP on 2026-03-26 — see session notes.
-- Function was created directly in the database (not via migration runner).
-- This file exists for migration sequence completeness only.
--
-- Live definition as at creation:
CREATE OR REPLACE FUNCTION public.calculate_supplier_spend(
  start_date text,
  end_date   text
)
RETURNS TABLE (
  supplier_name  text,
  total_amount   numeric,
  invoice_count  integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    s.name                AS supplier_name,
    SUM(i.total)          AS total_amount,
    COUNT(*)::integer     AS invoice_count
  FROM invoices i
  JOIN suppliers s ON s.id = i.supplier_id
  WHERE i.invoice_date >= start_date::date
    AND i.invoice_date <= end_date::date
  GROUP BY s.name
  ORDER BY total_amount DESC;
$$;
