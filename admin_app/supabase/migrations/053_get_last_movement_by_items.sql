-- Migration 053: RPC for stock levels — last movement date per item (one row per item, aggregated).
-- Used by Stock Levels screen to avoid loading thousands of stock_movements rows.
-- stock_movements has item_id and created_at (default now()).

CREATE OR REPLACE FUNCTION get_last_movement_by_items(input_ids uuid[])
RETURNS TABLE(item_id uuid, last_movement_at timestamptz)
LANGUAGE sql
STABLE
AS $$
  SELECT sm.item_id, MAX(sm.created_at) AS last_movement_at
  FROM stock_movements sm
  WHERE sm.item_id = ANY(input_ids)
  GROUP BY sm.item_id;
$$;

COMMENT ON FUNCTION get_last_movement_by_items(uuid[]) IS 'Returns one row per item_id with the most recent created_at from stock_movements. Used by Stock Levels screen.';
