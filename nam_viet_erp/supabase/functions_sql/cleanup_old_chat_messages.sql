CREATE OR REPLACE FUNCTION public.cleanup_old_chat_messages()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
  v_cutoff timestamptz := now() - interval '365 days';
  v_deleted_count int := 0;
BEGIN
  WITH updated AS (
    UPDATE public.chat_messages
       SET deleted_at = now()
     WHERE created_at < v_cutoff
       AND deleted_at IS NULL
    RETURNING 1
  )
  SELECT COUNT(*)::int INTO v_deleted_count FROM updated;

  RETURN jsonb_build_object(
    'deleted_count', v_deleted_count,
    'cutoff_date',   v_cutoff::text
  );
END;
$function$
