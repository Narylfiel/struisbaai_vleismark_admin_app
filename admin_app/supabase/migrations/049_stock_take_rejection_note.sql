-- Stock-take: add rejection_note for reject workflow (staff can recount).
ALTER TABLE stock_take_sessions
  ADD COLUMN IF NOT EXISTS rejection_note TEXT;

COMMENT ON COLUMN stock_take_sessions.rejection_note IS 'Reason for rejection when status reverts to in_progress; staff can recount.';
