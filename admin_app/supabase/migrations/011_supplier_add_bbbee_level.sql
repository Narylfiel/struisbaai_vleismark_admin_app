-- Fix: suppliers table may have been created without bbbee_level (e.g. pre-010).
-- Ensures column exists for Blueprint §4.6.
ALTER TABLE suppliers ADD COLUMN IF NOT EXISTS bbbee_level TEXT;
COMMENT ON COLUMN suppliers.bbbee_level IS 'e.g. Level 2';
