CREATE OR REPLACE FUNCTION public.upsert_product_with_units(p_product_json jsonb, p_units_json jsonb, p_contents_json jsonb DEFAULT NULL::jsonb, p_inventory_json jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_product_id BIGINT;
    v_unit_data JSONB;
    v_kept_unit_ids BIGINT[];
    v_base_cost NUMERIC;      
    v_unit_cost NUMERIC;      
    v_unit_price NUMERIC;     
    v_conversion_rate INT;
    v_anchor_rate NUMERIC := 1; 
    
    v_retail_margin_val NUMERIC;
    v_retail_margin_type TEXT;
    v_wholesale_margin_val NUMERIC;
    v_wholesale_margin_type TEXT;
    v_selected_margin_val NUMERIC;
    v_selected_margin_type TEXT;
    v_inv_data JSONB;
BEGIN
    -- [PHẦN 1: PRODUCT - UPSERT & BẢO VỆ DỮ LIỆU CŨ]
    IF (p_product_json->>'id') IS NOT NULL AND (p_product_json->>'id') <> '' AND (p_product_json->>'id') <> '0' THEN
        v_product_id := (p_product_json->>'id')::BIGINT;
        
        UPDATE public.products
        SET
            -- [CORE FIX TỐI THƯỢNG]: Dùng NULLIF để loại bỏ chuỗi rỗng. Dùng COALESCE để lấy lại data cũ nếu payload thiếu.
            sku = COALESCE(NULLIF(p_product_json->>'sku', ''), sku),
            name = COALESCE(NULLIF(p_product_json->>'name', ''), NULLIF(p_product_json->>'productName', ''), name),
            barcode = COALESCE(NULLIF(p_product_json->>'barcode', ''), barcode),
            registration_number = COALESCE(NULLIF(p_product_json->>'registration_number', ''), NULLIF(p_product_json->>'registrationNumber', ''), registration_number),
            manufacturer_name = COALESCE(NULLIF(p_product_json->>'manufacturer_name', ''), NULLIF(p_product_json->>'manufacturer', ''), manufacturer_name),
            
            distributor_id = CASE 
                WHEN p_product_json ? 'distributor_id' OR p_product_json ? 'distributor' THEN 
                    NULLIF(COALESCE(p_product_json->>'distributor_id', p_product_json->>'distributor'), '')::BIGINT
                ELSE distributor_id 
            END,
            
            category_name = COALESCE(NULLIF(p_product_json->>'category_name', ''), NULLIF(p_product_json->>'category', ''), category_name),
            packing_spec = COALESCE(NULLIF(p_product_json->>'packing_spec', ''), NULLIF(p_product_json->>'packingSpec', ''), packing_spec),
            active_ingredient = COALESCE(NULLIF(p_product_json->>'active_ingredient', ''), NULLIF(p_product_json->>'tags', ''), active_ingredient),
            
            -- [ĐÂY LÀ CHỐT CHẶN CỦA LỖI MẤT ẢNH]
            image_url = COALESCE(
                NULLIF(p_product_json->>'image_url', ''), 
                NULLIF(p_product_json->>'imageUrl', ''), 
                image_url
            ),
            product_images = CASE 
                WHEN p_product_json ? 'product_images' THEN 
                    ARRAY(SELECT jsonb_array_elements_text(COALESCE(p_product_json->'product_images', '[]'::jsonb)))
                ELSE product_images 
            END,
            
            actual_cost = COALESCE((COALESCE(p_product_json->>'actual_cost', p_product_json->>'actualCost'))::NUMERIC, actual_cost),
            wholesale_margin_value = COALESCE((COALESCE(p_product_json->>'wholesale_margin_value', p_product_json->>'wholesaleMarginValue'))::NUMERIC, wholesale_margin_value),
            wholesale_margin_type = COALESCE(NULLIF(p_product_json->>'wholesale_margin_type', ''), NULLIF(p_product_json->>'wholesaleMarginType', ''), wholesale_margin_type),
            retail_margin_value = COALESCE((COALESCE(p_product_json->>'retail_margin_value', p_product_json->>'retailMarginValue'))::NUMERIC, retail_margin_value),
            retail_margin_type = COALESCE(NULLIF(p_product_json->>'retail_margin_type', ''), NULLIF(p_product_json->>'retailMarginType', ''), retail_margin_type),
            
            items_per_carton = COALESCE((COALESCE(p_product_json->>'items_per_carton', p_product_json->>'itemsPerCarton'))::INTEGER, items_per_carton),
            purchasing_policy = COALESCE(NULLIF(p_product_json->>'purchasing_policy', ''), NULLIF(p_product_json->>'purchasingPolicy', ''), purchasing_policy),
            
            updated_at = NOW()
        WHERE id = v_product_id
        RETURNING actual_cost, retail_margin_value, retail_margin_type, wholesale_margin_value, wholesale_margin_type
        INTO v_base_cost, v_retail_margin_val, v_retail_margin_type, v_wholesale_margin_val, v_wholesale_margin_type;
    ELSE
        -- [PHẦN INSERT GIỮ NGUYÊN...]
        INSERT INTO public.products (
            sku, name, barcode, registration_number, manufacturer_name, distributor_id,
            category_name, packing_spec, active_ingredient, status,
            image_url, product_images, actual_cost, wholesale_margin_value, wholesale_margin_type,
            retail_margin_value, retail_margin_type, items_per_carton, purchasing_policy,
            created_at, updated_at
        ) VALUES (
            COALESCE(p_product_json->>'sku', 'SP-' || TO_CHAR(NOW(), 'YYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 1000)::TEXT, 3, '0')),
            COALESCE(p_product_json->>'name', p_product_json->>'productName'), 
            p_product_json->>'barcode', 
            COALESCE(p_product_json->>'registration_number', p_product_json->>'registrationNumber'), 
            COALESCE(p_product_json->>'manufacturer_name', p_product_json->>'manufacturer'),
            CASE 
                WHEN COALESCE(p_product_json->>'distributor_id', p_product_json->>'distributor') IS NOT NULL 
                 AND COALESCE(p_product_json->>'distributor_id', p_product_json->>'distributor') <> '' 
                THEN COALESCE(p_product_json->>'distributor_id', p_product_json->>'distributor')::BIGINT 
                ELSE NULL 
            END,
            COALESCE(p_product_json->>'category_name', p_product_json->>'category'), 
            COALESCE(p_product_json->>'packing_spec', p_product_json->>'packingSpec'), 
            COALESCE(p_product_json->>'active_ingredient', p_product_json->>'tags'),
            'active',
            
            COALESCE(p_product_json->>'image_url', p_product_json->>'imageUrl'),
            ARRAY(SELECT jsonb_array_elements_text(COALESCE(p_product_json->'product_images', '[]'::jsonb))),
            
            COALESCE((COALESCE(p_product_json->>'actual_cost', p_product_json->>'actualCost'))::NUMERIC, 0),
            COALESCE((COALESCE(p_product_json->>'wholesale_margin_value', p_product_json->>'wholesaleMarginValue'))::NUMERIC, 0),
            COALESCE(p_product_json->>'wholesale_margin_type', p_product_json->>'wholesaleMarginType', 'amount'),
            COALESCE((COALESCE(p_product_json->>'retail_margin_value', p_product_json->>'retailMarginValue'))::NUMERIC, 0),
            COALESCE(p_product_json->>'retail_margin_type', p_product_json->>'retailMarginType', 'amount'),
            COALESCE((COALESCE(p_product_json->>'items_per_carton', p_product_json->>'itemsPerCarton'))::INTEGER, 1),
            COALESCE(p_product_json->>'purchasing_policy', p_product_json->>'purchasingPolicy', 'ALLOW_LOOSE'),
            NOW(), NOW()
        ) 
        RETURNING id, actual_cost, retail_margin_value, retail_margin_type, wholesale_margin_value, wholesale_margin_type
        INTO v_product_id, v_base_cost, v_retail_margin_val, v_retail_margin_type, v_wholesale_margin_val, v_wholesale_margin_type;
    END IF;

    -- [PHẦN 2: UNITS - ĐỒNG BỘ GIÁ TỪ FRONTEND XUỐNG]
    SELECT COALESCE(array_agg((x->>'id')::BIGINT), ARRAY[]::BIGINT[]) INTO v_kept_unit_ids
    FROM jsonb_array_elements(p_units_json) x
    WHERE (x->>'id') IS NOT NULL AND (x->>'id') <> '' AND (x->>'id') <> '0';

    DELETE FROM public.product_units WHERE product_id = v_product_id AND id <> ALL(v_kept_unit_ids);

    IF p_units_json IS NOT NULL THEN
        SELECT COALESCE(MAX((x->>'conversion_rate')::NUMERIC), 1) INTO v_anchor_rate
        FROM jsonb_array_elements(p_units_json) x;

        FOR v_unit_data IN SELECT * FROM jsonb_array_elements(p_units_json)
        LOOP
            v_conversion_rate := COALESCE((v_unit_data->>'conversion_rate')::INTEGER, 1);
            v_unit_cost := v_base_cost * v_conversion_rate; 

            IF (v_unit_data->>'unit_type') = 'wholesale' OR (v_unit_data->>'unit_type') = 'logistics' THEN
                v_selected_margin_val := v_wholesale_margin_val;
                v_selected_margin_type := v_wholesale_margin_type;
            ELSE
                v_selected_margin_val := v_retail_margin_val;
                v_selected_margin_type := v_retail_margin_type;
            END IF;

            IF v_selected_margin_type IN ('percent', '%') THEN
                v_unit_price := v_unit_cost * (1 + v_selected_margin_val / 100.0);
            ELSE
                v_unit_price := v_unit_cost + ((v_selected_margin_val / v_anchor_rate) * v_conversion_rate);
            END IF;
            
            v_unit_price := CEIL(v_unit_price / 100.0) * 100;

            IF COALESCE((v_unit_data->>'price')::NUMERIC, 0) > 0 THEN
                v_unit_price := (v_unit_data->>'price')::NUMERIC;
            END IF;

            IF (v_unit_data->>'id') IS NOT NULL AND (v_unit_data->>'id') <> '' AND (v_unit_data->>'id') <> '0' THEN
                UPDATE public.product_units
                SET 
                    unit_name = v_unit_data->>'unit_name',
                    unit_type = COALESCE(v_unit_data->>'unit_type', 'retail'),
                    conversion_rate = v_conversion_rate,
                    price_cost = v_unit_cost, 
                    price_sell = v_unit_price, 
                    price = v_unit_price,      
                    barcode = COALESCE(NULLIF(v_unit_data->>'barcode', ''), barcode), -- Bảo vệ barcode
                    is_base = COALESCE((v_unit_data->>'is_base')::BOOLEAN, false),
                    is_direct_sale = COALESCE((v_unit_data->>'is_direct_sale')::BOOLEAN, true),
                    updated_at = NOW()
                WHERE id = (v_unit_data->>'id')::BIGINT;
            ELSE
                INSERT INTO public.product_units (
                    product_id, unit_name, unit_type, conversion_rate, 
                    price_cost, price_sell, price,
                    barcode, is_base, is_direct_sale, created_at, updated_at
                ) VALUES (
                    v_product_id, v_unit_data->>'unit_name', COALESCE(v_unit_data->>'unit_type', 'retail'), v_conversion_rate,
                    v_unit_cost, v_unit_price, v_unit_price,
                    v_unit_data->>'barcode', COALESCE((v_unit_data->>'is_base')::BOOLEAN, false), COALESCE((v_unit_data->>'is_direct_sale')::BOOLEAN, true), NOW(), NOW()
                );
            END IF;
        END LOOP;
    END IF;

    -- [PHẦN 3 & 4: CONTENT & INVENTORY - Giữ nguyên]
    IF p_contents_json IS NOT NULL THEN
       INSERT INTO public.product_contents (product_id, channel, language_code, description_html, short_description, seo_title, seo_description, seo_keywords, is_published, updated_at)
       VALUES (v_product_id, 'website', 'vi', p_contents_json->>'description_html', p_contents_json->>'short_description', p_contents_json->>'seo_title', p_contents_json->>'seo_description', (SELECT ARRAY(SELECT jsonb_array_elements_text(COALESCE(p_contents_json->'seo_keywords', '[]'::jsonb)))), COALESCE((p_contents_json->>'is_published')::BOOLEAN, true), NOW())
       ON CONFLICT (product_id, channel) DO UPDATE SET description_html = EXCLUDED.description_html, short_description = EXCLUDED.short_description, seo_title = EXCLUDED.seo_title, seo_description = EXCLUDED.seo_description, seo_keywords = EXCLUDED.seo_keywords, updated_at = NOW();
    END IF;

    IF p_inventory_json IS NOT NULL AND jsonb_typeof(p_inventory_json) = 'array' THEN
        FOR v_inv_data IN SELECT * FROM jsonb_array_elements(p_inventory_json)
        LOOP
            IF (v_inv_data->>'warehouse_id') IS NOT NULL THEN
                INSERT INTO public.product_inventory (product_id, warehouse_id, min_stock, max_stock, stock_quantity, updated_at)
                VALUES (v_product_id, (v_inv_data->>'warehouse_id')::BIGINT, (v_inv_data->>'min_stock')::NUMERIC, (v_inv_data->>'max_stock')::NUMERIC, 0, NOW())
                ON CONFLICT (warehouse_id, product_id) DO UPDATE SET min_stock = EXCLUDED.min_stock, max_stock = EXCLUDED.max_stock, updated_at = NOW();
            END IF;
        END LOOP;
    END IF;

    -- [PHẦN 5: PRODUCT REGULATORY - BỘ Y TẾ]
    IF p_product_json ? 'regulatory' AND (p_product_json->'regulatory') IS NOT NULL THEN
        INSERT INTO public.product_regulatory (
            product_id, 
            prescription_class, 
            is_essential, 
            special_control_type, 
            is_vaccine, 
            updated_at
        )
        VALUES (
            v_product_id,
            p_product_json->'regulatory'->>'prescription_class',
            COALESCE((p_product_json->'regulatory'->>'is_essential')::BOOLEAN, false),
            COALESCE(p_product_json->'regulatory'->>'special_control_type', 'none'),
            COALESCE((p_product_json->'regulatory'->>'is_vaccine')::BOOLEAN, false),
            NOW()
        )
        ON CONFLICT (product_id) DO UPDATE SET 
            prescription_class = EXCLUDED.prescription_class,
            is_essential = EXCLUDED.is_essential,
            special_control_type = EXCLUDED.special_control_type,
            is_vaccine = EXCLUDED.is_vaccine,
            updated_at = NOW();
    END IF;

    RETURN jsonb_build_object('success', true, 'product_id', v_product_id);
END;
$function$
