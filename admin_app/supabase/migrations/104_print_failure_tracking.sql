-- Migration 104: Add print failure tracking to online_order_print_queue
-- This is an ADDITIVE migration - no existing columns are modified

-- Add print failure tracking columns
ALTER TABLE online_order_print_queue 
ADD COLUMN print_attempts INTEGER DEFAULT 0 NOT NULL,
ADD COLUMN last_error TEXT NULL;

-- Add index for efficient failed job queries
CREATE INDEX idx_online_order_print_queue_failed_jobs 
ON online_order_print_queue (last_error) 
WHERE last_error IS NOT NULL;

-- Add index for print attempts tracking
CREATE INDEX idx_online_order_print_queue_attempts 
ON online_order_print_queue (print_attempts);

-- Add comment for documentation
COMMENT ON COLUMN online_order_print_queue.print_attempts IS 'Number of print attempts made for this job';
COMMENT ON COLUMN online_order_print_queue.last_error IS 'Last error message if print failed';

-- Validation: Check columns were added
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'online_order_print_queue' 
  AND column_name IN ('print_attempts', 'last_error')
ORDER BY column_name;
