-- Migration 037: Create dashboard data tables (reorder_recommendations, leave_requests, timecards)
-- Safe: CREATE TABLE IF NOT EXISTS only. No changes to existing migrations or data.
--
-- DEPENDENCIES (documented for future work):
-- - reorder_recommendations: Populated by trigger in 003 (stock_movements). Expects inventory_items
--   (reorder_point, average_daily_sales, current_stock). inventory_items is not created in this repo
--   (assumed from POS or shared schema).
-- - leave_requests / timecards: Dashboard and HR (staff_list_screen) use these. timecards may be
--   populated by a separate Clock-In app; staff_profiles is not created in this repo (assumed from
--   auth or shared schema). staff_id is stored as UUID; no FK to staff_profiles so migration
--   succeeds even if staff_profiles does not exist yet.
--
-- Used by: dashboard_screen.dart (alerts, clock-in status), staff_list_screen.dart (leave, timecards),
--          analytics_repository.dart (reorder), report_repository.dart (timecards).

-- ═══════════════════════════════════════════════════════════════════
-- 1. reorder_recommendations
-- Trigger in 003_indexes_triggers_rpc.sql inserts (item_id, current_stock, reorder_point,
-- days_of_stock, recommended_quantity). Dashboard selects *, inventory_items(name), auto_resolved = false.
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS reorder_recommendations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  item_id UUID NOT NULL,
  current_stock DECIMAL(10,3) NOT NULL DEFAULT 0,
  reorder_point DECIMAL(10,3) NOT NULL DEFAULT 0,
  days_of_stock DECIMAL(8,2) NOT NULL,
  recommended_quantity DECIMAL(10,3) NOT NULL DEFAULT 0,
  auto_resolved BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE reorder_recommendations IS 'Low-stock alerts; populated by trigger on stock_movements (003). item_id logically references inventory_items(id).';

CREATE INDEX IF NOT EXISTS idx_reorder_recommendations_item_id ON reorder_recommendations(item_id);
CREATE INDEX IF NOT EXISTS idx_reorder_recommendations_auto_resolved ON reorder_recommendations(auto_resolved);
CREATE INDEX IF NOT EXISTS idx_reorder_recommendations_days_of_stock ON reorder_recommendations(days_of_stock);

-- Optional FK only if inventory_items exists (avoids migration failure on fresh DB without inventory)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'inventory_items') THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints
      WHERE table_schema = 'public' AND table_name = 'reorder_recommendations' AND constraint_name = 'reorder_recommendations_item_id_fkey'
    ) THEN
      ALTER TABLE reorder_recommendations
        ADD CONSTRAINT reorder_recommendations_item_id_fkey
        FOREIGN KEY (item_id) REFERENCES inventory_items(id) ON DELETE CASCADE;
    END IF;
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════
-- 2. leave_requests
-- Dashboard: status = 'Pending', staff_profiles!staff_id(full_name). Staff list: status, review_notes, reviewed_at.
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS leave_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID NOT NULL,
  status TEXT NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Approved', 'Rejected')),
  leave_type TEXT,
  start_date DATE,
  end_date DATE,
  review_notes TEXT,
  reviewed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE leave_requests IS 'Staff leave requests; dashboard shows Pending. staff_id logically references staff_profiles(id).';

CREATE INDEX IF NOT EXISTS idx_leave_requests_status ON leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_leave_requests_staff_id ON leave_requests(staff_id);
CREATE INDEX IF NOT EXISTS idx_leave_requests_created_at ON leave_requests(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════
-- 3. timecards
-- Dashboard: staff_id, clock_in, gte clock_in today. Staff list / reports: clock_in, clock_out,
-- total_hours, regular_hours, overtime_hours, sunday_hours, breaks (or timecard_breaks table).
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS timecards (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID NOT NULL,
  clock_in TIMESTAMP WITH TIME ZONE NOT NULL,
  clock_out TIMESTAMP WITH TIME ZONE,
  total_hours DECIMAL(6,2),
  regular_hours DECIMAL(6,2),
  overtime_hours DECIMAL(6,2),
  sunday_hours DECIMAL(6,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE timecards IS 'Clock-in/out records; dashboard shows who is clocked in today. May be populated by Clock-In app. staff_id logically references staff_profiles(id).';

CREATE INDEX IF NOT EXISTS idx_timecards_staff_id ON timecards(staff_id);
CREATE INDEX IF NOT EXISTS idx_timecards_clock_in ON timecards(clock_in);
CREATE INDEX IF NOT EXISTS idx_timecards_staff_clock ON timecards(staff_id, clock_in);
