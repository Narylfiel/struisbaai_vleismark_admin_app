-- 060: RLS lockdown — core financial / stock write tables (Phase 3, gated)
--
-- Apply ONLY after the Phase Gate in the RLS hardening plan:
--   Edge Functions deployed; client writes routed (USE_EDGE_PIPELINE=true); smoke tests pass.
--
-- Effect: removes the permissive anon policy "Allow all for anon" where it exists on the
-- tables below. Service-role writes (Edge Functions) are unaffected. Authenticated policies
-- that already exist (e.g. ledger_entries_auth_policy) remain; anon direct PostgREST
-- access to these tables is denied.
--
-- Prerequisite: snapshot pg_policies / known-good backup before applying.
--
-- Out of scope here: timecards / timecard_breaks anon policies — Clock-In may still need
-- anon SELECT until reads are mediated; drop those in a follow-up migration with a read strategy.

BEGIN;

DROP POLICY IF EXISTS "Allow all for anon" ON public.ledger_entries;
DROP POLICY IF EXISTS "Allow all for anon" ON public.stock_movements;
DROP POLICY IF EXISTS "Allow all for anon" ON public.transactions;
DROP POLICY IF EXISTS "Allow all for anon" ON public.transaction_items;

COMMIT;
