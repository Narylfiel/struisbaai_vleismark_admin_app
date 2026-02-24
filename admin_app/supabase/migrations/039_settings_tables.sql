-- Migration 039: Create settings tables required by SettingsRepository
-- Safe: CREATE TABLE IF NOT EXISTS only. No changes to existing migrations or data.
--
-- SettingsRepository usage (lib/features/settings/services/settings_repository.dart):
--   scale_config: getScaleConfig() select().limit(1).maybeSingle(); updateScaleConfig() insert(data) or update(data).eq('id', existing['id'])
--   tax_rules: getTaxRules() select().order('name'); createTaxRule(name, percentage) insert; deleteTaxRule(id) delete.eq('id', id)
--   system_config: getSystemConfig() select().order('key'); toggleNotification(id, val) update({'is_active': val}).eq('id', id)
--
-- Note: Scale, Tax, and Notification screens currently use business_settings (key-value) directly.
-- These tables ensure the repository API does not fail when called and support future use.

-- ═══════════════════════════════════════════════════════════════════
-- 1. scale_config
-- Single-row or first-row config for scale/hardware. Repository: getScaleConfig(), updateScaleConfig(data).
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS scale_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primary_mode TEXT DEFAULT 'Price-embedded',
  plu_digits INTEGER DEFAULT 4,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE scale_config IS 'Scale/hardware config; used by SettingsRepository getScaleConfig/updateScaleConfig.';

CREATE INDEX IF NOT EXISTS idx_scale_config_updated_at ON scale_config(updated_at DESC);

-- ═══════════════════════════════════════════════════════════════════
-- 2. tax_rules
-- Named tax rates (e.g. VAT 15%). Repository: getTaxRules(), createTaxRule(name, percentage), deleteTaxRule(id).
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS tax_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  percentage NUMERIC(5,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE tax_rules IS 'Tax rules (e.g. VAT); used by SettingsRepository getTaxRules, createTaxRule, deleteTaxRule.';

CREATE INDEX IF NOT EXISTS idx_tax_rules_name ON tax_rules(name);

-- ═══════════════════════════════════════════════════════════════════
-- 3. system_config
-- Key-value style system/notification toggles. Repository: getSystemConfig() order by key, toggleNotification(id, is_active).
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS system_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  description TEXT,
  value JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE system_config IS 'System/notification config keys; used by SettingsRepository getSystemConfig, toggleNotification.';

CREATE INDEX IF NOT EXISTS idx_system_config_key ON system_config(key);
CREATE INDEX IF NOT EXISTS idx_system_config_is_active ON system_config(is_active);

-- ═══════════════════════════════════════════════════════════════════
-- VERIFICATION CHECKLIST (after running this migration)
-- ═══════════════════════════════════════════════════════════════════
-- [ ] 1. scale_config: \d scale_config shows id, primary_mode, plu_digits, created_at, updated_at
-- [ ] 2. tax_rules: \d tax_rules shows id, name, percentage, is_active, created_at, updated_at
-- [ ] 3. system_config: \d system_config shows id, key, description, value, is_active, created_at, updated_at
-- [ ] 4. SettingsRepository.getScaleConfig() returns {} or one row; no exception
-- [ ] 5. SettingsRepository.getTaxRules() returns []; no exception
-- [ ] 6. SettingsRepository.getSystemConfig() returns []; no exception
-- [ ] 7. Scale settings screen (Business Settings → Scale / HW): loads and saves via business_settings — unchanged
-- [ ] 8. Tax settings screen (Business Settings → Tax Rates): loads and saves via business_settings — unchanged
-- [ ] 9. Notification settings screen (Business Settings → Notifications): loads and saves via business_settings — unchanged
