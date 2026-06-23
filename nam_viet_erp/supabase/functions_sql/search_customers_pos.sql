CREATE OR REPLACE FUNCTION public.search_customers_pos(p_keyword text)
 RETURNS TABLE(id bigint, code text, name text, phone text, type text, debt_amount numeric, loyalty_points integer, sub_label text, customer_type text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_text_part TEXT;
        v_phone_part TEXT;
    BEGIN
        -- Parse Input
        v_phone_part := regexp_replace(p_keyword, '[^0-9]', '', 'g');
        v_text_part := trim(regexp_replace(p_keyword, '[0-9]', '', 'g'));
        
        IF v_phone_part = '' THEN v_phone_part := NULL; END IF;
        IF v_text_part = '' THEN v_text_part := NULL; END IF;

        IF v_phone_part IS NULL AND v_text_part IS NULL THEN RETURN; END IF;

        RETURN QUERY
        WITH matched_customers AS (
            -- 1. CaNhan
            SELECT c.id, c.customer_code as code, c.name, c.phone, c.type::TEXT, c.loyalty_points,
                   NULL::TEXT as relation_info, 1 as priority, c.customer_type::text
            FROM public.customers c
            WHERE c.status = 'active' AND c.type = 'CaNhan'
              AND (v_text_part IS NULL OR c.name ILIKE '%' || v_text_part || '%')
              AND (v_phone_part IS NULL OR c.phone ILIKE '%' || v_phone_part || '%')

            UNION ALL

            -- 2. ToChuc (B2C)
            SELECT c.id, c.customer_code as code, c.name, c.phone, c.type::TEXT, c.loyalty_points,
                   'LH: ' || COALESCE(c.contact_person_name, 'N/A') as relation_info, 2 as priority, c.customer_type::text
            FROM public.customers c
            WHERE c.status = 'active' AND c.type = 'ToChuc'
              AND (
                  (v_text_part IS NULL OR c.name ILIKE '%' || v_text_part || '%') AND (v_phone_part IS NULL OR c.phone ILIKE '%' || v_phone_part || '%')
                  OR
                  (v_text_part IS NULL OR c.contact_person_name ILIKE '%' || v_text_part || '%') AND (v_phone_part IS NULL OR c.contact_person_phone ILIKE '%' || v_phone_part || '%')
              )

            UNION ALL

            -- 3. Phu huynh
            SELECT child.id, child.customer_code as code, child.name, child.phone, child.type::TEXT, child.loyalty_points,
                   'PH: ' || guardian.name || ' (' || guardian.phone || ')' as relation_info, 3 as priority, child.customer_type::text
            FROM public.customers child
            JOIN public.customer_guardians cg ON child.id = cg.customer_id
            JOIN public.customers guardian ON cg.guardian_id = guardian.id
            WHERE child.status = 'active'
              AND (v_text_part IS NULL OR guardian.name ILIKE '%' || v_text_part || '%')
              AND (v_phone_part IS NULL OR guardian.phone ILIKE '%' || v_phone_part || '%')
              
            UNION ALL
            
            -- 4. B2B Customers
            SELECT b.id, b.customer_code as code, b.name, b.phone, 'B2B'::TEXT as type, b.loyalty_points,
                   'MST: ' || COALESCE(b.tax_code, 'N/A') as relation_info, 0 as priority, b.customer_type::text
            FROM public.customers_b2b b
            WHERE b.status = 'active'
              AND (v_text_part IS NULL OR b.name ILIKE '%' || v_text_part || '%')
              AND (v_phone_part IS NULL OR b.phone ILIKE '%' || v_phone_part || '%')
        )
        SELECT 
            mc.id, mc.code, mc.name, mc.phone, mc.type,
            
            COALESCE((
                SELECT SUM(o.final_amount - o.paid_amount) 
                FROM public.orders o 
                WHERE 
                  ((mc.customer_type = 'B2C' AND o.customer_b2c_id = mc.id) OR (mc.customer_type = 'B2B' AND o.customer_b2b_id = mc.id))
                  AND o.status NOT IN ('DRAFT', 'CANCELLED', 'QUOTE')
                  AND o.payment_status != 'paid'
            ), 0) AS debt_amount,
            
            mc.loyalty_points,
            CASE WHEN mc.customer_type = 'B2B' THEN 'Khách Sỉ (B2B)' 
                 WHEN mc.relation_info IS NOT NULL THEN mc.relation_info 
                 WHEN mc.type = 'ToChuc' THEN 'Khách Doanh Nghiệp' 
                 ELSE 'Khách Lẻ' 
            END AS sub_label,
            mc.customer_type
        FROM matched_customers mc
        GROUP BY mc.id, mc.code, mc.name, mc.phone, mc.type, mc.loyalty_points, mc.relation_info, mc.priority, mc.customer_type
        ORDER BY mc.priority ASC, mc.name ASC
        LIMIT 20;
    END;
    $function$
