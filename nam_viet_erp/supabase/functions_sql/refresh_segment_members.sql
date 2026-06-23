CREATE OR REPLACE FUNCTION public.refresh_segment_members(p_segment_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    DECLARE
        v_segment RECORD;
        v_criteria JSONB;
        v_sql TEXT;
    BEGIN
        -- A. Lấy thông tin phân khúc
        SELECT * INTO v_segment FROM public.customer_segments WHERE id = p_segment_id;
        
        -- Chỉ xử lý nếu tìm thấy và là nhóm 'dynamic'
        IF NOT FOUND OR v_segment.type = 'static' THEN 
            RETURN; 
        END IF;

        v_criteria := v_segment.criteria;

        -- B. Xây dựng câu Query động
        -- Khởi tạo câu Select cơ bản
        v_sql := format('SELECT %L::BIGINT, id FROM public.customers WHERE status = ''active'' ', p_segment_id);

        -- =================================================================
        -- C. CÁC TIÊU CHÍ LỌC (LOGIC CŨ & MỚI)
        -- =================================================================

        -- 1. Giới tính (Gender)
        IF v_criteria ? 'gender' THEN
            v_sql := v_sql || format(' AND gender = %L', v_criteria->>'gender');
        END IF;

        -- 2. Điểm tích lũy (Loyalty Points)
        IF v_criteria ? 'min_loyalty' THEN
            v_sql := v_sql || format(' AND loyalty_points >= %s', (v_criteria->>'min_loyalty')::int);
        END IF;

        -- 3. Tháng sinh nhật (Birthday)
        IF v_criteria ? 'birthday_month' THEN
            IF (v_criteria->>'birthday_month') = 'current' THEN
                v_sql := v_sql || ' AND EXTRACT(MONTH FROM dob::date) = EXTRACT(MONTH FROM CURRENT_DATE)';
            ELSE
                v_sql := v_sql || format(' AND EXTRACT(MONTH FROM dob::date) = %s', (v_criteria->>'birthday_month')::int);
            END IF;
        END IF;

        -- 4. Độ tuổi (Age)
        IF v_criteria ? 'min_age' THEN
            v_sql := v_sql || format(' AND EXTRACT(YEAR FROM age(dob::date)) >= %s', (v_criteria->>'min_age')::int);
        END IF;
        IF v_criteria ? 'max_age' THEN
            v_sql := v_sql || format(' AND EXTRACT(YEAR FROM age(dob::date)) <= %s', (v_criteria->>'max_age')::int);
        END IF;

        -- 5. [NEW] THỜI GIAN MUA HÀNG (RECENCY) - Mệnh Lệnh 43
        -- Ý nghĩa: Tìm khách hàng ĐÃ LÂU KHÔNG MUA (để chăm sóc lại)
        -- Logic: (Chưa từng mua) HOẶC (Lần mua cuối < Hiện tại - X tháng)
        IF v_criteria ? 'last_purchase_months' THEN
            v_sql := v_sql || format(
                ' AND (last_purchase_at IS NULL OR last_purchase_at < (NOW() - INTERVAL ''%s months''))', 
                (v_criteria->>'last_purchase_months')::int
            );
        END IF;

        -- =================================================================
        -- D. THỰC THI (EXECUTE)
        -- =================================================================
        
        -- Bước 1: Xóa thành viên cũ để làm mới
        DELETE FROM public.customer_segment_members WHERE segment_id = p_segment_id;

        -- Bước 2: Insert danh sách mới
        EXECUTE format('INSERT INTO public.customer_segment_members (segment_id, customer_id) %s', v_sql);

        -- Bước 3: Cập nhật thời gian chạy
        UPDATE public.customer_segments SET updated_at = NOW() WHERE id = p_segment_id;
    END;
    $function$
