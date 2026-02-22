-- Fix Dryer: column dryer_batches.batch_number does not exist in some DBs.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'dryer_batches') THEN
    ALTER TABLE dryer_batches ADD COLUMN IF NOT EXISTS batch_number TEXT;
    -- Backfill existing rows with unique id-based value
    UPDATE dryer_batches SET batch_number = 'DB-' || REPLACE(id::text, '-', '') WHERE batch_number IS NULL OR batch_number = '';
    -- Ensure not null for new rows (allow null only if table had no rows)
    ALTER TABLE dryer_batches ALTER COLUMN batch_number SET DEFAULT 'DB-pending';
  END IF;
END $$;
