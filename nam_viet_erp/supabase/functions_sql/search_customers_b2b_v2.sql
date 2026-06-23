CREATE OR REPLACE FUNCTION public.search_customers_b2b_v2(p_keyword text)
 RETURNS TABLE(id bigint, name text, tax_code text, vat_address text, shipping_address text, phone text, debt_limit numeric, current_debt numeric, loyalty_points integer, contacts jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    -- Chuẩn hóa từ khóa tìm kiếm: Xóa khoảng trắng thừa, chuyển về chữ thường
    v_clean_keyword text := TRIM(p_keyword); 
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.tax_code,
        c.vat_address,
        c.shipping_address,
        c.phone,
        COALESCE(c.debt_limit, 0),
        COALESCE(c.current_debt, 0),
        COALESCE(c.loyalty_points, 0), -- Cột này là Integer
        
        -- Lấy danh sách liên hệ (giữ nguyên để không lỗi giao diện)
        COALESCE((
            SELECT jsonb_agg(jsonb_build_object(
                'name', cc.name,
                'phone', cc.phone,
                'position', cc.position,
                'is_primary', cc.is_primary
            ))
            FROM public.customer_b2b_contacts cc
            WHERE cc.customer_b2b_id = c.id
        ), '[]'::jsonb) as contacts
    FROM public.customers_b2b c
    WHERE 
        c.status = 'active'
        AND (
            v_clean_keyword IS NULL OR v_clean_keyword = '' 
            OR
            -- Tìm theo Tên (Chứa từ khóa, không phân biệt hoa thường)
            -- VD: "ngọc du" sẽ tìm thấy trong "Quầy Thuốc Ngọc Duy"
            c.name ILIKE '%' || v_clean_keyword || '%' 
            OR
            -- Tìm theo SĐT
            c.phone ILIKE '%' || v_clean_keyword || '%' 
            OR
            -- Tìm theo Mã số thuế
            c.tax_code ILIKE '%' || v_clean_keyword || '%' 
            OR
            -- Tìm theo Mã khách hàng
            c.customer_code ILIKE '%' || v_clean_keyword || '%'
        )
    ORDER BY 
        -- Ưu tiên: Nếu tên bắt đầu bằng từ khóa thì lên đầu (Tăng trải nghiệm tìm kiếm)
        CASE WHEN c.name ILIKE v_clean_keyword || '%' THEN 0 ELSE 1 END,
        c.name ASC
    LIMIT 20;
END;
$function$
