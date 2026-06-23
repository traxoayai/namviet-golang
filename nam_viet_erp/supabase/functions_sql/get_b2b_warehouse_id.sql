CREATE OR REPLACE FUNCTION public.get_b2b_warehouse_id()
 RETURNS bigint
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_id BIGINT;
BEGIN
  SELECT id INTO v_id
  FROM public.warehouses
  WHERE type = 'b2b' AND status = 'active'
  ORDER BY id ASC
  LIMIT 1;

  IF v_id IS NULL THEN
    RAISE EXCEPTION 'Không tìm thấy kho B2B nào đang hoạt động (warehouses.type=''b2b'' AND status=''active'').';
  END IF;

  RETURN v_id;
END;
$function$
