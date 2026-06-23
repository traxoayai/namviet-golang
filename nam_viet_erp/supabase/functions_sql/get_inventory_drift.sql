CREATE OR REPLACE FUNCTION public.get_inventory_drift(p_check_id bigint)
 RETURNS TABLE(product_id bigint, product_name text, batch_code text, system_snapshot integer, current_live integer, diff integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_warehouse_id BIGINT;
    BEGIN
        SELECT warehouse_id INTO v_warehouse_id FROM public.inventory_checks WHERE id = p_check_id;

        RETURN QUERY
        SELECT 
            ici.product_id,
            p.name,
            ici.batch_code,
            ici.system_quantity as system_snapshot,
            COALESCE(ib.quantity, 0)::INTEGER as current_live,
            (COALESCE(ib.quantity, 0)::INTEGER - ici.system_quantity) as diff
        FROM public.inventory_check_items ici
        JOIN public.products p ON ici.product_id = p.id
        -- Join lại vào kho thật (inventory_batches) để lấy số hiện tại
        LEFT JOIN public.batches b ON ici.batch_code = b.batch_code AND b.product_id = ici.product_id
        LEFT JOIN public.inventory_batches ib ON ib.batch_id = b.id AND ib.warehouse_id = v_warehouse_id
        WHERE ici.check_id = p_check_id
        -- Chỉ lấy dòng có sự thay đổi
        AND (COALESCE(ib.quantity, 0) <> ici.system_quantity);
    END;
    $function$
