-- Migration 059: Enforce one refund per original transaction (DB-level)
--
-- Business rule:
-- - Refunds are financial-only transactions linked via `refund_of_transaction_id`.
-- - Enforce that each original transaction can have at most one refund.
--
-- Safety:
-- - If duplicates already exist in production, this migration will fail
--   with a clear message so we don't silently break/partially enforce the constraint.

DO $$
DECLARE
  dup_count INT := 0;
BEGIN
  SELECT COUNT(*) INTO dup_count
  FROM (
    SELECT refund_of_transaction_id
    FROM public.transactions
    WHERE is_refund = true
      AND refund_of_transaction_id IS NOT NULL
    GROUP BY refund_of_transaction_id
    HAVING COUNT(*) > 1
  ) d;

  IF dup_count > 0 THEN
    -- Emit a NOTICE log (Supabase migration console) with details.
    FOR r IN
      SELECT refund_of_transaction_id, COUNT(*) AS cnt
      FROM public.transactions
      WHERE is_refund = true
        AND refund_of_transaction_id IS NOT NULL
      GROUP BY refund_of_transaction_id
      HAVING COUNT(*) > 1
    LOOP
      RAISE NOTICE 'Duplicate refunds detected for refund_of_transaction_id=% count=%',
        r.refund_of_transaction_id, r.cnt;
    END LOOP;

    RAISE EXCEPTION
      'Aborting migration 059_refund_uniqueness.sql: found % original transaction(s) with duplicate refunds. Resolve duplicates before enabling the unique index.',
      dup_count;
  END IF;

  EXECUTE $q$
    CREATE UNIQUE INDEX idx_unique_refund_per_transaction
    ON public.transactions (refund_of_transaction_id)
    WHERE is_refund = true AND refund_of_transaction_id IS NOT NULL
  $q$;
END $$;

