-- Migration 036: Create missing tables referenced by existing code
-- Safe: CREATE TABLE IF NOT EXISTS only. No changes to existing migrations or data.
-- Dependencies: profiles (referenced by account_awol_records in 002) may exist from Auth or other app.
--
-- COLUMN CHOICES (from repository/screen usage):
-- business_accounts: account_list_screen insert/update/select (name, contact_person, whatsapp, email, vat_number,
--   address, credit_limit, notes, account_type, credit_terms_days, auto_suspend, auto_suspend_days, is_active,
--   balance, updated_at); dashboard select (name, balance, credit_terms_days, is_active); 003 ALTER (active,
--   suspension_recommended); account_detail update (balance, updated_at); list select (suspended, suspended_at).
-- audit_log: audit_repository getAuditLogs (created_at gte/lte, action ilike, staff_name ilike, details ilike);
--   report_repository getAuditTrail (created_at, select *).
-- message_logs: whatsapp_service insert (message_sid, to_number, message_content, status, error_message, sent_at);
--   getMessageLogs select * order sent_at, filter sent_at gte/lte, status eq.

-- ═══════════════════════════════════════════════════════════════════
-- 1. business_accounts
-- Referenced by: account_awol_records (002), invoices (002), account_transactions (017).
-- Used by: account_list_screen (select/insert/update), account_detail_screen, dashboard_screen.
-- 003_indexes_triggers_rpc.sql ALTERs this table (active, suspension_recommended) and creates indexes.
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS business_accounts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  contact_person TEXT,
  email TEXT,
  whatsapp TEXT,
  phone TEXT,
  vat_number TEXT,
  address TEXT,
  notes TEXT,
  account_type TEXT DEFAULT 'Restaurant',
  balance DECIMAL(12,2) NOT NULL DEFAULT 0,
  credit_limit DECIMAL(12,2),
  credit_terms_days INTEGER DEFAULT 7,
  is_active BOOLEAN NOT NULL DEFAULT true,
  suspended BOOLEAN DEFAULT false,
  suspended_at TIMESTAMP WITH TIME ZONE,
  auto_suspend BOOLEAN DEFAULT false,
  auto_suspend_days INTEGER DEFAULT 30,
  active BOOLEAN DEFAULT true,
  suspension_recommended BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE business_accounts IS 'Business/credit accounts; referenced by account_transactions, invoices, account_awol_records.';

CREATE INDEX IF NOT EXISTS idx_business_accounts_is_active ON business_accounts(is_active);
CREATE INDEX IF NOT EXISTS idx_business_accounts_active ON business_accounts(active);
CREATE INDEX IF NOT EXISTS idx_business_accounts_balance ON business_accounts(balance);
CREATE INDEX IF NOT EXISTS idx_business_accounts_name ON business_accounts(name);

-- ═══════════════════════════════════════════════════════════════════
-- 2. audit_log
-- Used by: audit_repository.dart (getAuditLogs: created_at, action, staff_name, details),
--          report_repository.dart (getAuditTrail: created_at range, order created_at desc).
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  action TEXT NOT NULL,
  staff_id UUID,
  staff_name TEXT,
  details TEXT,
  severity TEXT
);

COMMENT ON TABLE audit_log IS 'Immutable system activity log; Module 14 Audit.';

CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log(action);

-- ═══════════════════════════════════════════════════════════════════
-- 3. message_logs
-- Used by: whatsapp_service.dart insert (message_sid, to_number, message_content, status, error_message, sent_at),
--          getMessageLogs select * order sent_at desc, filter sent_at gte/lte, status eq.
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS message_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  message_sid TEXT,
  to_number TEXT NOT NULL,
  message_content TEXT,
  status TEXT NOT NULL,
  error_message TEXT,
  sent_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE message_logs IS 'WhatsApp/SMS message audit trail; used by WhatsAppService.';

CREATE INDEX IF NOT EXISTS idx_message_logs_sent_at ON message_logs(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_message_logs_status ON message_logs(status);

-- ═══════════════════════════════════════════════════════════════════
-- VERIFICATION CHECKLIST (after running this migration)
-- ═══════════════════════════════════════════════════════════════════
-- [ ] 1. business_accounts: \d public.business_accounts shows id (uuid PK), name, balance, is_active, etc.
-- [ ] 2. account_transactions (017) FK: INSERT into account_transactions(account_id,...) with valid business_accounts.id succeeds.
-- [ ] 3. account_awol_records (002) FK: Same; account_id references business_accounts(id).
-- [ ] 4. invoices (002) account_id: Optional FK to business_accounts(id); no constraint change needed.
-- [ ] 5. audit_log: AuditRepository.getAuditLogs() returns rows (or []); no exception. Filter by created_at, action, staff_name, details.
-- [ ] 6. message_logs: WhatsAppService _logMessage insert succeeds; getMessageLogs() returns list. Filter by sent_at, status.
-- [ ] 7. App: Accounts → Account List loads; add new account saves; Dashboard overdue widget does not throw.
-- [ ] 8. App: Audit Log screen loads; Report Hub audit trail export works.
-- [ ] 9. App: WhatsApp send path logs to message_logs without error.
--
-- Fresh DB note: 002 and 017 reference business_accounts(id). If applying to a new DB where 002 has not
-- been run yet, run this migration (036) before 002 so business_accounts exists when FKs are created.
