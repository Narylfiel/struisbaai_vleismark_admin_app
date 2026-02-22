-- Blueprint alignment: transactions and transaction_items (Admin reads; POS writes)
-- §15 Tables Admin READS: transactions, transaction_items
-- Relationship: transaction_items.transaction_id → transactions(id)

-- 1. Transactions (POS writes; Admin uses for Today's Sales, Transaction Count, Avg Basket, Margin)
CREATE TABLE IF NOT EXISTS transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  cost_amount DECIMAL(12,2),
  payment_method TEXT,
  till_session_id UUID,
  staff_id UUID REFERENCES profiles(id),
  account_id UUID REFERENCES business_accounts(id),
  notes TEXT
);

-- 2. Transaction items (POS writes; Admin uses for product performance, margins)
CREATE TABLE IF NOT EXISTS transaction_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  inventory_item_id UUID REFERENCES inventory_items(id),
  quantity DECIMAL(12,3) NOT NULL DEFAULT 0,
  unit_price DECIMAL(12,2) NOT NULL DEFAULT 0,
  line_total DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for dashboard and report queries
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_transactions_total_amount ON transactions(total_amount);
CREATE INDEX IF NOT EXISTS idx_transaction_items_transaction_id ON transaction_items(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_items_inventory_item_id ON transaction_items(inventory_item_id);

-- RPC: get_dashboard_metrics using canonical tables (transactions, transaction_items)
CREATE OR REPLACE FUNCTION get_dashboard_metrics(start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days', end_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
  total_sales DECIMAL(10,2),
  transaction_count BIGINT,
  avg_transaction DECIMAL(10,2),
  top_products JSON
) AS $dashboard$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(SUM(t.total_amount), 0)::DECIMAL(10,2) as total_sales,
    COUNT(t.id)::BIGINT as transaction_count,
    COALESCE(AVG(t.total_amount), 0)::DECIMAL(10,2) as avg_transaction,
    COALESCE(
      (SELECT json_agg(agg) FROM (
        SELECT json_build_object('name', ii.name, 'quantity', SUM(ti.quantity)::DECIMAL) as agg
        FROM transaction_items ti
        LEFT JOIN inventory_items ii ON ti.inventory_item_id = ii.id
        WHERE ti.transaction_id IN (SELECT id FROM transactions WHERE created_at >= start_date AND created_at <= end_date + INTERVAL '1 day')
        GROUP BY ii.name
        LIMIT 20
      ) sub),
      '[]'::JSON
    ) as top_products
  FROM transactions t
  WHERE t.created_at >= start_date AND t.created_at <= end_date + INTERVAL '1 day';
END;
$dashboard$ LANGUAGE plpgsql;
