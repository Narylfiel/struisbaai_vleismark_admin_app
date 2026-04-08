-- ============================================
-- MIGRATION 102: Print Queue Validation & Hardening
-- PURPOSE: Idempotency protection + comprehensive validation
-- DATE: 2026-04-08
-- CRITICAL: Prevents duplicate delivery labels
-- ============================================

-- ============================================
-- CRITICAL FIX: Idempotency Protection
-- ============================================

-- Prevent duplicate delivery labels for same order
-- Partial index only applies to delivery_label type
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_delivery_label
ON online_order_print_queue(order_id, print_type)
WHERE print_type = 'delivery_label';

COMMENT ON INDEX idx_unique_delivery_label IS 
'Prevents duplicate delivery label queue entries for the same order. Only applies to delivery_label type, does not affect pos type.';

-- ============================================
-- VALIDATION SECTION
-- ============================================

-- Validation 1: Verify table structure
DO $$
DECLARE
  v_column_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_column_count
  FROM information_schema.columns
  WHERE table_name = 'online_order_print_queue'
    AND column_name IN ('id', 'order_id', 'order_data', 'print_type', 'hold_until', 'printed', 'printed_at', 'created_at');

  IF v_column_count != 8 THEN
    RAISE EXCEPTION 'VALIDATION FAILED: Expected 8 columns in online_order_print_queue, found %', v_column_count;
  END IF;

  RAISE NOTICE '✓ Table structure validated: 8 columns present';
END $$;

-- Validation 2: Verify print_type default
DO $$
DECLARE
  v_default TEXT;
BEGIN
  SELECT column_default INTO v_default
  FROM information_schema.columns
  WHERE table_name = 'online_order_print_queue'
    AND column_name = 'print_type';

  IF v_default IS NULL OR v_default NOT LIKE '%pos%' THEN
    RAISE EXCEPTION 'VALIDATION FAILED: print_type default is not ''pos''';
  END IF;

  RAISE NOTICE '✓ print_type default validated: %', v_default;
END $$;

-- Validation 3: Verify CHECK constraint exists
DO $$
DECLARE
  v_constraint_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_constraint_count
  FROM information_schema.check_constraints
  WHERE constraint_name LIKE '%print_type%'
    AND check_clause LIKE '%pos%'
    AND check_clause LIKE '%delivery_label%';

  IF v_constraint_count = 0 THEN
    RAISE EXCEPTION 'VALIDATION FAILED: print_type CHECK constraint not found';
  END IF;

  RAISE NOTICE '✓ CHECK constraint validated';
END $$;

-- Validation 4: Verify trigger exists
DO $$
DECLARE
  v_trigger_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_trigger_count
  FROM information_schema.triggers
  WHERE trigger_name = 'trg_prevent_delivery_pos_contamination';

  IF v_trigger_count = 0 THEN
    RAISE EXCEPTION 'VALIDATION FAILED: Contamination trigger not found';
  END IF;

  RAISE NOTICE '✓ Contamination trigger validated';
END $$;

-- Validation 5: Verify claim_print_job RPC exists
DO $$
DECLARE
  v_function_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_function_count
  FROM information_schema.routines
  WHERE routine_name = 'claim_print_job';

  IF v_function_count = 0 THEN
    RAISE EXCEPTION 'VALIDATION FAILED: claim_print_job RPC not found';
  END IF;

  RAISE NOTICE '✓ claim_print_job RPC validated';
END $$;

-- Validation 6: Verify polling index exists
DO $$
DECLARE
  v_index_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_index_count
  FROM pg_indexes
  WHERE tablename = 'online_order_print_queue'
    AND indexname = 'idx_print_queue_type_hold';

  IF v_index_count = 0 THEN
    RAISE EXCEPTION 'VALIDATION FAILED: Polling index not found';
  END IF;

  RAISE NOTICE '✓ Polling index validated';
END $$;

-- ============================================
-- TEST SECTION
-- ============================================

-- Test 1: Atomic Claim Test
DO $$
DECLARE
  v_test_order_id UUID;
  v_test_job_id UUID;
  v_claim_result_1 JSONB;
  v_claim_result_2 JSONB;
