-- M7: Equipment Register — service_log and status for Equipment Register screen.
ALTER TABLE equipment_register ADD COLUMN IF NOT EXISTS service_log JSONB DEFAULT '[]'::jsonb;
ALTER TABLE equipment_register ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active' CHECK (status IN ('active', 'under_repair', 'written_off'));
ALTER TABLE equipment_register ADD COLUMN IF NOT EXISTS depreciation_rate DECIMAL(5,2);

-- Allow diminishing as alias for declining_balance in app (DB keeps declining_balance)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'equipment_register' AND column_name = 'depreciation_method') THEN
    ALTER TABLE equipment_register DROP CONSTRAINT IF EXISTS equipment_register_depreciation_method_check;
    ALTER TABLE equipment_register ADD CONSTRAINT equipment_register_depreciation_method_check
      CHECK (depreciation_method IN ('straight_line', 'declining_balance', 'diminishing'));
  END IF;
END $$;
