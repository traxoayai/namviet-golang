CREATE OR REPLACE FUNCTION public.get_transaction_history(p_flow transaction_flow DEFAULT NULL::transaction_flow, p_fund_id bigint DEFAULT NULL::bigint, p_date_from timestamp with time zone DEFAULT NULL::timestamp with time zone, p_date_to timestamp with time zone DEFAULT NULL::timestamp with time zone, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0, p_search text DEFAULT NULL::text, p_status text DEFAULT NULL::text)
 RETURNS TABLE(id bigint, code text, transaction_date timestamp with time zone, flow transaction_flow, amount numeric, fund_name text, partner_name text, category_name text, description text, business_type business_type, created_by_name text, status transaction_status, ref_advance_id bigint, evidence_url text, total_count bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        t.id, t.code, t.transaction_date, t.flow, t.amount,
        f.name as fund_name,
        COALESCE(t.partner_name_cache, 'Khác') as partner_name,
        cat.name as category_name,
        t.description, t.business_type,
        u.full_name as created_by_name,
        t.status, t.ref_advance_id, t.evidence_url,
        COUNT(*) OVER() as total_count
    FROM public.finance_transactions t
    JOIN public.fund_accounts f ON t.fund_account_id = f.id
    LEFT JOIN public.transaction_categories cat ON t.category_id = cat.id
    LEFT JOIN public.users u ON t.created_by = u.id
    WHERE
        (p_flow IS NULL OR t.flow = p_flow)
        AND (p_fund_id IS NULL OR t.fund_account_id = p_fund_id)
        AND (p_date_from IS NULL OR t.transaction_date >= p_date_from)
        AND (p_date_to IS NULL OR t.transaction_date <= p_date_to)
        AND (p_status IS NULL OR p_status = '' OR t.status = p_status::public.transaction_status)
        AND (
            p_search IS NULL OR p_search = '' OR
            t.code ILIKE '%' || p_search || '%' OR
            t.description ILIKE '%' || p_search || '%' OR
            t.partner_name_cache ILIKE '%' || p_search || '%'
        )
    ORDER BY t.transaction_date DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$
