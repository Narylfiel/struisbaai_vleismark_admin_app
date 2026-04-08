-- ============================================
-- MIGRATION 101: Atomic Print Job Claim
-- PURPOSE: Prevent duplicate printing across devices
-- DATE: 2026-04-08
-- ============================================

CREATE OR REPLACE FUNCTION claim_print_job(job_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_job JSONB;
BEGIN
  -- Atomically claim the print job
  -- Only succeeds if job is not already printed
  UPDATE online_order_print_queue
  SET printed = true,
      printed_at = now()
  WHERE id = job_id
    AND printed = false
  RETURNING to_jsonb(online_order_print_queue.*) INTO v_job;

  -- Return the job data if claimed, NULL if already printed
  RETURN v_job;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment
COMMENT ON FUNCTION claim_print_job IS 
'Atomically claim a print job by setting printed=true. Returns job data if successful, NULL if already printed. Prevents duplicate printing across devices.';

-- Grant execute to authenticated users (admin app)
GRANT EXECUTE ON FUNCTION claim_print_job TO authenticated;
