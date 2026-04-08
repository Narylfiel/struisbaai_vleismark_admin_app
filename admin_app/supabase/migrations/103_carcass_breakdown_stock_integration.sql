-- Carcass Breakdown Stock Integration
-- This migration adds RPC function for atomic carcass breakdown with stock movements

-- Create RPC function for atomic carcass breakdown
CREATE OR REPLACE FUNCTION perform_carcass_breakdown(
    p_carcass_intake_id UUID,
    p_status TEXT,
    p_remaining_weight NUMERIC,
    p_cuts JSONB,
    p_staff_id UUID DEFAULT NULL
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    cuts_created INTEGER,
    stock_movements_created INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_carcass carcass_intakes%ROWTYPE;
    v_total_cut_weight NUMERIC := 0;
    v_cuts_processed INTEGER := 0;
    v_stock_movements_created INTEGER := 0;
    v_carcass_item_id UUID;
    v_existing_movements INTEGER;
BEGIN
    -- Get carcass intake details
    SELECT * INTO v_carcass 
    FROM carcass_intakes 
    WHERE id = p_carcass_intake_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Carcass intake not found', 0, 0;
        RETURN;
    END IF;
    
    -- Idempotency guard: check if breakdown already exists
    SELECT COUNT(*) INTO v_existing_movements
    FROM stock_movements 
    WHERE reference_id = p_carcass_intake_id 
    AND reference_type = 'carcass_breakdown';
    
    IF v_existing_movements > 0 THEN
        RETURN QUERY SELECT FALSE, 'Breakdown already completed for this carcass', 0, 0;
        RETURN;
    END IF;
    
    -- Calculate total cut weight for validation
    SELECT COALESCE(SUM((cut->>'actual_kg')::NUMERIC), 0) INTO v_total_cut_weight
    FROM jsonb_array_elements(p_cuts) AS cut;
    
    -- Weight balance validation (warning only, don't block)
    IF v_total_cut_weight > v_carcass.weight_in THEN
        RAISE LOG 'WARNING: Cut weight (%) exceeds intake weight (%)', 
                  v_total_cut_weight, v_carcass.weight_in;
    END IF;
    
    -- Update carcass intake status
    UPDATE carcass_intakes 
    SET 
        status = p_status,
        remaining_weight = p_remaining_weight,
        updated_at = NOW()
    WHERE id = p_carcass_intake_id;
    
    -- Insert carcass cuts and create stock movements
    FOR cut_record IN SELECT * FROM jsonb_array_elements(p_cuts) AS cut LOOP
        DECLARE
            v_cut_inventory_id UUID := (cut_record->>'inventory_item_id')::UUID;
            v_actual_kg NUMERIC := (cut_record->>'actual_kg')::NUMERIC;
            v_cut_name TEXT := cut_record->>'cut_name';
        BEGIN
            -- Insert carcass cut record
            INSERT INTO carcass_cuts (
                intake_id,
                cut_name,
                expected_kg,
                actual_kg,
                plu_code,
                sellable,
                inventory_item_id,
                breakdown_date
            ) VALUES (
                p_carcass_intake_id,
                cut_record->>'cut_name',
                (cut_record->>'expected_kg')::NUMERIC,
                v_actual_kg,
                (cut_record->>'plu_code')::INTEGER,
                (cut_record->>'sellable')::BOOLEAN,
                v_cut_inventory_id,
                NOW()
            );
            
            v_cuts_processed := v_cuts_processed + 1;
            
            -- Create stock movement for cut (if inventory item exists and weight > 0)
            IF v_cut_inventory_id IS NOT NULL AND v_actual_kg > 0 THEN
                INSERT INTO stock_movements (
                    item_id,
                    movement_type,
                    quantity,
                    unit_type,
                    reference_id,
                    reference_type,
                    reason,
                    staff_id
                ) VALUES (
                    v_cut_inventory_id,
                    'carcass_cut_in',
                    v_actual_kg,
                    'kg',
                    p_carcass_intake_id,
                    'carcass_breakdown',
                    format('Carcass breakdown: %s from intake #%s', 
                           v_cut_name, v_carcass.reference_number),
                    p_staff_id
                );
                
                v_stock_movements_created := v_stock_movements_created + 1;
            END IF;
        END;
    END LOOP;
    
    -- Get carcass inventory item for consumption
    v_carcass_item_id := CASE v_carcass.carcass_type
        WHEN 'Whole Lamb (Premium)' THEN '833f35f7-8fea-4696-9f73-f5bbb44e9e98'::UUID
        WHEN 'Whole Lamb (AB Grade)' THEN '833f35f7-8fea-4696-9f73-f5bbb44e9e98'::UUID
        ELSE NULL
    END;
    
    -- Consume carcass stock (if inventory item exists)
    IF v_carcass_item_id IS NOT NULL THEN
        INSERT INTO stock_movements (
            item_id,
            movement_type,
            quantity,
            unit_type,
            reference_id,
            reference_type,
            reason,
            staff_id
        ) VALUES (
            v_carcass_item_id,
            'carcass_out',
            -v_total_cut_weight,
            'kg',
            p_carcass_intake_id,
            'carcass_breakdown',
            format('Carcass breakdown consumption: %s', v_carcass.carcass_type),
            p_staff_id
        );
        
        v_stock_movements_created := v_stock_movements_created + 1;
    ELSE
        RAISE LOG 'WARNING: No inventory item found for carcass type: %', v_carcass.carcass_type;
    END IF;
    
    -- Return success result
    RETURN QUERY SELECT TRUE, 
                        format('Breakdown completed: %s cuts, %s stock movements', 
                               v_cuts_processed, v_stock_movements_created),
                        v_cuts_processed,
                        v_stock_movements_created;
    RETURN;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log error and return failure
        RAISE LOG 'ERROR in perform_carcass_breakdown: %', SQLERRM;
        RETURN QUERY SELECT FALSE, SQLERRM, 0, 0;
        RETURN;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION perform_carcass_breakdown TO authenticated;

-- Create RPC function for carcass intake stock creation
CREATE OR REPLACE FUNCTION create_carcass_intake_stock(
    p_carcass_intake_id UUID,
    p_carcass_type TEXT,
    p_weight NUMERIC,
    p_staff_id UUID DEFAULT NULL
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    stock_movement_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_inventory_item_id UUID;
    v_stock_movement_id UUID;
BEGIN
    -- Map carcass types to inventory items
    v_inventory_item_id := CASE p_carcass_type
        WHEN 'Whole Lamb (Premium)' THEN '833f35f7-8fea-4696-9f73-f5bbb44e9e98'::UUID
        WHEN 'Whole Lamb (AB Grade)' THEN '833f35f7-8fea-4696-9f73-f5bbb44e9e98'::UUID
        WHEN 'Beef Side' THEN NULL
        WHEN 'Pork Side' THEN NULL
        ELSE NULL
    END;
    
    IF v_inventory_item_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 
                            format('No inventory item found for carcass type: %', p_carcass_type),
                            NULL::UUID;
        RETURN;
    END IF;
    
    -- Create stock movement for carcass intake
    INSERT INTO stock_movements (
        item_id,
        movement_type,
        quantity,
        unit_type,
        reference_id,
        reference_type,
        reason,
        staff_id
    ) VALUES (
        v_inventory_item_id,
        'carcass_in',
        p_weight,
        'kg',
        p_carcass_intake_id,
        'carcass_intake',
        format('Carcass intake: %s', p_carcass_type),
        p_staff_id
    ) RETURNING id INTO v_stock_movement_id;
    
    RETURN QUERY SELECT TRUE, 
                        format('Stock movement created for carcass %s: %s kg', p_carcass_type, p_weight),
                        v_stock_movement_id;
    RETURN;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'ERROR in create_carcass_intake_stock: %', SQLERRM;
        RETURN QUERY SELECT FALSE, SQLERRM, NULL::UUID;
        RETURN;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_carcass_intake_stock TO authenticated;
