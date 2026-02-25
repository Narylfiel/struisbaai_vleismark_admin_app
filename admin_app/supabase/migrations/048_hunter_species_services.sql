-- Hunter: species table, link services to inventory, job JSONB columns, parked_sales

-- PART 2: Species table
CREATE TABLE IF NOT EXISTS hunter_species (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  typical_weight_min NUMERIC,
  typical_weight_max NUMERIC,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO hunter_species (name, typical_weight_min, typical_weight_max, sort_order) VALUES
  ('Kudu', 120, 250, 1),
  ('Springbok', 25, 45, 2),
  ('Blue Wildebeest', 180, 270, 3),
  ('Gemsbok', 180, 240, 4),
  ('Blesbok', 55, 80, 5),
  ('Warthog', 60, 100, 6),
  ('Eland', 400, 700, 7),
  ('Impala', 40, 70, 8),
  ('Bushbuck', 30, 55, 9),
  ('Zebra', 250, 350, 10),
  ('Red Hartebeest', 100, 160, 11),
  ('Waterbuck', 150, 260, 12),
  ('Bushpig', 45, 80, 13),
  ('Nyala', 55, 125, 14),
  ('Duiker', 15, 25, 15)
ON CONFLICT (name) DO NOTHING;

ALTER TABLE hunter_species ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all for anon" ON hunter_species;
CREATE POLICY "Allow all for anon" ON hunter_species
  FOR ALL TO anon USING (true) WITH CHECK (true);

-- PART 3: Link hunter_services to inventory_items
ALTER TABLE hunter_services
  ADD COLUMN IF NOT EXISTS inventory_item_id UUID REFERENCES inventory_items(id),
  ADD COLUMN IF NOT EXISTS service_category TEXT
    CHECK (service_category IS NULL OR service_category = ANY (ARRAY[
      'processing','packaging','spice','extra','casing','other'
    ]));

-- PART 4: hunter_jobs JSONB columns; allow service_id to be null when using services_list (if column exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'hunter_jobs' AND column_name = 'service_id') THEN
    ALTER TABLE hunter_jobs ALTER COLUMN service_id DROP NOT NULL;
  END IF;
END $$;
ALTER TABLE hunter_jobs
  ADD COLUMN IF NOT EXISTS species_list JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS services_list JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS materials_list JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS processing_options JSONB DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS animal_count INTEGER DEFAULT 1;

-- PART 5: Parked sales for POS integration
CREATE TABLE IF NOT EXISTS parked_sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reference TEXT NOT NULL,
  source TEXT DEFAULT 'hunter' CHECK (source = ANY (
    ARRAY['hunter','manual','layby','online']
  )),
  hunter_job_id UUID REFERENCES hunter_jobs(id),
  customer_name TEXT,
  customer_phone TEXT,
  line_items JSONB NOT NULL DEFAULT '[]',
  subtotal NUMERIC DEFAULT 0,
  notes TEXT,
  status TEXT DEFAULT 'parked' CHECK (status = ANY (
    ARRAY['parked','in_progress','completed','cancelled']
  )),
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE parked_sales ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all for anon" ON parked_sales;
CREATE POLICY "Allow all for anon" ON parked_sales
  FOR ALL TO anon USING (true) WITH CHECK (true);
