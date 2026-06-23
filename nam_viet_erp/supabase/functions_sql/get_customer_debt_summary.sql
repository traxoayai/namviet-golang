CREATE OR REPLACE FUNCTION public.get_customer_debt_summary(p_customer_b2b_id bigint)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_result JSON;
  v_exp RECORD;
BEGIN
  SELECT * INTO v_exp
  FROM public.get_customer_exposure_summary(p_customer_b2b_id)
  LIMIT 1;

  SELECT json_build_object(
    'customer_id', dv.customer_id,
    'customer_code', dv.customer_code,
    'customer_name', dv.customer_name,
    'total_invoiced', dv.total_invoiced,
    'total_paid', dv.total_paid,
    'actual_current_debt', dv.actual_current_debt,
    'debt_limit', c.debt_limit,
    'payment_term', c.payment_term,
    'available_credit', v_exp.available_credit,
    'pending_orders_total', v_exp.pending_orders_total,
    'total_exposure', v_exp.total_exposure
  ) INTO v_result
  FROM public.b2b_customer_debt_view dv
  JOIN public.customers_b2b c ON c.id = dv.customer_id
  WHERE dv.customer_id = p_customer_b2b_id;

  RETURN v_result;
END;
$function$
