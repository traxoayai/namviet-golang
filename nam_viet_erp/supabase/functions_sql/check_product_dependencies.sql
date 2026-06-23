CREATE OR REPLACE FUNCTION public.check_product_dependencies(p_product_ids bigint[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_result JSONB;
    BEGIN
        SELECT jsonb_agg(
            jsonb_build_object(
                'product_id', p.id,
                'product_name', p.name,
                'package_names', used_packages.names
            )
        ) INTO v_result
        FROM public.products p
        JOIN (
            -- [FIXED] Sửa spi.product_id -> spi.item_id
            SELECT 
                spi.item_id, 
                array_agg(DISTINCT sp.name) as names
            FROM public.service_package_items spi
            JOIN public.service_packages sp ON spi.package_id = sp.id
            
            -- [FIXED] WHERE clause
            WHERE spi.item_id = ANY(p_product_ids)
            
            -- [FIXED] GROUP BY clause
            GROUP BY spi.item_id
            
        ) used_packages ON p.id = used_packages.item_id; -- [FIXED] JOIN condition

        -- Nếu không có ràng buộc nào, trả về mảng rỗng thay vì NULL
        RETURN COALESCE(v_result, '[]'::JSONB);
    END;
    $function$
