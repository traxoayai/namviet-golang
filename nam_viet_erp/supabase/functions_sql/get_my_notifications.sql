CREATE OR REPLACE FUNCTION public.get_my_notifications(p_category text DEFAULT NULL::text, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_offset INT := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_total  INT;
  v_data   JSON;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM public.notifications n
  WHERE n.user_id = auth.uid()
    AND (p_category IS NULL OR n.category = p_category);

  SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json) INTO v_data
  FROM (
    SELECT
      n.id,
      n.title,
      n.message,
      n.type,
      n.is_read,
      n.category,
      n.metadata,
      n.reference_id,
      n.created_at
    FROM public.notifications n
    WHERE n.user_id = auth.uid()
      AND (p_category IS NULL OR n.category = p_category)
    ORDER BY n.created_at DESC
    LIMIT p_page_size OFFSET v_offset
  ) t;

  RETURN json_build_object(
    'data', v_data,
    'total', v_total,
    'page', p_page,
    'page_size', p_page_size
  );
END;
$function$
