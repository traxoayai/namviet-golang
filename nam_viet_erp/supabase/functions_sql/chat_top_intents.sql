CREATE OR REPLACE FUNCTION public.chat_top_intents(p_from date, p_to date, p_limit integer DEFAULT 10)
 RETURNS TABLE(intent text, count integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
  SELECT COALESCE(m.intent, 'unknown')::text AS intent,
         COUNT(*)::int                       AS count
  FROM public.chat_messages m
  WHERE public.is_chat_staff()
    AND m.role = 'user'
    AND m.deleted_at IS NULL
    AND m.created_at::date BETWEEN p_from AND p_to
  GROUP BY 1
  ORDER BY 2 DESC, 1 ASC
  LIMIT GREATEST(COALESCE(p_limit, 10), 1);
$function$
