-- Blueprint §9.1: Supplier invoices — supplier_id, status pending_review for OCR/manual approval flow.

-- Invoices: link to supplier (supplier invoices)
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS supplier_id UUID REFERENCES suppliers(id);

-- Allow status 'pending_review' for OCR/manual review before approval
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'invoices') THEN
    ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_status_check;
    ALTER TABLE invoices ADD CONSTRAINT invoices_status_check CHECK (
      status IN ('draft', 'pending_review', 'approved', 'sent', 'paid', 'overdue', 'cancelled')
    );
  END IF;
EXCEPTION
  WHEN others THEN NULL;
END $$;

COMMENT ON COLUMN invoices.supplier_id IS 'Blueprint §9.1: Supplier for this invoice (supplier invoices)';
