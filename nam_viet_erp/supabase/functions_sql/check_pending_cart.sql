CREATE OR REPLACE FUNCTION public.check_pending_cart(p_user_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
  v_portal_user_id uuid;
  v_count int;
  v_total numeric;
  v_last timestamptz;
BEGIN
  -- Resolve portal_user từ auth uid
  SELECT id INTO v_portal_user_id
  FROM public.portal_users
  WHERE auth_user_id = p_user_id
  LIMIT 1;

  IF v_portal_user_id IS NULL THEN
    RETURN jsonb_build_object('has_pending', false);
  END IF;

  -- Aggregate items hiện có trong giỏ (portal_cart_items đã lưu unit_price khi add).
  SELECT
    COUNT(*),
    COALESCE(SUM(ci.quantity * ci.unit_price), 0),
    MAX(GREATEST(ci.created_at, ci.updated_at))
  INTO v_count, v_total, v_last
  FROM public.portal_cart_items ci
  WHERE ci.portal_user_id = v_portal_user_id;

  -- Không có item HOẶC giỏ vừa update gần đây (<6h) → không cần prompt resume.
  IF v_count = 0 OR v_last IS NULL OR v_last > now() - interval '6 hours' THEN
    RETURN jsonb_build_object('has_pending', false);
  END IF;

  RETURN jsonb_build_object(
    'has_pending', true,
    'item_count', v_count,
    'total', v_total,
    'last_added_at', v_last
  );
END;
$function$
