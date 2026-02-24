-- Migration 038: Ensure recipes.created_by exists (audit trail).
-- PostgrestException PGRST204: column 'created_by' missing from schema cache.
-- 001 defines it with REFERENCES profiles(id); this adds it if missing (nullable, no FK to avoid profiles dependency).

ALTER TABLE recipes ADD COLUMN IF NOT EXISTS created_by UUID;

COMMENT ON COLUMN recipes.created_by IS 'Staff who created the recipe (audit); may reference staff_profiles(id) or profiles(id).';
