CREATE OR REPLACE FUNCTION public.import_product_master_v2(p_data jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    item jsonb;
    v_product_id bigint;
    ws_item jsonb;
    
    -- Biến tạm để tính toán
    v_input_cost numeric;
    v_retail_rate integer;
    v_wholesale_rate integer;
    v_max_rate integer;
    v_base_cost numeric;
    
    -- [CORE NEW]: Biến định danh ID chống đúp
    v_base_id bigint;
    v_retail_id bigint;
    v_wholesale_id bigint;
BEGIN
    FOR item IN SELECT * FROM jsonb_array_elements(p_data)
    LOOP
        -- A. TÌM SẢN PHẨM THEO SKU
        SELECT id INTO v_product_id FROM public.products WHERE sku = TRIM(item->>'sku');
        
        IF v_product_id IS NOT NULL THEN
        
            -- [CORE AN TOÀN]: Reset ID để không bị lưu nhầm vòng lặp trước
            v_base_id := NULL;
            v_retail_id := NULL;
            v_wholesale_id := NULL;
        
            -- 1. LẤY & ÉP KIỂU AN TOÀN CÁC BIẾN SỐ ĐỂ TÍNH TOÁN
            v_input_cost := CAST(REPLACE(NULLIF(TRIM(item->>'cost_price'), ''), ',', '.') AS numeric);
            v_retail_rate := COALESCE(CAST(NULLIF(TRIM(item->>'retail_conversion_rate'), '') AS integer), 1);
            v_wholesale_rate := COALESCE(CAST(NULLIF(TRIM(item->>'wholesale_conversion_rate'), '') AS integer), 1);
            
            -- Tính Giá Vốn Cơ Bản (Base Cost)
            v_max_rate := GREATEST(1, v_retail_rate, v_wholesale_rate);
            IF v_input_cost IS NOT NULL THEN
                v_base_cost := v_input_cost / v_max_rate;
            END IF;

            -- B. CẬP NHẬT BẢNG PRODUCTS 
            UPDATE public.products
            SET
                name = COALESCE(NULLIF(TRIM(item->>'name'), ''), name),
                status = COALESCE(NULLIF(TRIM(item->>'status'), ''), status),
                image_url = COALESCE(NULLIF(TRIM(item->>'image_url'), ''), image_url),
                barcode = COALESCE(NULLIF(NULLIF(NULLIF(TRIM(item->>'barcode'), ''), 'N/A'), 'Không có thông tin'), barcode),
                manufacturer_name = COALESCE(NULLIF(NULLIF(NULLIF(TRIM(item->>'manufacturer_name'), ''), 'N/A'), 'Không có thông tin'), manufacturer_name),
                
                actual_cost = COALESCE(v_base_cost, actual_cost), 
                items_per_carton = v_max_rate,
                
                retail_margin_value = COALESCE(CAST(REPLACE(NULLIF(TRIM(item->>'retail_margin_value'), ''), ',', '.') AS numeric), retail_margin_value),
                retail_margin_type = COALESCE(NULLIF(TRIM(item->>'retail_margin_type'), ''), retail_margin_type),
                wholesale_margin_value = COALESCE(CAST(REPLACE(NULLIF(TRIM(item->>'wholesale_margin_value'), ''), ',', '.') AS numeric), wholesale_margin_value),
                wholesale_margin_type = COALESCE(NULLIF(TRIM(item->>'wholesale_margin_type'), ''), wholesale_margin_type),
                
                updated_at = NOW()
            WHERE id = v_product_id;

            -- C. CẬP NHẬT ĐƠN VỊ TÍNH (PRODUCT_UNITS) - [CƠ CHẾ ĐỊNH DANH VÀ QUÉT RÁC]
            
            -- 1. Base Unit (Đơn vị Cơ bản)
            IF NULLIF(TRIM(item->>'base_unit_name'), '') IS NOT NULL THEN
                -- Khóa mục tiêu (Chỉ lấy đúng 1 dòng Base)
                SELECT id INTO v_base_id FROM public.product_units WHERE product_id = v_product_id AND is_base = true LIMIT 1;
                
                IF v_base_id IS NOT NULL THEN
                    UPDATE public.product_units 
                    SET unit_name = TRIM(item->>'base_unit_name'),
                        unit_type = 'base', -- Ép chuẩn type để chống nhầm lẫn sau này
                        price_cost = COALESCE(v_base_cost * 1, price_cost),
                        updated_at = NOW()
                    WHERE id = v_base_id;
                ELSE
                    INSERT INTO public.product_units (product_id, unit_name, unit_type, conversion_rate, is_base, price_cost)
                    VALUES (v_product_id, TRIM(item->>'base_unit_name'), 'base', 1, true, COALESCE(v_base_cost, 0))
                    RETURNING id INTO v_base_id;
                END IF;
                
                -- [QUÉT RÁC]: Xóa bỏ các dòng Base Unit dư thừa bị đúp do lỗi trước đó
                DELETE FROM public.product_units WHERE product_id = v_product_id AND is_base = true AND id != v_base_id;
            END IF;

            -- 2. Retail Unit (Đơn vị Lẻ)
            IF NULLIF(TRIM(item->>'retail_unit_name'), '') IS NOT NULL THEN
                -- Khóa mục tiêu (Tuyệt đối không lấy nhầm dòng Base)
                SELECT id INTO v_retail_id FROM public.product_units WHERE product_id = v_product_id AND unit_type = 'retail' AND (is_base = false OR is_base IS NULL) LIMIT 1;
                
                IF v_retail_id IS NOT NULL THEN
                     UPDATE public.product_units 
                     SET unit_name = TRIM(item->>'retail_unit_name'),
                         conversion_rate = v_retail_rate,
                         price_cost = COALESCE(v_base_cost * v_retail_rate, price_cost), 
                         price_sell = COALESCE(CAST(REPLACE(NULLIF(TRIM(item->>'retail_price'), ''), ',', '.') AS numeric), price_sell),
                         price = COALESCE(CAST(REPLACE(NULLIF(TRIM(item->>'retail_price'), ''), ',', '.') AS numeric), price),
                         updated_at = NOW()
                     WHERE id = v_retail_id;
                ELSE
                     INSERT INTO public.product_units (product_id, unit_name, unit_type, conversion_rate, is_base, price_cost, price_sell, price)
                     VALUES (
                         v_product_id, 
                         TRIM(item->>'retail_unit_name'), 
                         'retail', 
                         v_retail_rate, 
                         false,
                         COALESCE(v_base_cost * v_retail_rate, 0), 
                         COALESCE(CAST(REPLACE(NULLIF(TRIM(item->>'retail_price'), ''), ',', '.') AS numeric), 0),
                         COALESCE(CAST(REPLACE(NULLIF(TRIM(item->>'retail_price'), ''), ',', '.') AS numeric), 0)
                     ) RETURNING id INTO v_retail_id;
                END IF;
                
                -- [QUÉT RÁC]: Xóa bỏ các dòng Retail Unit dư thừa
                DELETE FROM public.product_units WHERE product_id = v_product_id AND unit_type = 'retail' AND (is_base = false OR is_base IS NULL) AND id != v_retail_id;
            END IF;
            
            -- 3. Wholesale Unit (Đơn vị Sỉ)
            IF NULLIF(TRIM(item->>'wholesale_unit_name'), '') IS NOT NULL THEN
                -- Khóa mục tiêu
                SELECT id INTO v_wholesale_id FROM public.product_units WHERE product_id = v_product_id AND unit_type = 'wholesale' AND (is_base = false OR is_base IS NULL) LIMIT 1;
                
                IF v_wholesale_id IS NOT NULL THEN
                     UPDATE public.product_units 
                     SET unit_name = TRIM(item->>'wholesale_unit_name'),
                         conversion_rate = v_wholesale_rate,
                         price_cost = COALESCE(v_base_cost * v_wholesale_rate, price_cost), 
                         price_sell = COALESCE(CAST(REPLACE(NULLIF(TRIM(item->>'wholesale_price'), ''), ',', '.') AS numeric), price_sell),
                         price = COALESCE(CAST(REPLACE(NULLIF(TRIM(item->>'wholesale_price'), ''), ',', '.') AS numeric), price),
                         updated_at = NOW()
                     WHERE id = v_wholesale_id;
                ELSE
                     INSERT INTO public.product_units (product_id, unit_name, unit_type, conversion_rate, is_base, price_cost, price_sell, price)
                     VALUES (
                         v_product_id, 
                         TRIM(item->>'wholesale_unit_name'), 
                         'wholesale', 
                         v_wholesale_rate, 
                         false,
                         COALESCE(v_base_cost * v_wholesale_rate, 0),
                         COALESCE(CAST(REPLACE(NULLIF(TRIM(item->>'wholesale_price'), ''), ',', '.') AS numeric), 0),
                         COALESCE(CAST(REPLACE(NULLIF(TRIM(item->>'wholesale_price'), ''), ',', '.') AS numeric), 0)
                     ) RETURNING id INTO v_wholesale_id;
                END IF;
                
                -- [QUÉT RÁC]: Xóa bỏ các dòng Wholesale Unit dư thừa
                DELETE FROM public.product_units WHERE product_id = v_product_id AND unit_type = 'wholesale' AND (is_base = false OR is_base IS NULL) AND id != v_wholesale_id;
            END IF;

            -- D. UPDATE TỒN KHO MIN/MAX
            IF (item->'warehouse_settings') IS NOT NULL AND jsonb_array_length(item->'warehouse_settings') > 0 THEN
                FOR ws_item IN SELECT * FROM jsonb_array_elements(item->'warehouse_settings')
                LOOP
                    INSERT INTO public.product_inventory (product_id, warehouse_id, min_stock, max_stock, stock_quantity)
                    VALUES (
                        v_product_id, 
                        CAST(NULLIF(TRIM(ws_item->>'warehouse_id'), '') AS bigint), 
                        CAST(NULLIF(TRIM(ws_item->>'min'), '') AS integer), 
                        CAST(NULLIF(TRIM(ws_item->>'max'), '') AS integer),
                        0 
                    )
                    ON CONFLICT (product_id, warehouse_id) 
                    DO UPDATE SET
                        min_stock = COALESCE(CAST(NULLIF(TRIM(ws_item->>'min'), '') AS integer), product_inventory.min_stock),
                        max_stock = COALESCE(CAST(NULLIF(TRIM(ws_item->>'max'), '') AS integer), product_inventory.max_stock),
                        updated_at = NOW();
                END LOOP;
            END IF;

        END IF; 
    END LOOP;
    
    RETURN jsonb_build_object('success', true, 'message', 'Import Dữ liệu Master thành công. Đã dọn sạch các đơn vị tính bị trùng lặp!');
END;
$function$
