-- H1: Hunter Job Intake/Process/Summary — add cut_options, processing_instructions, job_date, weight_in, cuts, paid.
-- Use hunter_services as species config; hunter_jobs stores intake and process data.

-- 1. hunter_services: cut_options jsonb (list of cut names for CheckboxListTile per species)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'hunter_services') THEN
    ALTER TABLE hunter_services ADD COLUMN IF NOT EXISTS cut_options JSONB DEFAULT '[]';
    COMMENT ON COLUMN hunter_services.cut_options IS 'H1: Cut names for processing (e.g. ["Steaks","Mince","Biltong"]) per species.';
  END IF;
END $$;

-- 2. hunter_jobs: job_date, processing_instructions (selected cuts), weight_in (actual), cuts (actual per-cut data), paid
--    Optional display columns for list: customer_name, customer_phone, animal_type, estimated_weight, total_amount (sync from client_name etc. if needed)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'hunter_jobs') THEN
    ALTER TABLE hunter_jobs ADD COLUMN IF NOT EXISTS job_date DATE DEFAULT CURRENT_DATE;
    ALTER TABLE hunter_jobs ADD COLUMN IF NOT EXISTS processing_instructions JSONB DEFAULT '[]';
    ALTER TABLE hunter_jobs ADD COLUMN IF NOT EXISTS weight_in DECIMAL(8,2);
    ALTER TABLE hunter_jobs ADD COLUMN IF NOT EXISTS cuts JSONB DEFAULT '[]';
    ALTER TABLE hunter_jobs ADD COLUMN IF NOT EXISTS paid BOOLEAN DEFAULT false;
    ALTER TABLE hunter_jobs ADD COLUMN IF NOT EXISTS customer_name TEXT;
    ALTER TABLE hunter_jobs ADD COLUMN IF NOT EXISTS customer_phone TEXT;
    ALTER TABLE hunter_jobs ADD COLUMN IF NOT EXISTS animal_type TEXT;
    ALTER TABLE hunter_jobs ADD COLUMN IF NOT EXISTS estimated_weight DECIMAL(8,2);
    ALTER TABLE hunter_jobs ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10,2);
    COMMENT ON COLUMN hunter_jobs.processing_instructions IS 'H1: Selected cut names from intake.';
    COMMENT ON COLUMN hunter_jobs.weight_in IS 'H1: Actual weight in (kg) after processing.';
    COMMENT ON COLUMN hunter_jobs.cuts IS 'H1: Per-cut actual weight and linked inventory_item_id.';
    COMMENT ON COLUMN hunter_jobs.paid IS 'H1: Mark paid on summary.';
  END IF;
END $$;

-- 3. Relax status check to include H1 flow (Intake, Processing, Ready for Collection, Completed)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT c.conname FROM pg_constraint c
    JOIN pg_class t ON c.conrelid = t.oid
    WHERE t.relname = 'hunter_jobs' AND c.contype = 'c'
  LOOP
    EXECUTE format('ALTER TABLE hunter_jobs DROP CONSTRAINT IF EXISTS %I', r.conname);
  END LOOP;
  ALTER TABLE hunter_jobs ADD CONSTRAINT hunter_jobs_status_check CHECK (
    status IN (
      'quoted', 'confirmed', 'in_progress', 'completed', 'cancelled',
      'intake', 'processing', 'ready', 'collected',
      'Intake', 'Processing', 'Ready for Collection', 'Completed'
    )
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
  WHEN others THEN NULL;
END $$;
