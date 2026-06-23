CREATE OR REPLACE FUNCTION public.chat_unmatched_questions(p_from date, p_to date, p_limit integer DEFAULT 20)
 RETURNS TABLE(question text, occurred_at timestamp with time zone, session_id uuid)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
  SELECT m.content::text   AS question,
         m.created_at      AS occurred_at,
         m.session_id      AS session_id
  FROM public.chat_messages m
  WHERE public.is_chat_staff()
    AND m.role = 'user'
    AND (m.intent IS NULL OR m.intent = 'unknown')
    AND m.deleted_at IS NULL
    AND m.content IS NOT NULL
    AND btrim(m.content) <> ''
    AND m.created_at::date BETWEEN p_from AND p_to
  ORDER BY m.created_at DESC
  LIMIT GREATEST(COALESCE(p_limit, 20), 1);
$function$
