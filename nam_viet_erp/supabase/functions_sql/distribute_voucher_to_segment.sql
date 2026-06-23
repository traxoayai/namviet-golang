CREATE OR REPLACE FUNCTION public.distribute_voucher_to_segment(p_promotion_id uuid, p_segment_id bigint)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    DECLARE
        v_count INT;
        v_promo_code TEXT;
    BEGIN
        -- 1. Lấy mã hiển thị (code) từ bảng gốc
        SELECT code INTO v_promo_code FROM public.promotions WHERE id = p_promotion_id;
        
        IF v_promo_code IS NULL THEN
            RAISE EXCEPTION 'Không tìm thấy chương trình khuyến mãi ID %', p_promotion_id;
        END IF;

        -- 2. Thực hiện phát tặng (Insert Bulk)
        WITH inserted AS (
            INSERT INTO public.customer_vouchers (customer_id, promotion_id, code, status, usage_remaining)
            SELECT 
                m.customer_id, 
                p_promotion_id, 
                v_promo_code, 
                'active',
                1 -- Tặng 1 vé
            FROM public.customer_segment_members m
            WHERE m.segment_id = p_segment_id
            -- Điều kiện loại trừ: Không tặng nếu khách đã có voucher này rồi (tránh spam)
            AND NOT EXISTS (
                SELECT 1 FROM public.customer_vouchers cv 
                WHERE cv.customer_id = m.customer_id 
                AND cv.promotion_id = p_promotion_id
            )
            RETURNING id
        )
        SELECT COUNT(*) INTO v_count FROM inserted;

        -- 3. Ghi nhận vào bảng Target (để UI hiển thị là nhóm này đã được chọn)
        INSERT INTO public.promotion_targets (promotion_id, target_type, target_id)
        VALUES (p_promotion_id, 'segment', p_segment_id)
        ON CONFLICT DO NOTHING;

        RETURN v_count;
    END;
    $function$
