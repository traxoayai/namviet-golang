CREATE OR REPLACE FUNCTION public.get_customer_b2b_details(p_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_customer jsonb;
    v_contacts jsonb;
    v_history jsonb;
BEGIN
    SELECT to_jsonb(c.*) INTO v_customer FROM public.customers_b2b c WHERE c.id = p_id;
    SELECT jsonb_agg(to_jsonb(ct.*)) INTO v_contacts FROM public.customer_b2b_contacts ct WHERE ct.customer_b2b_id = p_id;
    
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object('key', sub.id, 'date', sub.created_at, 'code', sub.code, 'content', 'Đơn hàng ' || sub.code, 'total', sub.final_amount, 'status', sub.status)
    ), '[]'::jsonb) INTO v_history
    FROM (
        SELECT id, created_at, code, final_amount, status FROM public.orders
        WHERE customer_id = p_id ORDER BY created_at DESC LIMIT 5
    ) sub;

    RETURN jsonb_build_object('customer', v_customer, 'contacts', COALESCE(v_contacts, '[]'::jsonb), 'history', v_history);
END;
$function$
