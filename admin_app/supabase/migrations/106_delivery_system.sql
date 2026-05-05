-- Migration 106: Delivery system
-- Safe, additive migration for delivery windows/zones/streets/settings and online_orders gaps.

BEGIN;

-- PART 2 — Create delivery_windows table
CREATE TABLE IF NOT EXISTS public.delivery_windows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  delivery_date date NOT NULL,
  opens_at timestamptz NOT NULL,
  closes_at timestamptz NOT NULL,
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'open', 'confirmed', 'closed', 'cancelled')),
  reminder_sent_at timestamptz,
  confirmed_at timestamptz,
  created_by uuid REFERENCES public.staff_profiles(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_delivery_windows_status
  ON public.delivery_windows(status);
CREATE INDEX IF NOT EXISTS idx_delivery_windows_delivery_date
  ON public.delivery_windows(delivery_date);

-- PART 3 — Create delivery_zones table
CREATE TABLE IF NOT EXISTS public.delivery_zones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  suburb_name text NOT NULL UNIQUE,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_delivery_zones_active
  ON public.delivery_zones(is_active);

-- PART 4 — Create delivery_streets table
CREATE TABLE IF NOT EXISTS public.delivery_streets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_id uuid NOT NULL REFERENCES public.delivery_zones(id) ON DELETE CASCADE,
  street_name text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(zone_id, street_name)
);

CREATE INDEX IF NOT EXISTS idx_delivery_streets_zone
  ON public.delivery_streets(zone_id);
CREATE INDEX IF NOT EXISTS idx_delivery_streets_active
  ON public.delivery_streets(is_active);

-- PART 5 — Create delivery_settings table
CREATE TABLE IF NOT EXISTS public.delivery_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_fee numeric NOT NULL DEFAULT 110.00,
  min_order_value numeric NOT NULL DEFAULT 500.00,
  auto_cancel_days integer NOT NULL DEFAULT 1,
  is_active boolean NOT NULL DEFAULT true,
  updated_at timestamptz DEFAULT now(),
  updated_by uuid REFERENCES public.staff_profiles(id) ON DELETE SET NULL
);

-- Insert default row if table is empty
INSERT INTO public.delivery_settings (delivery_fee, min_order_value, auto_cancel_days)
SELECT 110.00, 500.00, 1
WHERE NOT EXISTS (SELECT 1 FROM public.delivery_settings);

-- PART 1 — Fix online_orders schema gaps
ALTER TABLE public.online_orders
  ADD COLUMN IF NOT EXISTS held_at timestamptz,
  ADD COLUMN IF NOT EXISTS delivery_date date,
  ADD COLUMN IF NOT EXISTS delivery_zone text,
  ADD COLUMN IF NOT EXISTS special_instructions text,
  ADD COLUMN IF NOT EXISTS availability_confirmed boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS requires_unfrozen boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS route_order integer;

-- PART 6 — Add delivery_window_id FK to online_orders
ALTER TABLE public.online_orders
  ADD COLUMN IF NOT EXISTS delivery_window_id uuid
  REFERENCES public.delivery_windows(id) ON DELETE SET NULL;

-- PART 7 — RLS policies
ALTER TABLE public.delivery_windows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_streets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_settings ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'delivery_windows'
      AND policyname = 'Staff manage delivery windows'
  ) THEN
    CREATE POLICY "Staff manage delivery windows"
      ON public.delivery_windows FOR ALL
      TO authenticated
      USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'delivery_windows'
      AND policyname = 'Customers read open windows'
  ) THEN
    CREATE POLICY "Customers read open windows"
      ON public.delivery_windows FOR SELECT
      TO anon
      USING (status IN ('open', 'confirmed'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'delivery_zones'
      AND policyname = 'Staff manage zones'
  ) THEN
    CREATE POLICY "Staff manage zones"
      ON public.delivery_zones FOR ALL
      TO authenticated
      USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'delivery_zones'
      AND policyname = 'Customers read active zones'
  ) THEN
    CREATE POLICY "Customers read active zones"
      ON public.delivery_zones FOR SELECT
      TO anon
      USING (is_active = true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'delivery_streets'
      AND policyname = 'Staff manage streets'
  ) THEN
    CREATE POLICY "Staff manage streets"
      ON public.delivery_streets FOR ALL
      TO authenticated
      USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'delivery_streets'
      AND policyname = 'Customers read active streets'
  ) THEN
    CREATE POLICY "Customers read active streets"
      ON public.delivery_streets FOR SELECT
      TO anon
      USING (is_active = true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'delivery_settings'
      AND policyname = 'Staff manage settings'
  ) THEN
    CREATE POLICY "Staff manage settings"
      ON public.delivery_settings FOR ALL
      TO authenticated
      USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'delivery_settings'
      AND policyname = 'Customers read settings'
  ) THEN
    CREATE POLICY "Customers read settings"
      ON public.delivery_settings FOR SELECT
      TO anon
      USING (true);
  END IF;
END $$;

-- PART 8 — Seed initial delivery zones
INSERT INTO public.delivery_zones (suburb_name, sort_order) VALUES
  ('Durbanville', 1),
  ('Brackenfell', 2),
  ('Cape Gate', 3),
  ('Kraaifontein', 4)
ON CONFLICT (suburb_name) DO NOTHING;

-- PART 9 — updated_at triggers (only if helper function exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'update_updated_at_column'
      AND n.nspname = 'public'
  ) THEN
    CREATE OR REPLACE TRIGGER update_delivery_windows_updated_at
      BEFORE UPDATE ON public.delivery_windows
      FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

    CREATE OR REPLACE TRIGGER update_delivery_zones_updated_at
      BEFORE UPDATE ON public.delivery_zones
      FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

    CREATE OR REPLACE TRIGGER update_delivery_streets_updated_at
      BEFORE UPDATE ON public.delivery_streets
      FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

    CREATE OR REPLACE TRIGGER update_delivery_settings_updated_at
      BEFORE UPDATE ON public.delivery_settings
      FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
  END IF;
END $$;

COMMIT;
