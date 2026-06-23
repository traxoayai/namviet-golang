CREATE OR REPLACE FUNCTION public.save_outbound_progress(p_order_id uuid, p_items jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_item JSONB;
        v_prod_id BIGINT;
        v_qty_picked INT;
    BEGIN
        -- Loop update từng dòng
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
        LOOP
            v_prod_id := (v_item->>'product_id')::BIGINT;
            v_qty_picked := (v_item->>'quantity_picked')::INTEGER;

            -- [FIXED] Nhân với conversion_factor để luôn lưu dưới dạng Đơn vị cơ sở (base unit)
            UPDATE public.order_items oi
            SET quantity_picked = v_qty_picked * COALESCE(oi.conversion_factor, 1),
                updated_at = NOW()
            WHERE order_id = p_order_id AND product_id = v_prod_id;
        END LOOP;

        RETURN jsonb_build_object('success', true, 'message', 'Lưu tiến độ thành công');
    END;
$function$
