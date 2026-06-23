CREATE OR REPLACE FUNCTION public.get_system_logs(p_page integer DEFAULT 1, p_page_size integer DEFAULT 20, p_module text DEFAULT NULL::text, p_action text DEFAULT NULL::text, p_date_from timestamp with time zone DEFAULT NULL::timestamp with time zone, p_date_to timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_sql_data TEXT;
    v_sql_count TEXT;
    v_where_clauses TEXT[] := ARRAY['1=1'];
    v_where_str TEXT;
    v_data JSONB;
    v_total_count INT;
BEGIN
    -- Lắp ghép điều kiện Động (Tư duy Senko)
    IF p_module IS NOT NULL AND p_module <> '' THEN
        v_where_clauses := array_append(v_where_clauses, format('module = %L', p_module));
    END IF;
    
    IF p_action IS NOT NULL AND p_action <> '' THEN
        v_where_clauses := array_append(v_where_clauses, format('action = %L', p_action));
    END IF;

    IF p_date_from IS NOT NULL THEN
        v_where_clauses := array_append(v_where_clauses, format('created_at >= %L', p_date_from));
    END IF;

    IF p_date_to IS NOT NULL THEN
        v_where_clauses := array_append(v_where_clauses, format('created_at <= %L', p_date_to));
    END IF;

    v_where_str := array_to_string(v_where_clauses, ' AND ');

    -- Đếm tổng số dòng (Siêu tốc)
    v_sql_count := 'SELECT COUNT(*) FROM public.system_logs WHERE ' || v_where_str;
    EXECUTE v_sql_count INTO v_total_count;

    -- Lấy dữ liệu phân trang (Ép dùng Index created_at)
    v_sql_data := format(
        'SELECT COALESCE(jsonb_agg(t.*), ''[]''::jsonb)
         FROM (
             SELECT id, action, module, record_id, old_data, new_data, created_at, user_id, user_name
             FROM public.system_logs
             WHERE %s
             ORDER BY created_at DESC
             LIMIT %s OFFSET %s
         ) t',
        v_where_str, p_page_size, (p_page - 1) * p_page_size
    );
    
    EXECUTE v_sql_data INTO v_data;

    RETURN jsonb_build_object(
        'data', COALESCE(v_data, '[]'::jsonb),
        'total_count', COALESCE(v_total_count, 0)
    );
END;
$function$
