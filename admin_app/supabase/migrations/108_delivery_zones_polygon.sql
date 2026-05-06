-- Migration 108: Polygon-based delivery zones
-- Adds delivery_zones_polygon table for coordinate-based delivery validation.
-- This is ADDITIVE — delivery_zones, delivery_streets, and delivery_settings
-- from migration 106 are left completely intact as fallback during transition.
--
-- DO NOT run automatically via CI. Execute manually in Supabase SQL Editor.

-- ── PART 1 — Create delivery_zones_polygon table ──────────────────────────────

CREATE TABLE IF NOT EXISTS public.delivery_zones_polygon (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text        NOT NULL,
  -- Array of {lat, lng} objects defining the closed polygon boundary.
  -- Example: [{"lat": -33.85, "lng": 18.68}, {"lat": -33.80, "lng": 18.70}, ...]
  -- Minimum 3 points required for a valid polygon.
  polygon     jsonb       NOT NULL DEFAULT '[]'::jsonb,
  delivery_fee  numeric   NOT NULL DEFAULT 110.00,
  minimum_order numeric   NOT NULL DEFAULT 500.00,
  delivery_day  text,
  is_active   boolean     NOT NULL DEFAULT true,
  color       text                 DEFAULT '#E53935',
  description text,
  created_at  timestamptz          DEFAULT now(),
  updated_at  timestamptz          DEFAULT now()
);

COMMENT ON TABLE  public.delivery_zones_polygon IS
  'Polygon-based delivery zones. Each zone defines a geographic boundary '
  'using an array of lat/lng coordinates. Customers must be inside a zone '
  'polygon to qualify for delivery.';

COMMENT ON COLUMN public.delivery_zones_polygon.polygon IS
  'Array of {lat, lng} objects defining the polygon boundary. '
  'Example: [{"lat": -33.8, "lng": 18.6}, {"lat": -33.79, "lng": 18.63}, ...]. '
  'Minimum 3 points required. The polygon is treated as closed '
  '(last point connects back to first).';

COMMENT ON COLUMN public.delivery_zones_polygon.delivery_fee IS
  'Flat delivery fee in ZAR charged for orders in this zone. Default R110.';

COMMENT ON COLUMN public.delivery_zones_polygon.minimum_order IS
  'Minimum order value in ZAR required to qualify for delivery. Default R500.';

COMMENT ON COLUMN public.delivery_zones_polygon.color IS
  'Hex colour used to render the zone on the admin map. Default #E53935 (red).';

CREATE INDEX IF NOT EXISTS idx_delivery_zones_polygon_active
  ON public.delivery_zones_polygon(is_active);

CREATE INDEX IF NOT EXISTS idx_delivery_zones_polygon_name
  ON public.delivery_zones_polygon(name);

-- ── PART 2 — Row-Level Security ───────────────────────────────────────────────

ALTER TABLE public.delivery_zones_polygon ENABLE ROW LEVEL SECURITY;

-- Authenticated staff (admin, manager, owner) can read, insert, update, delete.
CREATE POLICY "Staff manage polygon zones"
  ON public.delivery_zones_polygon
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Anonymous (loyalty app customers before auth) can read active zones only.
CREATE POLICY "Customers read active polygon zones"
  ON public.delivery_zones_polygon
  FOR SELECT
  TO anon
  USING (is_active = true);

-- ── PART 3 — updated_at trigger ───────────────────────────────────────────────
-- Reuses the update_updated_at_column() function created in migration 003.

CREATE OR REPLACE TRIGGER update_delivery_zones_polygon_updated_at
  BEFORE UPDATE ON public.delivery_zones_polygon
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ── PART 4 — Seed initial Northern Suburbs zone ───────────────────────────────
-- Polygon is intentionally empty ([]). Admin will draw the actual boundary
-- on the polygon drawing screen (Admin app → Delivery Zones Map).
-- ON CONFLICT DO NOTHING ensures this is safe to re-run.

INSERT INTO public.delivery_zones_polygon
  (name, polygon, delivery_fee, minimum_order, delivery_day,
   is_active, color, description)
VALUES (
  'Northern Suburbs',
  '[]'::jsonb,
  110.00,
  500.00,
  'Monthly delivery',
  true,
  '#E53935',
  'Durbanville, Brackenfell, Uitsig, Welgemoed, Cape Gate area'
)
ON CONFLICT DO NOTHING;

-- ── PART 5 — Existing tables NOT modified ────────────────────────────────────
-- The following tables from migration 106 are intentionally left untouched:
--   public.delivery_zones      — suburb-based zones (fallback)
--   public.delivery_streets    — street lists per suburb (fallback)
--   public.delivery_settings   — global fee/min-order settings (fallback)
--   public.delivery_windows    — booking windows (unchanged)
-- They remain operational as fallback until all polygon validation is confirmed.
