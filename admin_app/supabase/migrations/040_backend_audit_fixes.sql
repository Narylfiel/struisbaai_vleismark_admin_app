-- Migration 040: Backend audit fixes (BACKEND_AUDIT_REPORT.md)
-- Safe: ADD COLUMN IF NOT EXISTS, CREATE TABLE IF NOT EXISTS. No destructive changes.
--
-- Fixes: leave_requests (review_notes, reviewed_at), leave_balances (staff_id),
--        timecard_breaks (missing table), event_tags (event_type),
--        supplier_price_changes (missing table), business_settings (setting_key/setting_value for key-value screens).
--

-- ═══════════════════════════════════════════════════════════════════
-- 1. leave_requests: add review_notes, reviewed_at (code: staff_list_screen)
-- ═══════════════════════════════════════════════════════════════════
ALTER TABLE leave_requests ADD COLUMN IF NOT EXISTS review_notes TEXT;
ALTER TABLE leave_requests ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP WITH TIME ZONE;

-- ═══════════════════════════════════════════════════════════════════
-- 2. leave_balances: add staff_id for join to staff_profiles (code: staff_list_screen)
-- ═══════════════════════════════════════════════════════════════════
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'leave_balances' AND column_name = 'staff_id') THEN
    ALTER TABLE leave_balances ADD COLUMN staff_id UUID REFERENCES staff_profiles(id);
  END IF;
END $$;
-- Backfill: staff_id = employee_id where staff_profiles.id = profiles.id (same identity)
UPDATE leave_balances lb
SET staff_id = lb.employee_id
WHERE lb.staff_id IS NULL AND lb.employee_id IS NOT NULL
  AND EXISTS (SELECT 1 FROM staff_profiles sp WHERE sp.id = lb.employee_id);

-- ═══════════════════════════════════════════════════════════════════
-- 3. timecard_breaks: missing table (code: staff_list_screen, compliance_service)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS timecard_breaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timecard_id UUID NOT NULL REFERENCES timecards(id) ON DELETE CASCADE,
  break_start TIMESTAMP WITH TIME ZONE,
  break_end TIMESTAMP WITH TIME ZONE,
  break_duration_minutes NUMERIC(6,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_timecard_breaks_timecard_id ON timecard_breaks(timecard_id);

-- ═══════════════════════════════════════════════════════════════════
-- 4. event_tags: add event_type (code: analytics_repository saveEventTag)
-- ═══════════════════════════════════════════════════════════════════
ALTER TABLE event_tags ADD COLUMN IF NOT EXISTS event_type TEXT;

-- ═══════════════════════════════════════════════════════════════════
-- 5. supplier_price_changes: missing table (code: analytics_repository)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS supplier_price_changes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inventory_item_id UUID,
  supplier_id UUID,
  old_price NUMERIC(10,2),
  new_price NUMERIC(10,2),
  percentage_increase NUMERIC(6,2),
  suggested_sell_price NUMERIC(10,2),
  status TEXT DEFAULT 'Pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_supplier_price_changes_status ON supplier_price_changes(status);
CREATE INDEX IF NOT EXISTS idx_supplier_price_changes_created_at ON supplier_price_changes(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════
-- 6. business_settings: add setting_key, setting_value for key-value screens (Scale/Tax/Notification)
-- ═══════════════════════════════════════════════════════════════════
ALTER TABLE business_settings ADD COLUMN IF NOT EXISTS setting_key TEXT;
ALTER TABLE business_settings ADD COLUMN IF NOT EXISTS setting_value JSONB;
CREATE UNIQUE INDEX IF NOT EXISTS idx_business_settings_setting_key
  ON business_settings(setting_key) WHERE setting_key IS NOT NULL;

COMMENT ON COLUMN business_settings.setting_key IS 'Optional key for key-value rows; null = main config row.';
COMMENT ON COLUMN business_settings.setting_value IS 'Optional value for key-value rows.';
