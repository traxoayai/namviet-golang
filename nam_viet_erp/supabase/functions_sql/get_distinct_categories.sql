CREATE OR REPLACE FUNCTION public.get_distinct_categories()
 RETURNS TABLE(category_name text)
 LANGUAGE sql
AS $function$
  SELECT DISTINCT category_name 
  FROM public.products 
  WHERE category_name IS NOT NULL AND category_name <> ''
  ORDER BY category_name;
$function$
