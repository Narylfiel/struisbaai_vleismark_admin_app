-- 107_bilingual_content.sql
-- Bilingual (Afrikaans) CMS columns for loyalty-facing content.
-- English columns remain canonical; *_af columns are nullable — app falls back to English when empty.
-- Run manually in Supabase SQL Editor (do not apply automatically via CI without review).

-- ── Loyalty customer recipes (Flutter: customer_recipes + nested ingredients/steps) ─────────────
ALTER TABLE public.customer_recipes
  ADD COLUMN IF NOT EXISTS title_af text,
  ADD COLUMN IF NOT EXISTS description_af text,
  ADD COLUMN IF NOT EXISTS instructions_af text,
  ADD COLUMN IF NOT EXISTS ingredients_af text;

ALTER TABLE public.customer_recipe_ingredients
  ADD COLUMN IF NOT EXISTS ingredient_text_af text;

ALTER TABLE public.customer_recipe_steps
  ADD COLUMN IF NOT EXISTS instruction_text_af text;

-- ── Deals / promotions (Flutter: promotions via loyalty_app channel) ───────────────────────────
-- Note: primary English deal title column is `name` — Afrikaans companion is `name_af`.
ALTER TABLE public.promotions
  ADD COLUMN IF NOT EXISTS name_af text,
  ADD COLUMN IF NOT EXISTS description_af text,
  ADD COLUMN IF NOT EXISTS terms_af text;

-- ── News / announcements ─────────────────────────────────────────────────────────────────────────
-- English body column is `content`. Afrikaans body may use `content_af` or `body_af` (either may be filled).
ALTER TABLE public.announcements
  ADD COLUMN IF NOT EXISTS title_af text,
  ADD COLUMN IF NOT EXISTS body_af text,
  ADD COLUMN IF NOT EXISTS summary_af text,
  ADD COLUMN IF NOT EXISTS content_af text;

-- ── Internal production recipes table (optional — not used by loyalty customer_recipes UI) ────────
-- Query 1 showed public.recipes exists with name, ingredients jsonb, instructions text.
ALTER TABLE public.recipes
  ADD COLUMN IF NOT EXISTS name_af text,
  ADD COLUMN IF NOT EXISTS instructions_af text,
  ADD COLUMN IF NOT EXISTS ingredients_af jsonb;
