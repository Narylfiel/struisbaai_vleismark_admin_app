-- M2: Report scheduling — additive only (no ALTER/DROP on existing tables).
-- admin_notifications: dashboard delivery for scheduled reports (Admin only).
-- Do not use `notifications` (Loyalty Realtime) or `loyalty_notifications`.

-- ---------------------------------------------------------------------------
-- admin_notifications
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  body text,
  type text NOT NULL DEFAULT 'scheduled_report',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;

-- Authenticated staff: read dashboard notifications only.
-- Inserts come from Edge Function (service role bypasses RLS).
CREATE POLICY "admin_notifications_select_authenticated"
  ON public.admin_notifications
  FOR SELECT
  TO authenticated
  USING (true);

COMMENT ON TABLE public.admin_notifications IS 'Admin dashboard notifications (scheduled reports, etc.). Not for Loyalty app.';

-- ---------------------------------------------------------------------------
-- report_schedules
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.report_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_key text NOT NULL,
  label text NOT NULL,
  schedule_type text NOT NULL CHECK (schedule_type IN ('daily', 'weekly', 'monthly')),
  time_of_day text NOT NULL DEFAULT '06:00',
  day_of_week int NULL CHECK (day_of_week IS NULL OR (day_of_week >= 1 AND day_of_week <= 7)),
  day_of_month int NULL CHECK (day_of_month IS NULL OR (day_of_month >= 1 AND day_of_month <= 28)),
  delivery text[] NOT NULL DEFAULT ARRAY['dashboard']::text[],
  email_to text NULL,
  format text NOT NULL DEFAULT 'pdf' CHECK (format IN ('pdf', 'csv', 'xlsx')),
  date_range text NOT NULL DEFAULT 'last_7_days' CHECK (
    date_range IN (
      'today',
      'yesterday',
      'last_7_days',
      'last_30_days',
      'this_month',
      'last_month'
    )
  ),
  is_active boolean NOT NULL DEFAULT true,
  last_run_at timestamptz NULL,
  next_run_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_report_schedules_active_next
  ON public.report_schedules (is_active, next_run_at);

ALTER TABLE public.report_schedules ENABLE ROW LEVEL SECURITY;

-- Service role bypasses RLS. Authenticated: full CRUD for Admin app schedule management.
CREATE POLICY "report_schedules_select_authenticated"
  ON public.report_schedules FOR SELECT TO authenticated USING (true);
CREATE POLICY "report_schedules_insert_authenticated"
  ON public.report_schedules FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "report_schedules_update_authenticated"
  ON public.report_schedules FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "report_schedules_delete_authenticated"
  ON public.report_schedules FOR DELETE TO authenticated USING (true);

COMMENT ON TABLE public.report_schedules IS 'Scheduled report definitions. Edge function run-scheduled-reports uses service role.';

-- ---------------------------------------------------------------------------
-- scheduled_report_runs (audit log)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.scheduled_report_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_id uuid NOT NULL REFERENCES public.report_schedules(id) ON DELETE CASCADE,
  report_key text NOT NULL,
  status text NOT NULL CHECK (status IN ('success', 'error', 'no_data', 'not_implemented')),
  row_count int NULL,
  delivery_log jsonb NULL,
  error_message text NULL,
  run_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_scheduled_report_runs_schedule_run
  ON public.scheduled_report_runs (schedule_id, run_at DESC);

ALTER TABLE public.scheduled_report_runs ENABLE ROW LEVEL SECURITY;

-- Authenticated: read-only audit trail.
CREATE POLICY "scheduled_report_runs_select_authenticated"
  ON public.scheduled_report_runs FOR SELECT TO authenticated USING (true);

COMMENT ON TABLE public.scheduled_report_runs IS 'Audit log of scheduled report executions.';

-- ---------------------------------------------------------------------------
-- Seed rows (DefaultReportSchedules blueprint — labels match report types)
-- Fixed UUIDs so re-run is safe: ON CONFLICT (id) DO NOTHING
-- ---------------------------------------------------------------------------
INSERT INTO public.report_schedules (
  id, report_key, label, schedule_type, time_of_day, day_of_week, day_of_month,
  delivery, email_to, format, date_range, is_active, next_run_at, updated_at
) VALUES
  (
    'ee000000-0000-0000-0000-000000000001'::uuid,
    'daily_sales',
    'Daily Sales',
    'daily',
    '23:00',
    NULL,
    NULL,
    ARRAY['dashboard']::text[],
    NULL,
    'pdf',
    'today',
    true,
    now(),
    now()
  ),
  (
    'ee000000-0000-0000-0000-000000000002'::uuid,
    'weekly_sales',
    'Weekly Sales',
    'weekly',
    '06:00',
    1,
    NULL,
    ARRAY['dashboard', 'email']::text[],
    NULL,
    'pdf',
    'last_7_days',
    true,
    now(),
    now()
  ),
  (
    'ee000000-0000-0000-0000-000000000003'::uuid,
    'monthly_pl',
    'Monthly P&L',
    'monthly',
    '06:00',
    NULL,
    1,
    ARRAY['dashboard', 'email']::text[],
    NULL,
    'pdf',
    'last_month',
    true,
    now(),
    now()
  )
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- MANUAL STEP: Enable pg_cron in Supabase dashboard first.
-- Dashboard → Database → Extensions → pg_cron → Enable
-- Then uncomment the block below and re-run.
-- ============================================================
--
-- SELECT cron.schedule(
--   'run-scheduled-reports',
--   '*/15 * * * *',
--   $$
--   SELECT net.http_post(
--     url := current_setting('app.settings.edge_function_url', true) || '/functions/v1/run-scheduled-reports',
--     headers := jsonb_build_object(
--       'Content-Type', 'application/json',
--       'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
--     ),
--     body := '{}'::jsonb
--   ) AS request_id;
--   $$
-- );
-- NOTE: Configure `app.settings.edge_function_url` and `app.settings.service_role_key` via ALTER DATABASE
-- or use Supabase Dashboard → Database → Cron with the project invoke URL + service role from Vault.
-- Alternative: invoke from external cron (GitHub Actions, etc.) with POST + Authorization header.
