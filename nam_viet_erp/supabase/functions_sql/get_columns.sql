CREATE OR REPLACE FUNCTION public.get_columns(table_name text)
 RETURNS TABLE(column_name text, data_type text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
  SELECT c.column_name::text, c.data_type::text
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND c.table_name = get_columns.table_name;
$function$
