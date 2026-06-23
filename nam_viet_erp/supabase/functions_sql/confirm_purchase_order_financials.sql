CREATE OR REPLACE FUNCTION public.confirm_purchase_order_financials(p_po_id bigint, p_items_data jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_item JSONB;
    v_po_record RECORD;
    v_total_rebate NUMERIC := 0;
    v_supplier_id BIGINT;
    v_po_item_cf INT;
    v_real_base_cost NUMERIC;
BEGIN
    SELECT * INTO v_po_record FROM public.purchase_orders WHERE id = p_po_id;
    IF v_po_record IS NULL THEN RAISE EXCEPTION 'Không tìm thấy đơn mua hàng ID %', p_po_id; END IF;

    v_supplier_id := v_po_record.supplier_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items_data)
    LOOP
        UPDATE public.purchase_order_items
        SET vat_rate = COALESCE((v_item->>'vat_rate')::NUMERIC, 0), rebate_rate = COALESCE((v_item->>'rebate_rate')::NUMERIC, 0), bonus_quantity = COALESCE((v_item->>'bonus_quantity')::INTEGER, 0), allocated_shipping_fee = COALESCE((v_item->>'allocated_shipping_fee')::NUMERIC, 0), final_unit_cost = COALESCE((v_item->>'final_unit_cost')::NUMERIC, 0)
        WHERE id = (v_item->>'id')::BIGINT;

        v_total_rebate := v_total_rebate + (((v_item->>'unit_price')::NUMERIC * (v_item->>'quantity_ordered')::NUMERIC) * ((v_item->>'rebate_rate')::NUMERIC / 100.0));
            
        -- [CORE FIX]: Chia cho Conversion Factor
        SELECT COALESCE(NULLIF(conversion_factor, 0), 1) INTO v_po_item_cf FROM public.purchase_order_items WHERE id = (v_item->>'id')::BIGINT;
        v_real_base_cost := COALESCE((v_item->>'final_unit_cost')::NUMERIC, 0) / v_po_item_cf;

        UPDATE public.products SET actual_cost = v_real_base_cost, updated_at = NOW() WHERE id = (v_item->>'product_id')::BIGINT;
        
        UPDATE public.product_units SET price_cost = v_real_base_cost * COALESCE(conversion_rate, 1), updated_at = NOW() WHERE product_id = (v_item->>'product_id')::BIGINT;
    END LOOP;

    IF v_total_rebate > 0 THEN
        INSERT INTO public.supplier_wallets (supplier_id, balance, total_earned, updated_at) VALUES (v_supplier_id, v_total_rebate, v_total_rebate, NOW()) ON CONFLICT (supplier_id) DO UPDATE SET balance = public.supplier_wallets.balance + v_total_rebate, total_earned = public.supplier_wallets.total_earned + v_total_rebate, updated_at = NOW();
    END IF;

    UPDATE public.purchase_orders SET status = 'COMPLETED', updated_at = NOW() WHERE id = p_po_id;

    RETURN jsonb_build_object('success', true, 'total_rebate_earned', v_total_rebate, 'message', 'Đã cập nhật giá vốn và tích lũy ví NCC thành công.');
END;
$function$
