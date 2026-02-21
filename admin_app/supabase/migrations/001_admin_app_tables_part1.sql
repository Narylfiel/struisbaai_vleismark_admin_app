-- Admin App Database Migrations
-- Missing tables from blueprint audit
-- Run these migrations in Supabase SQL editor

-- 1. Staff Documents
CREATE TABLE IF NOT EXISTS staff_documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL CHECK (document_type IN ('id', 'contract', 'qualification', 'medical', 'other')),
  file_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  uploaded_by UUID REFERENCES profiles(id),
  is_active BOOLEAN DEFAULT true
);

-- 2. Business Settings
CREATE TABLE IF NOT EXISTS business_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  setting_key TEXT UNIQUE NOT NULL,
  setting_value JSONB,
  description TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id)
);

-- 3. Stock Locations
CREATE TABLE IF NOT EXISTS stock_locations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Modifier Groups
CREATE TABLE IF NOT EXISTS modifier_groups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Modifier Items
CREATE TABLE IF NOT EXISTS modifier_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID NOT NULL REFERENCES modifier_groups(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  price_adjustment DECIMAL(10,2) DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Yield Templates
CREATE TABLE IF NOT EXISTS yield_templates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  carcass_type TEXT NOT NULL CHECK (carcass_type IN ('beef', 'lamb', 'pork', 'chicken')),
  estimated_weight_kg DECIMAL(8,2),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id)
);

-- 7. Yield Template Cuts
CREATE TABLE IF NOT EXISTS yield_template_cuts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  template_id UUID NOT NULL REFERENCES yield_templates(id) ON DELETE CASCADE,
  cut_name TEXT NOT NULL,
  expected_percentage DECIMAL(5,2) NOT NULL CHECK (expected_percentage > 0 AND expected_percentage <= 100),
  expected_weight_kg DECIMAL(8,2),
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Carcass Intakes
CREATE TABLE IF NOT EXISTS carcass_intakes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  intake_date DATE NOT NULL DEFAULT CURRENT_DATE,
  supplier_name TEXT NOT NULL,
  carcass_count INTEGER NOT NULL CHECK (carcass_count > 0),
  total_weight_kg DECIMAL(10,2) NOT NULL,
  average_weight_kg DECIMAL(8,2) GENERATED ALWAYS AS (total_weight_kg / carcass_count) STORED,
  quality_grade TEXT CHECK (quality_grade IN ('A', 'B', 'C', 'D')),
  received_by UUID NOT NULL REFERENCES profiles(id),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Carcass Breakdown Sessions
CREATE TABLE IF NOT EXISTS carcass_breakdown_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  intake_id UUID NOT NULL REFERENCES carcass_intakes(id) ON DELETE CASCADE,
  carcass_number INTEGER NOT NULL CHECK (carcass_number > 0),
  actual_weight_kg DECIMAL(8,2) NOT NULL,
  template_id UUID REFERENCES yield_templates(id),
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  processed_by UUID NOT NULL REFERENCES profiles(id),
  status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'cancelled')),
  notes TEXT
);

-- 10. Stock Movements
CREATE TABLE IF NOT EXISTS stock_movements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  item_id UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
  movement_type TEXT NOT NULL CHECK (movement_type IN ('in', 'out', 'adjustment', 'transfer', 'waste', 'production')),
  quantity DECIMAL(10,3) NOT NULL,
  unit_cost DECIMAL(10,2),
  total_cost DECIMAL(10,2),
  reference_type TEXT CHECK (reference_type IN ('purchase', 'sale', 'production', 'adjustment', 'waste')),
  reference_id UUID,
  location_from UUID REFERENCES stock_locations(id),
  location_to UUID REFERENCES stock_locations(id),
  performed_by UUID NOT NULL REFERENCES profiles(id),
  performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  notes TEXT
);

-- 11. Recipes
CREATE TABLE IF NOT EXISTS recipes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  category TEXT,
  servings INTEGER DEFAULT 1,
  prep_time_minutes INTEGER,
  cook_time_minutes INTEGER,
  total_time_minutes INTEGER GENERATED ALWAYS AS (COALESCE(prep_time_minutes, 0) + COALESCE(cook_time_minutes, 0)) STORED,
  difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. Recipe Ingredients
