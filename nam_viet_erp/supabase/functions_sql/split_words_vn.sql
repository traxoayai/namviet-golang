CREATE OR REPLACE FUNCTION public.split_words_vn(p_text text)
 RETURNS text[]
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$
  SELECT COALESCE(
    array_remove(string_to_array(trim(COALESCE(p_text, '')), ' '), ''),
    ARRAY[]::text[]
  );
$function$
