CREATE OR REPLACE FUNCTION public.bulk_upsert_products(p_products_array jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    product_data JSONB;
    v_product_id BIGINT;
    v_warehouse_id BIGINT;
    v_branch_key TEXT;
    v_inventory_settings JSONB;
    
    -- Biến xử lý đơn vị
    v_retail_unit TEXT;
    v_wholesale_unit TEXT;
    v_conversion_factor INT;
    v_actual_cost NUMERIC;
BEGIN
    -- Loop qua từng sản phẩm trong mảng JSON từ Excel
    FOR product_data IN SELECT value FROM jsonb_array_elements(p_products_array) AS t(value)
    LOOP
        v_retail_unit := product_data->>'retail_unit';
        v_wholesale_unit := product_data->>'wholesale_unit';
        v_conversion_factor := COALESCE((product_data->>'conversion_factor')::INT, 1);
        v_actual_cost := COALESCE((product_data->>'actual_cost')::NUMERIC, 0);

        -- 1. UPSERT VÀO BẢNG CHÍNH (PRODUCTS)
        INSERT INTO public.products (
            name, sku, barcode, active_ingredient, image_url,
            category_name, manufacturer_name, distributor_id, status,
            invoice_price, actual_cost, 
            wholesale_unit, retail_unit, conversion_factor,
            updated_at
        )
        VALUES (
            product_data->>'name',
            product_data->>'sku',
            product_data->>'barcode',
            product_data->>'active_ingredient',
            product_data->>'image_url',
            product_data->>'category_name',
            product_data->>'manufacturer_name',
            (product_data->>'distributor_id')::BIGINT,
            COALESCE(product_data->>'status', 'active'),
            (product_data->>'invoice_price')::NUMERIC,
            v_actual_cost,
            v_wholesale_unit,
            v_retail_unit,
            v_conversion_factor,
            NOW()
        )
        ON CONFLICT (sku)
        DO UPDATE SET
            name = EXCLUDED.name,
            barcode = EXCLUDED.barcode,
            active_ingredient = EXCLUDED.active_ingredient,
            category_name = EXCLUDED.category_name,
            manufacturer_name = EXCLUDED.manufacturer_name,
            distributor_id = EXCLUDED.distributor_id,
            status = EXCLUDED.status,
            invoice_price = EXCLUDED.invoice_price,
            actual_cost = EXCLUDED.actual_cost,
            wholesale_unit = EXCLUDED.wholesale_unit,
            retail_unit = EXCLUDED.retail_unit,
            conversion_factor = EXCLUDED.conversion_factor,
            updated_at = now()
        RETURNING id INTO v_product_id;

        -- 2. TỰ ĐỘNG ĐỒNG BỘ 3 LOẠI ĐƠN VỊ VÀO BẢNG PRODUCT_UNITS
        
        -- A. TẠO ĐƠN VỊ BASE (HỆ THỐNG TỰ SINH)
        -- Tên = Retail Unit, Rate = 1, Type = 'base', IsBase = True
        IF v_retail_unit IS NOT NULL AND v_retail_unit <> '' THEN
            UPDATE public.product_units 
            SET unit_name = v_retail_unit, 
                price_cost = v_actual_cost, -- Giá vốn base
                updated_at = NOW()
            WHERE product_id = v_product_id AND unit_type = 'base';

            IF NOT FOUND THEN
                INSERT INTO public.product_units (
                    product_id, unit_name, conversion_rate, 
                    is_base, is_direct_sale, 
                    price_cost, price_sell, unit_type
                ) VALUES (
                    v_product_id, v_retail_unit, 1, 
                    true, true, -- Base: true, Direct Sale: true
                    v_actual_cost, 0, 'base'
                );
            END IF;
        END IF;

        -- B. TẠO ĐƠN VỊ RETAIL (TỪ EXCEL)
        -- Tên = Retail Unit, Rate = 1, Type = 'retail', IsBase = False (để phân biệt với dòng base)
        IF v_retail_unit IS NOT NULL AND v_retail_unit <> '' THEN
            UPDATE public.product_units 
            SET unit_name = v_retail_unit, 
                price_cost = v_actual_cost,
                updated_at = NOW()
            WHERE product_id = v_product_id AND unit_type = 'retail';

            IF NOT FOUND THEN
                INSERT INTO public.product_units (
                    product_id, unit_name, conversion_rate, 
                    is_base, is_direct_sale, 
                    price_cost, price_sell, unit_type
                ) VALUES (
                    v_product_id, v_retail_unit, 1, 
                    false, true, -- Base: false
                    v_actual_cost, 0, 'retail'
                );
            END IF;
        END IF;

        -- C. TẠO ĐƠN VỊ WHOLESALE (TỪ EXCEL)
        -- Chỉ tạo nếu có tên và hệ số > 1
        IF v_wholesale_unit IS NOT NULL AND v_wholesale_unit <> '' AND v_conversion_factor > 1 THEN
            UPDATE public.product_units 
            SET unit_name = v_wholesale_unit, 
                conversion_rate = v_conversion_factor,
                price_cost = v_actual_cost * v_conversion_factor, -- Giá vốn sỉ = Vốn base * hệ số
                updated_at = NOW()
            WHERE product_id = v_product_id AND unit_type = 'wholesale';

            IF NOT FOUND THEN
                INSERT INTO public.product_units (
                    product_id, unit_name, conversion_rate, 
                    is_base, is_direct_sale, 
                    price_cost, price_sell, unit_type
                ) VALUES (
                    v_product_id, v_wholesale_unit, v_conversion_factor, 
                    false, true, 
                    v_actual_cost * v_conversion_factor, 0, 'wholesale'
                );
            END IF;
        END IF;

        -- 3. XỬ LÝ TỒN KHO (Giữ nguyên logic)
        v_inventory_settings := product_data->'inventory_settings';
        IF v_inventory_settings IS NOT NULL THEN
            FOR v_branch_key IN SELECT key FROM jsonb_object_keys(v_inventory_settings) AS t(key)
            LOOP
                SELECT id INTO v_warehouse_id FROM public.warehouses WHERE key = v_branch_key;
                IF v_warehouse_id IS NOT NULL THEN
                    INSERT INTO public.product_inventory (product_id, warehouse_id, stock_quantity)
                    VALUES (
                        v_product_id, v_warehouse_id, (v_inventory_settings->>v_branch_key)::INT
                    )
                    ON CONFLICT (product_id, warehouse_id)
                    DO UPDATE SET stock_quantity = EXCLUDED.stock_quantity;
                END IF;
            END LOOP;
        END IF;
        
    END LOOP;
END;
$function$
