CREATE OR REPLACE FUNCTION public.import_product_from_ai(p_data jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_product_id BIGINT;
        v_unit JSONB;
        v_marketing JSONB;
        v_items_per_carton INTEGER := 1; -- Mặc định là 1 nếu không tìm thấy thùng
    BEGIN
        -- 1. TÍNH TOÁN ITEMS_PER_CARTON
        -- Logic: Tìm trong mảng units, nếu có type 'wholesale' (thùng/hộp to) thì lấy rate làm quy cách thùng
        FOR v_unit IN SELECT * FROM jsonb_array_elements(COALESCE(p_data->'units', '[]'::jsonb))
        LOOP
            IF (v_unit->>'unit_type') = 'wholesale' THEN
                v_items_per_carton := COALESCE((v_unit->>'conversion_rate')::INTEGER, 1);
            END IF;
        END LOOP;

        -- 2. INSERT VÀO BẢNG PRODUCTS
        -- Chỉ insert các trường cơ bản và packing_spec, items_per_carton theo yêu cầu
        INSERT INTO public.products (
            name,
            manufacturer_name,
            registration_number,
            barcode,
            active_ingredient,
            usage_instructions,
            packing_spec,       -- [REQ 1] Lấy từ JSON
            items_per_carton,   -- [REQ 2] Đã tính toán ở trên
            
            -- Không có Auto SKU (để NULL hoặc theo JSON nếu có)
            -- Không có Hybrid Sync (retail_unit/wholesale_unit giữ mặc định DB)
            
            status,
            created_at
        )
        VALUES (
            p_data->>'product_name',
            p_data->>'manufacturer_name',
            p_data->>'registration_number',
            p_data->>'barcode',
            (p_data->'active_ingredients'->0->>'name'), 
            COALESCE(p_data->'usage_instructions', '{}'::jsonb),
            p_data->>'packing_spec', 
            v_items_per_carton,
            
            'active',
            NOW()
        )
        RETURNING id INTO v_product_id;

        -- 3. INSERT VÀO BẢNG ĐƠN VỊ (PRODUCT_UNITS)
        FOR v_unit IN SELECT * FROM jsonb_array_elements(COALESCE(p_data->'units', '[]'::jsonb))
        LOOP
            INSERT INTO public.product_units (
                product_id,
                unit_name,
                unit_type,
                conversion_rate,
                is_base_unit,
                price,
                barcode
            )
            VALUES (
                v_product_id,
                v_unit->>'unit_name',
                v_unit->>'unit_type',
                COALESCE((v_unit->>'conversion_rate')::NUMERIC, 1),
                COALESCE((v_unit->>'is_base')::BOOLEAN, false),
                COALESCE((v_unit->>'price')::NUMERIC, 0),
                v_unit->>'barcode'
            );
        END LOOP;

        -- 4. INSERT VÀO BẢNG CONTENT (CÓ KIỂM TRA ĐIỀU KIỆN)
        v_marketing := p_data->'marketing_content';

        -- [REQ 3] Explicitly check if marketing_content exists
        IF v_marketing IS NOT NULL AND v_marketing != 'null'::jsonb THEN
            INSERT INTO public.product_contents (
                product_id,
                channel,
                short_description,
                description_html, 
                seo_title,
                seo_description,
                seo_keywords,
                is_ai_generated,
                is_published
            )
            VALUES (
                v_product_id,
                'website',
                v_marketing->>'short_description',
                v_marketing->>'full_description_html',
                v_marketing->>'seo_title',
                v_marketing->>'seo_description',
                (SELECT array_agg(x) FROM jsonb_array_elements_text(COALESCE(v_marketing->'seo_keywords', '[]'::jsonb)) t(x)),
                TRUE,
                TRUE
            )
            ON CONFLICT (product_id, channel) 
            DO UPDATE SET
                short_description = EXCLUDED.short_description,
                description_html = EXCLUDED.description_html,
                updated_at = NOW();
        END IF;

        RETURN v_product_id;
    END;
    $function$
