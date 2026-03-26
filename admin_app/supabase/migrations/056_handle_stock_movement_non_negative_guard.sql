create or replace function public.handle_stock_movement()
returns trigger
language plpgsql
as $function$
declare
  v_fresh numeric;
  v_frozen numeric;
  v_is_frozen boolean;
  v_new_fresh numeric;
  v_new_frozen numeric;
  v_allow_negative boolean := lower(coalesce(new.metadata->>'allow_negative', 'false')) in ('true', '1', 'yes');
begin
  select
    coalesce(stock_on_hand_fresh, 0),
    coalesce(stock_on_hand_frozen, 0),
    coalesce(is_frozen_variant, false)
  into v_fresh, v_frozen, v_is_frozen
  from public.inventory_items
  where id = new.item_id;

  v_new_fresh := v_fresh;
  v_new_frozen := v_frozen;

  if new.movement_type = 'sale' then
    if v_is_frozen then
      v_new_frozen := v_frozen + new.quantity;
    else
      v_new_fresh := v_fresh + new.quantity;
    end if;
  elsif new.movement_type in ('waste', 'out', 'donation', 'sponsorship', 'staff_meal') then
    v_new_fresh := v_fresh + new.quantity;
  elsif new.movement_type in ('in', 'production') then
    v_new_fresh := v_fresh + new.quantity;
  elsif new.movement_type = 'freezer' then
    v_new_fresh := v_fresh + new.quantity;
    v_new_frozen := v_frozen + abs(new.quantity);
  elsif new.movement_type = 'adjustment' then
    if v_is_frozen then
      v_new_frozen := v_frozen + new.quantity;
    else
      v_new_fresh := v_fresh + new.quantity;
    end if;
  elsif new.movement_type = 'transfer' then
    null;
  end if;

  if not v_allow_negative then
    v_new_fresh := greatest(0, v_new_fresh);
    v_new_frozen := greatest(0, v_new_frozen);
  end if;

  update public.inventory_items
  set
    stock_on_hand_fresh = v_new_fresh,
    stock_on_hand_frozen = v_new_frozen,
    current_stock = v_new_fresh + v_new_frozen,
    updated_at = now()
  where id = new.item_id;

  new.balance_after := v_new_fresh + v_new_frozen;
  return new;
end;
$function$;
