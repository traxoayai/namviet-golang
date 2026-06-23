CREATE OR REPLACE FUNCTION public.split_csv_nonempty(p text)
 RETURNS text[]
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
  SELECT COALESCE(
    array_agg(trim(x)) FILTER (WHERE trim(x) <> ''),
    ARRAY[]::text[]
  )
  FROM unnest(string_to_array(coalesce(p, ''), ',')) AS t(x);
$function$
