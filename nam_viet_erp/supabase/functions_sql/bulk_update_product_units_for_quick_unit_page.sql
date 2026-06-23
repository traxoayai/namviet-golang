CREATE OR REPLACE FUNCTION public.bulk_update_product_units_for_quick_unit_page(p_data jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    item JSONB;
    v_product_id BIGINT;
    v_base_unit TEXT;
    v_retail_unit TEXT;
    v_retail_rate INT;
    v_wholesale_unit TEXT;
    v_wholesale_rate INT;
    v_cost NUMERIC;
BEGIN
    FOR item IN SELECT value FROM jsonb_array_elements(p_data) AS t(value)
    LOOP
        -- 1. Tìm Product ID
        v_product_id := (item->>'product_id')::BIGINT;
        IF v_product_id IS NULL THEN
            SELECT id INTO v_product_id FROM public.products 
            WHERE sku = (item->>'sku') AND status = 'active' LIMIT 1;
        END IF;

        IF v_product_id IS NOT NULL THEN
            -- Lấy dữ liệu
            v_base_unit := COALESCE(NULLIF(TRIM(item->>'base_unit'), ''), 'Viên');
            v_retail_unit := NULLIF(TRIM(item->>'retail_unit'), '');
            v_retail_rate := COALESCE((item->>'retail_rate')::INT, 1);
            v_wholesale_unit := NULLIF(TRIM(item->>'wholesale_unit'), '');
            v_wholesale_rate := COALESCE((item->>'wholesale_rate')::INT, 1);
            
            SELECT actual_cost INTO v_cost FROM public.products WHERE id = v_product_id;

            -- 2. XÓA SẠCH LÀM LẠI
            DELETE FROM public.product_units WHERE product_id = v_product_id;

            -- A. TẠO UNIT BASE
            INSERT INTO public.product_units (
                product_id, unit_name, conversion_rate, is_base, is_direct_sale, price_cost, unit_type
            ) VALUES (
                v_product_id, v_base_unit, 1, true, true, v_cost, 'base'
            );

            -- B. TẠO UNIT RETAIL (Chấp nhận trùng tên Base)
            IF v_retail_unit IS NOT NULL AND v_retail_unit <> '' THEN
                INSERT INTO public.product_units (
                    product_id, unit_name, conversion_rate, is_base, is_direct_sale, price_cost, unit_type
                ) VALUES (
                    v_product_id, v_retail_unit, v_retail_rate, false, true, v_cost * v_retail_rate, 'retail'
                );
            END IF;

            -- C. TẠO UNIT WHOLESALE (Chấp nhận Rate = 1)
            -- [FIX V6]: Đã bỏ điều kiện (AND v_wholesale_rate > 1)
            IF v_wholesale_unit IS NOT NULL AND v_wholesale_unit <> '' THEN
                INSERT INTO public.product_units (
                    product_id, unit_name, conversion_rate, is_base, is_direct_sale, price_cost, unit_type
                ) VALUES (
                    v_product_id, v_wholesale_unit, v_wholesale_rate, false, true, v_cost * v_wholesale_rate, 'wholesale'
                );
            END IF;

            -- 3. CẬP NHẬT BẢNG PRODUCTS (Hiển thị)
            UPDATE public.products
            SET 
                retail_unit = COALESCE(v_retail_unit, v_base_unit),
                wholesale_unit = v_wholesale_unit,
                -- Conversion factor lấy cái lớn nhất để hiển thị
                conversion_factor = GREATEST(v_wholesale_rate, v_retail_rate),
                updated_at = NOW()
            WHERE id = v_product_id;
        END IF;
    END LOOP;
END;
$function$
