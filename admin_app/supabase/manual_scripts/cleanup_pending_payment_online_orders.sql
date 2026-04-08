-- =============================================================================
-- Manual: cancel stuck online_orders in pending_payment (NO DELETES)
-- =============================================================================
-- Run in Supabase SQL Editor (or psql) against the production project after
-- you have confirmed every target row is an intentional test / abandoned
-- checkout (not a real customer still paying).
--
-- Rules:
--   - Updates ONLY table: public.online_orders
--   - Sets status transition + cancellation audit fields only
--   - Idempotent: re-run updates 0 rows once nothing is pending_payment
--
-- Does NOT touch: online_order_items, payments, stock, ledger.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- STEP 1 — Preview (counts + ids + test flag)
-- -----------------------------------------------------------------------------
SELECT status, COUNT(*) AS n
FROM online_orders
GROUP BY status
ORDER BY status;

SELECT id,
       order_number,
       is_test,
       payment_method,
       created_at
FROM online_orders
WHERE status = 'pending_payment'
ORDER BY created_at;

-- -----------------------------------------------------------------------------
-- STEP 2 — Apply cancellation (single statement; use RETURNING for audit log)
-- -----------------------------------------------------------------------------
-- Expected: each returned row was pending_payment and is now cancelled.
-- Second run: 0 rows returned.

UPDATE online_orders
SET
  status = 'cancelled',
  cancelled_at = NOW(),
  cancellation_reason = 'Test order cleanup (manual)'
WHERE status = 'pending_payment'
RETURNING id, order_number, cancelled_at, cancellation_reason;

-- -----------------------------------------------------------------------------
-- STEP 3 — Post-check (validation)
-- -----------------------------------------------------------------------------
SELECT status, COUNT(*) AS n
FROM online_orders
GROUP BY status
ORDER BY status;

-- Spot-check: cancelled rows from this run should have the reason set.
-- SELECT id, status, cancelled_at, cancellation_reason
-- FROM online_orders
-- WHERE cancellation_reason = 'Test order cleanup (manual)'
-- ORDER BY cancelled_at DESC
-- LIMIT 50;

-- =============================================================================
-- OPTIONAL — stricter scope (only if you use is_test and want belt + suspenders)
-- =============================================================================
-- Uncomment and use INSTEAD of STEP 2 if every stuck row is is_test = true
-- and you must not touch any non-test pending_payment row:
--
-- UPDATE online_orders
-- SET
--   status = 'cancelled',
--   cancelled_at = NOW(),
--   cancellation_reason = 'Test order cleanup (manual)'
-- WHERE status = 'pending_payment'
--   AND is_test = true
-- RETURNING id, order_number, cancelled_at, cancellation_reason;
