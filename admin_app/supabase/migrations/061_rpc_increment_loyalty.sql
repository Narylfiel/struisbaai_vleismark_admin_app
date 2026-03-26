CREATE OR REPLACE FUNCTION public.increment_loyalty(customer_id uuid, points_to_add integer, spend_to_add numeric)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  new_balance INTEGER;
  current_tier TEXT;
  new_tier TEXT;
  customer_name TEXT;
BEGIN
  -- Update customer stats
  UPDATE loyalty_customers
  SET 
    points_balance     = COALESCE(points_balance, 0) + points_to_add,
    total_spend        = COALESCE(total_spend, 0) + spend_to_add,
    visit_count        = COALESCE(visit_count, 0) + 1,
    last_purchase_date = CURRENT_DATE,
    updated_at         = NOW()
  WHERE id = customer_id
  RETURNING points_balance, loyalty_tier, full_name
  INTO new_balance, current_tier, customer_name;

  -- Determine correct tier based on new balance
  SELECT tier_key INTO new_tier
  FROM loyalty_tier_config
  WHERE points_required <= new_balance
    AND is_active = true
  ORDER BY points_required DESC
  LIMIT 1;

  -- Upgrade tier if changed
  IF new_tier IS NOT NULL AND new_tier != current_tier THEN
    UPDATE loyalty_customers
    SET loyalty_tier = new_tier,
        updated_at = NOW()
    WHERE id = customer_id;

    -- Send tier upgrade notification
    INSERT INTO loyalty_notifications (
      customer_id,
      notification_type,
      title,
      body,
      scheduled_for,
      metadata
    ) VALUES (
      customer_id,
      'tier_upgrade',
      '🎉 You reached ' || INITCAP(new_tier) || '!',
      'Congratulations ' || customer_name || 
        '! You have been upgraded to ' || 
        INITCAP(new_tier) || ' status.',
      CURRENT_DATE,
      jsonb_build_object(
        'old_tier', current_tier,
        'new_tier', new_tier,
        'points_balance', new_balance
      )
    );
  END IF;

  -- Write points log
  INSERT INTO loyalty_points_log (
    customer_id,
    points_delta,
    amount,
    action_type
  ) VALUES (
    customer_id,
    points_to_add,
    spend_to_add,
    'purchase'
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.increment_loyalty(customer_id uuid, points_to_add integer, spend_to_add numeric, transaction_id uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  new_balance   INTEGER;
  current_tier  TEXT;
  new_tier      TEXT;
  customer_name TEXT;
BEGIN
  -- Update customer stats
  UPDATE loyalty_customers
  SET
    points_balance     = COALESCE(points_balance, 0) + points_to_add,
    total_spend        = COALESCE(total_spend, 0) + spend_to_add,
    visit_count        = COALESCE(visit_count, 0) + 1,
    last_purchase_date = CURRENT_DATE,
    updated_at         = NOW()
  WHERE id = customer_id
  RETURNING points_balance, loyalty_tier, full_name
  INTO new_balance, current_tier, customer_name;

  -- Determine correct tier based on new balance
  SELECT tier_key INTO new_tier
  FROM loyalty_tier_config
  WHERE points_required <= new_balance
    AND is_active = true
  ORDER BY points_required DESC
  LIMIT 1;

  -- Upgrade tier if changed
  IF new_tier IS NOT NULL AND new_tier != current_tier THEN
    UPDATE loyalty_customers
    SET loyalty_tier = new_tier,
        updated_at   = NOW()
    WHERE id = customer_id;

    -- Send tier upgrade notification
    INSERT INTO loyalty_notifications (
      customer_id,
      notification_type,
      title,
      body,
      scheduled_for,
      metadata
    ) VALUES (
      customer_id,
      'tier_upgrade',
      '🎉 You reached ' || INITCAP(new_tier) || '!',
      'Congratulations ' || customer_name ||
        '! You have been upgraded to ' ||
        INITCAP(new_tier) || ' status.',
      CURRENT_DATE,
      jsonb_build_object(
        'old_tier',      current_tier,
        'new_tier',      new_tier,
        'points_balance', new_balance
      )
    );
  END IF;

  -- Write points log — now includes transaction_id
  INSERT INTO loyalty_points_log (
    customer_id,
    transaction_id,    -- ← now populated
    points_delta,
    amount,
    action_type
  ) VALUES (
    customer_id,
    transaction_id,    -- ← passes through from param
    points_to_add,
    spend_to_add,
    'purchase'
  );
END;
$function$;
