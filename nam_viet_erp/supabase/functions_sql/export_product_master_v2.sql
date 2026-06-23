CREATE OR REPLACE FUNCTION public.export_product_master_v2()
 RETURNS TABLE(product_id bigint, sku text, name text, status text, image_url text, barcode text, manufacturer_name text, distributor_id bigint, cost_price numeric, base_unit_name text, retail_unit_name text, retail_conversion_rate integer, wholesale_unit_name text, wholesale_conversion_rate integer, logistic_unit_name text, logistic_conversion_rate integer, retail_margin_value numeric, retail_margin_type text, wholesale_margin_value numeric, wholesale_margin_type text, warehouse_settings jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as product_id,
        p.sku,
        p.name,
        p.status,
        p.image_url,
        p.barcode,
        p.manufacturer_name,
        p.distributor_id,
        
        -- Map cột vật lý 'actual_cost' sang alias 'cost_price'
        COALESCE(p.actual_cost, 0) as cost_price, 
        
        -- Base Unit
        (SELECT unit_name FROM public.product_units u WHERE u.product_id = p.id AND u.is_base = true LIMIT 1),
        
        -- Retail Unit
        (SELECT unit_name FROM public.product_units u WHERE u.product_id = p.id AND u.unit_type = 'retail' LIMIT 1),
        (SELECT conversion_rate::integer FROM public.product_units u WHERE u.product_id = p.id AND u.unit_type = 'retail' LIMIT 1),
        
        -- Wholesale Unit
        (SELECT unit_name FROM public.product_units u WHERE u.product_id = p.id AND u.unit_type = 'wholesale' LIMIT 1),
        (SELECT conversion_rate::integer FROM public.product_units u WHERE u.product_id = p.id AND u.unit_type = 'wholesale' LIMIT 1),
        
        -- Logistic Unit
        (SELECT unit_name FROM public.product_units u WHERE u.product_id = p.id AND u.unit_type = 'logistic' LIMIT 1),
        (SELECT conversion_rate::integer FROM public.product_units u WHERE u.product_id = p.id AND u.unit_type = 'logistic' LIMIT 1),
        
        -- Margin
        p.retail_margin_value,
        p.retail_margin_type,
        p.wholesale_margin_value,
        p.wholesale_margin_type,
        
        -- Aggregate Warehouse Settings
        COALESCE(
            (
                SELECT jsonb_agg(jsonb_build_object(
                    'warehouse_id', pi.warehouse_id,
                    'min', pi.min_stock,
                    'max', pi.max_stock
                ))
                FROM public.product_inventory pi
                WHERE pi.product_id = p.id
            ),
            '[]'::jsonb
        ) as warehouse_settings
        
    FROM public.products p
    ORDER BY p.created_at DESC;
END;
$function$
