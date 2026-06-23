CREATE OR REPLACE FUNCTION public.bulk_update_product_prices(p_data jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    item jsonb;
    v_product_id BIGINT;
    v_has_wholesale BOOLEAN;
BEGIN
    FOR item IN SELECT * FROM jsonb_array_elements(p_data)
    LOOP
        v_product_id := (item->>'product_id')::BIGINT;

        -- 1. Update Product (Lưu Giá Vốn Base)
        UPDATE public.products 
        SET 
            actual_cost = COALESCE((item->>'actual_cost')::NUMERIC, actual_cost),
            retail_margin_value = COALESCE((item->>'retail_margin')::NUMERIC, retail_margin_value),
            retail_margin_type = COALESCE(item->>'retail_margin_type', retail_margin_type),
            wholesale_margin_value = COALESCE((item->>'wholesale_margin')::NUMERIC, wholesale_margin_value),
            wholesale_margin_type = COALESCE(item->>'wholesale_margin_type', wholesale_margin_type),
            updated_at = NOW()
        WHERE id = v_product_id;

        -- 2. [CORE FIX]: Update Product Units (Giá Vốn Đơn Vị = Base Cost * Rate)
        -- Đã bỏ logic chia cho MAX() sai lầm cũ.
        UPDATE public.product_units
        SET price_cost = COALESCE((item->>'actual_cost')::NUMERIC, 0) * conversion_rate,
            updated_at = NOW()
        WHERE product_id = v_product_id; 

        -- 3. Xử lý Giá Bán
        -- A. Cập nhật GIÁ LẺ (Cho Base Unit & Retail Unit)
        IF (item->>'retail_price') IS NOT NULL THEN
            UPDATE public.product_units
            SET price_sell = (item->>'retail_price')::NUMERIC,
                price = (item->>'retail_price')::NUMERIC, 
                updated_at = NOW()
            WHERE product_id = v_product_id
              AND (unit_type = 'retail' OR is_base = true)
              AND unit_type <> 'wholesale'; 
        END IF;

        -- B. Cập nhật GIÁ BUÔN (Cho Wholesale Unit)
        IF (item->>'wholesale_price') IS NOT NULL THEN
            SELECT EXISTS(SELECT 1 FROM public.product_units WHERE product_id = v_product_id AND unit_type = 'wholesale') INTO v_has_wholesale;
            
            IF v_has_wholesale THEN
                UPDATE public.product_units
                SET price_sell = (item->>'wholesale_price')::NUMERIC,
                    price = (item->>'wholesale_price')::NUMERIC,
                    updated_at = NOW()
                WHERE product_id = v_product_id AND unit_type = 'wholesale';
            ELSE
                UPDATE public.product_units
                SET price_sell = (item->>'wholesale_price')::NUMERIC,
                    price = (item->>'wholesale_price')::NUMERIC,
                    updated_at = NOW()
                WHERE product_id = v_product_id
                  AND conversion_rate = (SELECT MAX(conversion_rate) FROM public.product_units WHERE product_id = v_product_id)
                  AND (SELECT COUNT(*) FROM public.product_units WHERE product_id = v_product_id) > 1; 
            END IF;
        END IF;

    END LOOP;
END;
$function$
