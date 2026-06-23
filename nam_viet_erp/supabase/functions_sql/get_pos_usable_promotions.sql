CREATE OR REPLACE FUNCTION public.get_pos_usable_promotions(p_customer_id bigint, p_order_total numeric DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_result JSONB;
    BEGIN
        SELECT jsonb_agg(t) INTO v_result
        FROM (
            SELECT * FROM (
                SELECT DISTINCT ON (p.id)
                    p.id, p.code, p.name, p.description,
                    p.discount_type, p.discount_value,
                    p.min_order_value, p.max_discount_value,
                    p.valid_to,
                    
                    -- Nguồn gốc (Badge)
                    CASE 
                        WHEN cv.id IS NOT NULL OR (p.type = 'personal' AND p.customer_id = p_customer_id) THEN 'personal' 
                        ELSE 'campaign' 
                    END as voucher_source,
                    
                    -- Trạng thái sở hữu
                    (cv.id IS NOT NULL OR (p.type = 'personal' AND p.customer_id = p_customer_id)) as is_owned,

                    -- [SHOPEE LOGIC 1] Check điều kiện (Boolean)
                    (p.min_order_value IS NULL OR p.min_order_value <= p_order_total) as is_eligible,
                    
                    -- [SHOPEE LOGIC 2] Tính tiền cần mua thêm (Upsell)
                    GREATEST(0, COALESCE(p.min_order_value, 0) - p_order_total) as missing_amount,

                    EXTRACT(DAY FROM (p.valid_to - NOW()))::INT as days_remaining

                FROM public.promotions p
                
                LEFT JOIN public.customer_vouchers cv 
                    ON p.id = cv.promotion_id 
                    AND cv.customer_id = p_customer_id 
                    AND cv.status = 'active'
                    AND (cv.usage_remaining IS NULL OR cv.usage_remaining > 0)
                
                LEFT JOIN public.promotion_targets pt 
                    ON p.id = pt.promotion_id
                
                LEFT JOIN public.customer_segment_members csm 
                    ON pt.target_type = 'segment' 
                    AND pt.target_id = csm.segment_id 
                    AND csm.customer_id = p_customer_id

                WHERE 
                    p.status = 'active'
                    AND p.valid_from <= now() 
                    AND p.valid_to >= now()
                    -- Chỉ lấy Voucher B2C (Hệ thống bán lẻ)
                    AND (p.customer_type = 'B2C' OR p.customer_type IS NULL)
                    
                    -- [THAY ĐỔI LỚN]: KHÔNG check min_order_value ở đây nữa
                    -- Để trả về cả voucher chưa đủ điều kiện cho Frontend hiển thị mờ
                    AND (
                        cv.id IS NOT NULL  
                        OR pt.id IS NOT NULL 
                        OR (p.type = 'public' AND p.apply_to_scope = 'all')
                        OR (p.type = 'personal' AND p.customer_id = p_customer_id AND (p.total_usage_limit IS NULL OR p.usage_count < p.total_usage_limit))
                    )
                
                ORDER BY p.id -- Bắt buộc của DISTINCT ON
            ) sub_query
            
            -- [SHOPEE LOGIC 3] Sắp xếp danh sách trả về
            ORDER BY 
                sub_query.is_eligible DESC,       -- 1. Voucher dùng được ngay lên đầu
                sub_query.missing_amount ASC,     -- 2. Voucher gần đạt được nhất (Upsell dễ nhất) lên nhì
                sub_query.discount_value DESC     -- 3. Giảm giá sâu xếp trước
        ) t;

        RETURN COALESCE(v_result, '[]'::jsonb);
    END;
    $function$
