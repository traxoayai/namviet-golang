CREATE OR REPLACE FUNCTION public._check_b2b_credit_exposure(p_customer_id bigint, p_order_type text, p_final_amount numeric)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_available_credit NUMERIC;
BEGIN
  -- [DISABLED 2026-04-17] Data hạn mức công nợ chưa chuẩn.
  -- Để bật lại: tạo migration mới override function này, bỏ RETURN sau đây
  -- và bỏ comment block IF dưới.
  RETURN;

  -- IF p_customer_id IS NOT NULL AND p_order_type = 'B2B' THEN
  --   PERFORM id FROM public.customers_b2b WHERE id = p_customer_id FOR UPDATE;
  --   SELECT available_credit INTO v_available_credit
  --   FROM public.get_customer_exposure_summary(p_customer_id);
  --   IF (COALESCE(v_available_credit, 0) - p_final_amount) < 0 THEN
  --     RAISE EXCEPTION 'Vượt hạn mức công nợ khả dụng. Khả dụng: %đ, Đơn: %đ',
  --       COALESCE(v_available_credit, 0)::BIGINT, p_final_amount::BIGINT;
  --   END IF;
  -- END IF;
END;
$function$
