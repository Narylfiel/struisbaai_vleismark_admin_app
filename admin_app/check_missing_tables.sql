-- Check which tables are missing
SELECT 'transaction_items' as table_name, 
       EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'transaction_items') as exists
UNION ALL
SELECT 'inventory_items', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'inventory_items')
UNION ALL  
SELECT 'profiles', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles')
UNION ALL
SELECT 'business_accounts', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'business_accounts')
UNION ALL
SELECT 'leave_requests', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'leave_requests')
UNION ALL
SELECT 'payroll_entries', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'payroll_entries')
UNION ALL
SELECT 'shrinkage_alerts', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'shrinkage_alerts')
UNION ALL
SELECT 'reorder_recommendations', EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'reorder_recommendations');
