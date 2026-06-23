CREATE OR REPLACE FUNCTION public.get_distinct_manufacturers()
 RETURNS TABLE(manufacturer_name text)
 LANGUAGE sql
AS $function$
  SELECT DISTINCT manufacturer_name 
  FROM public.products 
  WHERE manufacturer_name IS NOT NULL AND manufacturer_name <> ''
  ORDER BY manufacturer_name;
$function$
