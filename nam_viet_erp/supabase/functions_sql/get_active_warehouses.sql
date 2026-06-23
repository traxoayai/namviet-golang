CREATE OR REPLACE FUNCTION public.get_active_warehouses()
 RETURNS TABLE(id bigint, name text, latitude numeric, longitude numeric)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
        SELECT 
            id, 
            name, 
            latitude, 
            longitude
        FROM public.warehouses 
        WHERE status = 'active'
        ORDER BY name ASC;
    $function$
