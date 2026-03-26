CREATE OR REPLACE FUNCTION public.calculate_nightly_mass_balance()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_item RECORD;
  v_sales numeric;
  v_waste numeric;
  v_production numeric;
  v_received numeric;
  v_theoretical numeric;
  v_actual numeric;
  v_gap numeric;
  v_gap_pct numeric;
  v_allowance numeric;
BEGIN
  -- Loop through all stock-controlled products
  FOR v_item IN
    SELECT id, name, stock_on_hand_fresh, stock_on_hand_frozen,
           current_stock, shrinkage_allowance_pct
    FROM public.inventory_items
    WHERE stock_control_type = 'use_stock_control'
    AND is_active = true
  LOOP
    -- Sum movements over last 30 days
    SELECT COALESCE(SUM(ABS(quantity)), 0) INTO v_sales
    FROM public.stock_movements
    WHERE item_id = v_item.id
    AND movement_type = 'sale'
    AND created_at >= NOW() - INTERVAL '30 days';

    SELECT COALESCE(SUM(ABS(quantity)), 0) INTO v_waste
    FROM public.stock_movements
    WHERE item_id = v_item.id
    AND movement_type IN ('waste', 'donation', 'sponsorship', 'staff_meal')
    AND created_at >= NOW() - INTERVAL '30 days';

    SELECT COALESCE(SUM(quantity), 0) INTO v_production
    FROM public.stock_movements
    WHERE item_id = v_item.id
    AND movement_type IN ('production', 'in')
    AND created_at >= NOW() - INTERVAL '30 days';

    -- Theoretical = current + sales + waste - production/received
    -- (what should be on hand based on movements)
    v_actual := COALESCE(v_item.current_stock, 0);
    v_theoretical := v_actual + v_sales + v_waste - v_production;
    v_gap := v_theoretical - v_actual;
    v_allowance := COALESCE(v_item.shrinkage_allowance_pct, 2.0);

    -- Only alert if gap > 0 and exceeds allowance %
    IF v_theoretical > 0 THEN
      v_gap_pct := (v_gap / v_theoretical) * 100;
    ELSE
      v_gap_pct := 0;
    END IF;

    IF v_gap > 0 AND v_gap_pct > v_allowance THEN
      -- Check if unresolved alert already exists for this product
      IF NOT EXISTS (
        SELECT 1 FROM public.shrinkage_alerts
        WHERE product_id = v_item.id
        AND resolved = false
        AND created_at >= NOW() - INTERVAL '7 days'
      ) THEN
        INSERT INTO public.shrinkage_alerts (
          item_id,
          product_id,
          item_name,
          alert_date,
          theoretical_stock,
          actual_stock,
          gap_amount,
          gap_percentage,
          shrinkage_percentage,
          status,
          possible_reasons,
          resolved
        ) VALUES (
          v_item.id,
          v_item.id,
          v_item.name,
          CURRENT_DATE,
          v_theoretical,
          v_actual,
          v_gap,
          v_gap_pct,
          v_gap_pct,
          'Pending',
          CASE
            WHEN v_gap_pct > 20 THEN 'Possible theft, unlogged waste, or label error'
            WHEN v_gap_pct > 10 THEN 'Possible unlogged waste or portioning variance'
            ELSE 'Minor variance — moisture loss or scale variance'
          END,
          false
        );
      END IF;
    END IF;
  END LOOP;
END;
$function$;