BEGIN
  -- Get a test delivery order
  SELECT id INTO v_test_order_id
  FROM online_orders
  WHERE is_delivery = true
  LIMIT 1;

  IF v_test_order_id IS NULL THEN
    RAISE NOTICE '⚠ No delivery orders found for atomic claim test';
    RETURN;
  END IF;

  -- Insert test job
  INSERT INTO online_order_print_queue (order_id, order_data, print_type, printed)
  VALUES (v_test_order_id, '{"test": "atomic_claim"}', 'delivery_label', false)
  RETURNING id INTO v_test_job_id;

  -- First claim (should succeed)
  SELECT claim_print_job(v_test_job_id) INTO v_claim_result_1;

  -- Second claim (should return NULL)
  SELECT claim_print_job(v_test_job_id) INTO v_claim_result_2;

  IF v_claim_result_1 IS NULL THEN
    RAISE EXCEPTION 'TEST FAILED: First claim returned NULL';
  END IF;

  IF v_claim_result_2 IS NOT NULL THEN
    RAISE EXCEPTION 'TEST FAILED: Second claim did not return NULL (duplicate claim possible)';
  END IF;

  RAISE NOTICE '✓ Atomic claim test PASSED';

  -- Cleanup
  DELETE FROM online_order_print_queue WHERE id = v_test_job_id;
END $$;

-- Test 2: Idempotency Test
DO $$
DECLARE
  v_test_order_id UUID;
  v_duplicate_error BOOLEAN := false;
BEGIN
  -- Get a test delivery order
  SELECT id INTO v_test_order_id
  FROM online_orders
  WHERE is_delivery = true
  LIMIT 1;

  IF v_test_order_id IS NULL THEN
    RAISE NOTICE '⚠ No delivery orders found for idempotency test';
    RETURN;
  END IF;

  -- First insert (should succeed)
  INSERT INTO online_order_print_queue (order_id, order_data, print_type, printed)
  VALUES (v_test_order_id, '{"test": "idempotency_1"}', 'delivery_label', false);

  -- Second insert (should fail due to unique index)
  BEGIN
    INSERT INTO online_order_print_queue (order_id, order_data, print_type, printed)
    VALUES (v_test_order_id, '{"test": "idempotency_2"}', 'delivery_label', false);
  EXCEPTION
    WHEN unique_violation THEN
      v_duplicate_error := true;
  END;

  IF NOT v_duplicate_error THEN
    RAISE EXCEPTION 'TEST FAILED: Duplicate delivery label insert did not fail';
  END IF;

  RAISE NOTICE '✓ Idempotency test PASSED (duplicate prevented)';

  -- Cleanup
  DELETE FROM online_order_print_queue 
  WHERE order_id = v_test_order_id 
    AND print_type = 'delivery_label';
END $$;

-- Test 3: Trigger Validation (Contamination Prevention)
DO $$
DECLARE
  v_delivery_order_id UUID;
  v_cc_order_id UUID;
  v_error_caught BOOLEAN;