CREATE TABLE IF NOT EXISTS recipe_ingredients (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  inventory_item_id UUID REFERENCES inventory_items(id),
  ingredient_name TEXT NOT NULL, -- For non-inventory items
  quantity DECIMAL(10,3) NOT NULL,
  unit TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  is_optional BOOLEAN DEFAULT false,
  notes TEXT
);

-- 13. Production Batches
CREATE TABLE IF NOT EXISTS production_batches (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  batch_number TEXT UNIQUE NOT NULL,
  recipe_id UUID NOT NULL REFERENCES recipes(id),
  planned_quantity INTEGER NOT NULL,
  actual_quantity INTEGER,
  status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  started_by UUID REFERENCES profiles(id),
  completed_by UUID REFERENCES profiles(id),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 14. Production Batch Ingredients
CREATE TABLE IF NOT EXISTS production_batch_ingredients (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  batch_id UUID NOT NULL REFERENCES production_batches(id) ON DELETE CASCADE,
  ingredient_id UUID NOT NULL REFERENCES recipe_ingredients(id),
  planned_quantity DECIMAL(10,3) NOT NULL,
  actual_quantity DECIMAL(10,3),
  used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 15. Dryer Batches
CREATE TABLE IF NOT EXISTS dryer_batches (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  batch_number TEXT UNIQUE NOT NULL,
  product_name TEXT NOT NULL,
  input_weight_kg DECIMAL(8,2) NOT NULL,
  output_weight_kg DECIMAL(8,2),
  shrinkage_percentage DECIMAL(5,2) GENERATED ALWAYS AS (
    CASE WHEN input_weight_kg > 0 THEN ((input_weight_kg - COALESCE(output_weight_kg, 0)) / input_weight_kg) * 100 ELSE 0 END
  ) STORED,
  dryer_type TEXT NOT NULL CHECK (dryer_type IN ('biltong', 'droewors', 'jerky')),
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  status TEXT NOT NULL DEFAULT 'drying' CHECK (status IN ('drying', 'completed', 'cancelled')),
  processed_by UUID REFERENCES profiles(id),
  notes TEXT
);

-- 16. Dryer Batch Ingredients
CREATE TABLE IF NOT EXISTS dryer_batch_ingredients (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  batch_id UUID NOT NULL REFERENCES dryer_batches(id) ON DELETE CASCADE,
  inventory_item_id UUID NOT NULL REFERENCES inventory_items(id),
  quantity_used DECIMAL(10,3) NOT NULL,
  added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 17. Hunter Services
CREATE TABLE IF NOT EXISTS hunter_services (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  base_price DECIMAL(10,2) NOT NULL,
  price_per_kg DECIMAL(10,2),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 18. Hunter Jobs
CREATE TABLE IF NOT EXISTS hunter_jobs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  job_number TEXT UNIQUE NOT NULL,
  client_name TEXT NOT NULL,
  client_contact TEXT,
  service_id UUID NOT NULL REFERENCES hunter_services(id),
  status TEXT NOT NULL DEFAULT 'quoted' CHECK (status IN ('quoted', 'confirmed', 'in_progress', 'completed', 'cancelled')),
  quoted_price DECIMAL(10,2),
  final_price DECIMAL(10,2),
  estimated_weight_kg DECIMAL(8,2),
  actual_weight_kg DECIMAL(8,2),
  special_instructions TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id),
  assigned_to UUID REFERENCES profiles(id),
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  notes TEXT
);

-- 19. Hunter Job Processes
CREATE TABLE IF NOT EXISTS hunter_job_processes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  job_id UUID NOT NULL REFERENCES hunter_jobs(id) ON DELETE CASCADE,
  process_type TEXT NOT NULL CHECK (process_type IN ('skinning', 'quartering', 'aging', 'packaging', 'freezing')),
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  processed_by UUID NOT NULL REFERENCES profiles(id),
  weight_before_kg DECIMAL(8,2),
  weight_after_kg DECIMAL(8,2),
  notes TEXT
);

-- 20. Hunter Process Materials
CREATE TABLE IF NOT EXISTS hunter_process_materials (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  process_id UUID NOT NULL REFERENCES hunter_job_processes(id) ON DELETE CASCADE,
  material_type TEXT NOT NULL CHECK (material_type IN ('packaging', 'labels', 'supplies')),
  item_name TEXT NOT NULL,
  quantity_used DECIMAL(10,3) NOT NULL,
  unit TEXT NOT NULL,
  cost DECIMAL(10,2),
  used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);