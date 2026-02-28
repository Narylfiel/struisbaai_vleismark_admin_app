-- Migration 052: Supplier invoice receive — add received status and received_at/received_by.
-- Stock increases when invoice is marked received (not on approval).
-- Receive is allowed only when status is 'approved'; once received cannot receive again.

-- Drop existing status CHECK and re-add with 'received'
ALTER TABLE supplier_invoices
  DROP CONSTRAINT IF EXISTS supplier_invoices_status_check;

ALTER TABLE supplier_invoices
  ADD CONSTRAINT supplier_invoices_status_check
  CHECK (status IN ('draft','pending_review','approved','paid','overdue','cancelled','received'));

-- Track when and by whom goods were received
ALTER TABLE supplier_invoices
  ADD COLUMN IF NOT EXISTS received_at TIMESTAMPTZ NULL;

ALTER TABLE supplier_invoices
  ADD COLUMN IF NOT EXISTS received_by UUID NULL REFERENCES profiles(id);
