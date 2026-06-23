CREATE OR REPLACE FUNCTION public.create_manual_transfer(p_source_warehouse_id bigint, p_dest_warehouse_id bigint, p_note text, p_items jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_transfer_id BIGINT;
    v_code TEXT;
    v_item JSONB;
BEGIN
    -- 1. Validate
    IF p_source_warehouse_id = p_dest_warehouse_id THEN
        RAISE EXCEPTION 'Kho nguồn và đích không được trùng nhau';
    END IF;

    -- 2. Sinh mã phiếu (TRF-YYMMDD-XXXX)
    v_code := public._gen_finance_tx_code('TRF');

    -- 3. Tạo Header
    -- [CORE CONFIRM]: Dựa trên Schema, bảng inventory_transfers dùng 'created_by' (uuid)
    INSERT INTO public.inventory_transfers (
        code, 
        source_warehouse_id, 
        dest_warehouse_id, 
        status, 
        created_by,   -- [CORRECTED]: Tuân thủ schema
        note, 
        is_urgent,
        created_at,
        updated_at
    ) VALUES (
        v_code, 
        p_source_warehouse_id, 
        p_dest_warehouse_id, 
        'pending', 
        auth.uid(), 
        p_note, 
        false,
        NOW(),
        NOW()
    ) RETURNING id INTO v_transfer_id;

    -- 4. Tạo Items
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO public.inventory_transfer_items (
            transfer_id, 
            product_id, 
            unit, 
            conversion_factor, 
            qty_requested, 
            qty_approved, -- Mặc định bằng Requested
            qty_shipped,  -- Mặc định 0
            qty_received, -- Mặc định 0
            created_at
        ) VALUES (
            v_transfer_id,
            (v_item->>'product_id')::BIGINT,
            v_item->>'unit',
            COALESCE((v_item->>'conversion_factor')::INTEGER, 1),
            (v_item->>'quantity')::NUMERIC,
            (v_item->>'quantity')::NUMERIC, -- Auto approve
            0,
            0,
            NOW()
        );
    END LOOP;

    RETURN jsonb_build_object('success', true, 'transfer_id', v_transfer_id, 'code', v_code);
END;
$function$
