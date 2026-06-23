CREATE OR REPLACE FUNCTION public.calculate_carton_breakdown(p_product_id bigint, p_required_qty integer)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_items_per_carton INTEGER;
    v_purchasing_policy TEXT;
    v_full_cartons INTEGER;
    v_remainder INTEGER;
    v_final_qty INTEGER;
    v_note TEXT;
BEGIN
    SELECT COALESCE(items_per_carton, 1), COALESCE(purchasing_policy, 'ALLOW_LOOSE')
    INTO v_items_per_carton, v_purchasing_policy
    FROM public.products WHERE id = p_product_id;

    IF NOT FOUND OR v_items_per_carton < 1 THEN v_items_per_carton := 1; END IF;

    v_full_cartons := FLOOR(p_required_qty / v_items_per_carton);
    v_remainder := p_required_qty % v_items_per_carton;

    IF v_purchasing_policy = 'ALLOW_LOOSE' THEN
        v_final_qty := p_required_qty;
        v_note := 'Chấp nhận nhập lẻ.';
    ELSIF v_purchasing_policy = 'FULL_CARTON_ONLY' THEN
        IF v_remainder > 0 THEN
            v_full_cartons := v_full_cartons + 1;
            v_remainder := 0;
            v_final_qty := v_full_cartons * v_items_per_carton;
            v_note := 'Đã làm tròn lên nguyên thùng.';
        ELSE
             v_final_qty := p_required_qty;
             v_note := 'Đã đủ nguyên thùng.';
        END IF;
    END IF;

    RETURN jsonb_build_object(
        'result', jsonb_build_object('full_cartons', v_full_cartons, 'loose_units', v_remainder, 'final_total_qty', v_final_qty),
        'note', v_note
    );
END;
$function$
