-- Migration 051: Add foreign key from transactions.till_session_id to till_sessions(id).
-- Run after 050 (till_sessions table must exist).
-- Existing transactions with invalid till_session_id will cause this to fail; fix or null those first if needed.

ALTER TABLE transactions
  ADD CONSTRAINT transactions_till_session_id_fkey
  FOREIGN KEY (till_session_id) REFERENCES till_sessions(id);
