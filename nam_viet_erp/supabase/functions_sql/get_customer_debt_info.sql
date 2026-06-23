CREATE OR REPLACE FUNCTION public.get_customer_debt_info(p_customer_id bigint)
 RETURNS TABLE(customer_id bigint, customer_name text, debt_limit numeric, current_debt numeric, available_credit numeric, is_bad_debt boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    -- Query thẳng vào bảng customers_b2b và join với View công nợ
    SELECT 
        c.id AS customer_id,
        c.name AS customer_name,
        COALESCE(c.debt_limit, 0) AS debt_limit,
        COALESCE(v.actual_current_debt, 0) AS current_debt,
        (COALESCE(c.debt_limit, 0) - COALESCE(v.actual_current_debt, 0)) AS available_credit,
        (COALESCE(v.actual_current_debt, 0) > COALESCE(c.debt_limit, 0)) AS is_bad_debt
    FROM public.customers_b2b c
    -- Tận dụng Nguồn Chân Lý (View) đã có sẵn
    LEFT JOIN public.b2b_customer_debt_view v ON c.id = v.customer_id
    WHERE c.id = p_customer_id;
$function$
