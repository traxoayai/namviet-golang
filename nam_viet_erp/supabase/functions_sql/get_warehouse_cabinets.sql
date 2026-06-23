CREATE OR REPLACE FUNCTION public.get_warehouse_cabinets(p_warehouse_id bigint)
 RETURNS TABLE(cabinet_name text)
 LANGUAGE sql
 SECURITY DEFINER
AS $function$
        SELECT DISTINCT location_cabinet 
        FROM public.product_inventory 
        WHERE warehouse_id = p_warehouse_id 
          AND location_cabinet IS NOT NULL 
          AND location_cabinet <> ''
        ORDER BY location_cabinet;
    $function$
