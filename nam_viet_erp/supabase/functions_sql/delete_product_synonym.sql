CREATE OR REPLACE FUNCTION public.delete_product_synonym(p_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
BEGIN
  IF NOT public.is_chat_staff() THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;
  DELETE FROM public.product_synonyms WHERE id = p_id;
END;
$function$
