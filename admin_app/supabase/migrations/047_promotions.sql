-- Promotions engine: tables (promotions, promotion_products) were created manually.
-- This migration documents that and adds RLS for admin app (authenticated role).

-- Enable RLS on promotions (idempotent: no-op if already enabled)
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotion_products ENABLE ROW LEVEL SECURITY;

-- Policies for authenticated users (admin app). Drop first if re-running.
DROP POLICY IF EXISTS promotions_select ON promotions;
DROP POLICY IF EXISTS promotions_insert ON promotions;
DROP POLICY IF EXISTS promotions_update ON promotions;
DROP POLICY IF EXISTS promotions_delete ON promotions;
CREATE POLICY promotions_select ON promotions FOR SELECT TO authenticated USING (true);
CREATE POLICY promotions_insert ON promotions FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY promotions_update ON promotions FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY promotions_delete ON promotions FOR DELETE TO authenticated USING (true);

DROP POLICY IF EXISTS promotion_products_select ON promotion_products;
DROP POLICY IF EXISTS promotion_products_insert ON promotion_products;
DROP POLICY IF EXISTS promotion_products_update ON promotion_products;
DROP POLICY IF EXISTS promotion_products_delete ON promotion_products;
CREATE POLICY promotion_products_select ON promotion_products FOR SELECT TO authenticated USING (true);
CREATE POLICY promotion_products_insert ON promotion_products FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY promotion_products_update ON promotion_products FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY promotion_products_delete ON promotion_products FOR DELETE TO authenticated USING (true);
