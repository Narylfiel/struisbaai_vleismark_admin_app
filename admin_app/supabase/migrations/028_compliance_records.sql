-- H4: BCEA Compliance — document expiry tracking per staff (ID, work permit, health cert, etc.)
CREATE TABLE IF NOT EXISTS compliance_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL,
  expiry_date DATE,
  file_url TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(staff_id, document_type)
);

CREATE INDEX IF NOT EXISTS idx_compliance_records_staff_id ON compliance_records(staff_id);
CREATE INDEX IF NOT EXISTS idx_compliance_records_document_type ON compliance_records(document_type);
CREATE INDEX IF NOT EXISTS idx_compliance_records_expiry_date ON compliance_records(expiry_date);

COMMENT ON TABLE compliance_records IS 'H4: BCEA document compliance — one row per staff per document type; expiry and file link.';
