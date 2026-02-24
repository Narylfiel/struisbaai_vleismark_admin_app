-- Migration 041: Persistence failure fixes (PERSISTENCE_FAILURE_AUDIT.md)
-- Safe: ALTER to allow nullable where app sends null; ADD unique index for upsert.
--
-- Fixes:
-- 1. invoices: account_id nullable (supplier-only invoices have no account_id)
-- 2. compliance_records: UNIQUE (staff_id, document_type) for upsert onConflict
-- 3. staff_profiles: pin_hash nullable (new staff can be created without PIN)
--

-- ═══════════════════════════════════════════════════════════════════
-- 1. invoices: allow account_id NULL (supplier invoices use supplier_id only)
-- ═══════════════════════════════════════════════════════════════════
ALTER TABLE invoices ALTER COLUMN account_id DROP NOT NULL;

-- ═══════════════════════════════════════════════════════════════════
-- 2. compliance_records: unique on (staff_id, document_type) for upsert
-- ═══════════════════════════════════════════════════════════════════
CREATE UNIQUE INDEX IF NOT EXISTS idx_compliance_records_staff_document
  ON compliance_records(staff_id, document_type);

-- ═══════════════════════════════════════════════════════════════════
-- 3. staff_profiles: allow pin_hash NULL (new staff without PIN)
-- ═══════════════════════════════════════════════════════════════════
ALTER TABLE staff_profiles ALTER COLUMN pin_hash DROP NOT NULL;

COMMENT ON COLUMN staff_profiles.pin_hash IS 'Hashed PIN for login; NULL until staff sets PIN.';
