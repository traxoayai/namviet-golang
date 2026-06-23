CREATE OR REPLACE FUNCTION public.list_product_synonyms(p_product_id bigint)
 RETURNS TABLE(id bigint, synonym text, weight real, created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
  SELECT ps.id, ps.synonym, ps.weight, ps.created_at
  FROM public.product_synonyms ps
  WHERE ps.product_id = p_product_id
    AND public.is_chat_staff()
  ORDER BY ps.weight DESC, ps.synonym;
$function$