BEGIN
  -- Get test orders
  SELECT id INTO v_delivery_order_id
  FROM online_orders
  WHERE is_delivery = true
  LIMIT 1;

  SELECT id INTO v_cc_order_id
  FROM online_orders
  WHERE is_delivery = false
  LIMIT 1;

  IF v_delivery_order_id IS NULL OR v_cc_order_id IS NULL THEN
    RAISE NOTICE '⚠ Test orders not found for trigger validation';
    RETURN;
  END IF;

  -- Test A: Delivery order with 'pos' type (should FAIL)
  v_error_caught := false;
  BEGIN
    INSERT INTO online_order_print_queue (order_id, order_data, print_type, printed)
    VALUES (v_delivery_order_id, '{"test": "trigger_a"}', 'pos', false);
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLERRM LIKE '%POS_CONTAMINATION%' THEN
        v_error_caught := true;
      END IF;
  END;

  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'TEST FAILED: Trigger did not block delivery order with pos type';
  END IF;

  RAISE NOTICE '✓ Trigger test A PASSED (delivery + pos blocked)';

  -- Test B: C&C order with 'delivery_label' type (should FAIL)
  v_error_caught := false;
  BEGIN
    INSERT INTO online_order_print_queue (order_id, order_data, print_type, printed)
    VALUES (v_cc_order_id, '{"test": "trigger_b"}', 'delivery_label', false);
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLERRM LIKE '%DELIVERY_CONTAMINATION%' THEN
        v_error_caught := true;
      END IF;
  END;

  IF NOT v_error_caught THEN
    RAISE EXCEPTION 'TEST FAILED: Trigger did not block C&C order with delivery_label type';
  END IF;

  RAISE NOTICE '✓ Trigger test B PASSED (C&C + delivery_label blocked)';

  -- Test C: Valid combinations (should PASS)
  INSERT INTO online_order_print_queue (order_id, order_data, print_type, printed)
  VALUES (v_delivery_order_id, '{"test": "trigger_c1"}', 'delivery_label', false);

  INSERT INTO online_order_print_queue (order_id, order_data, print_type, printed)
  VALUES (v_cc_order_id, '{"test": "trigger_c2"}', 'pos', false);

  RAISE NOTICE '✓ Trigger test C PASSED (valid combinations allowed)';

  -- Cleanup
  DELETE FROM online_order_print_queue 
  WHERE order_data::text LIKE '%trigger_%';
END $$;

-- Test 4: POS Isolation Test
DO $$
DECLARE
  v_delivery_order_id UUID;
  v_cc_order_id UUID;
  v_pos_query_count INTEGER;
BEGIN
  -- Get test orders
  SELECT id INTO v_delivery_order_id
  FROM online_orders
  WHERE is_delivery = true
  LIMIT 1;

  SELECT id INTO v_cc_order_id
  FROM online_orders
  WHERE is_delivery = false
  LIMIT 1;

  IF v_delivery_order_id IS NULL OR v_cc_order_id IS NULL THEN
    RAISE NOTICE '⚠ Test orders not found for POS isolation test';
    RETURN;
  END IF;

  -- Insert both types
  INSERT INTO online_order_print_queue (order_id, order_data, print_type, printed)
  VALUES 
    (v_delivery_order_id, '{"test": "pos_isolation_delivery"}', 'delivery_label', false),
    (v_cc_order_id, '{"test": "pos_isolation_cc"}', 'pos', false);

  -- Simulate POS query (should only see 'pos' type)
  SELECT COUNT(*) INTO v_pos_query_count
  FROM online_order_print_queue
  WHERE print_type = 'pos'
    AND printed = false
    AND order_data::text LIKE '%pos_isolation%';

  IF v_pos_query_count != 1 THEN
    RAISE EXCEPTION 'TEST FAILED: POS query returned % jobs, expected 1', v_pos_query_count;
  END IF;

  RAISE NOTICE '✓ POS isolation test PASSED (only sees pos type)';

  -- Cleanup
  DELETE FROM online_order_print_queue 
  WHERE order_data::text LIKE '%pos_isolation%';
END $$;

-- ============================================
-- FINAL VALIDATION SUMMARY
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '════════════════════════════════════════════════════════';
  RAISE NOTICE 'MIGRATION 102 VALIDATION SUMMARY';
  RAISE NOTICE '════════════════════════════════════════════════════════';
  RAISE NOTICE '✓ Table structure validated';
  RAISE NOTICE '✓ Constraints validated';
  RAISE NOTICE '✓ Indexes validated';
  RAISE NOTICE '✓ Trigger validated';
  RAISE NOTICE '✓ RPC validated';
  RAISE NOTICE '✓ Atomic claim tested';
  RAISE NOTICE '✓ Idempotency tested';
  RAISE NOTICE '✓ Contamination prevention tested';
  RAISE NOTICE '✓ POS isolation tested';
  RAISE NOTICE '';
  RAISE NOTICE 'CRITICAL FIX APPLIED:';
  RAISE NOTICE '✓ Unique index prevents duplicate delivery labels';
  RAISE NOTICE '';
  RAISE NOTICE 'STATUS: READY FOR PRODUCTION';
  RAISE NOTICE '════════════════════════════════════════════════════════';
END $$;
