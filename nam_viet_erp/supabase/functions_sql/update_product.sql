CREATE OR REPLACE FUNCTION public.update_product(p_id bigint, p_name text DEFAULT NULL::text, p_sku text DEFAULT NULL::text, p_barcode text DEFAULT NULL::text, p_active_ingredient text DEFAULT NULL::text, p_image_url text DEFAULT NULL::text, p_category_name text DEFAULT NULL::text, p_manufacturer_name text DEFAULT NULL::text, p_distributor_id bigint DEFAULT NULL::bigint, p_status text DEFAULT NULL::text, p_invoice_price numeric DEFAULT NULL::numeric, p_actual_cost numeric DEFAULT NULL::numeric, p_wholesale_unit text DEFAULT NULL::text, p_retail_unit text DEFAULT NULL::text, p_conversion_factor integer DEFAULT NULL::integer, p_wholesale_margin_value numeric DEFAULT NULL::numeric, p_wholesale_margin_type text DEFAULT NULL::text, p_retail_margin_value numeric DEFAULT NULL::numeric, p_retail_margin_type text DEFAULT NULL::text, p_items_per_carton integer DEFAULT NULL::integer, p_carton_weight numeric DEFAULT NULL::numeric, p_carton_dimensions text DEFAULT NULL::text, p_purchasing_policy text DEFAULT NULL::text, p_inventory_settings jsonb DEFAULT '{}'::jsonb, p_description text DEFAULT NULL::text, p_registration_number text DEFAULT NULL::text, p_packing_spec text DEFAULT NULL::text, p_updated_by uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    DECLARE
        v_warehouse_key TEXT;
        v_warehouse_id BIGINT;
        v_min_stock INT;
        v_max_stock INT;
        v_user_id UUID;
    BEGIN
        -- 1. Xác định người thực hiện (Ưu tiên tham số truyền vào -> Fallback auth.uid())
        v_user_id := COALESCE(p_updated_by, auth.uid());

        -- 2. Update Bảng Products
        UPDATE public.products
        SET
            name = COALESCE(p_name, name),
            sku = COALESCE(p_sku, sku),
            barcode = COALESCE(p_barcode, barcode),
            active_ingredient = COALESCE(p_active_ingredient, active_ingredient),
            image_url = COALESCE(p_image_url, image_url),
            category_name = COALESCE(p_category_name, category_name),
            manufacturer_name = COALESCE(p_manufacturer_name, manufacturer_name),
            distributor_id = COALESCE(p_distributor_id, distributor_id),
            status = COALESCE(p_status, status),
            invoice_price = COALESCE(p_invoice_price, invoice_price),
            actual_cost = COALESCE(p_actual_cost, actual_cost),
            wholesale_unit = COALESCE(p_wholesale_unit, wholesale_unit),
            retail_unit = COALESCE(p_retail_unit, retail_unit),
            conversion_factor = COALESCE(p_conversion_factor, conversion_factor),
            wholesale_margin_value = COALESCE(p_wholesale_margin_value, wholesale_margin_value),
            wholesale_margin_type = COALESCE(p_wholesale_margin_type, wholesale_margin_type),
            retail_margin_value = COALESCE(p_retail_margin_value, retail_margin_value),
            retail_margin_type = COALESCE(p_retail_margin_type, retail_margin_type),
            items_per_carton = COALESCE(p_items_per_carton, items_per_carton),
            carton_weight = COALESCE(p_carton_weight, carton_weight),
            carton_dimensions = COALESCE(p_carton_dimensions, carton_dimensions),
            purchasing_policy = COALESCE(p_purchasing_policy, purchasing_policy),
            description = COALESCE(p_description, description),
            registration_number = COALESCE(p_registration_number, registration_number),
            packing_spec = COALESCE(p_packing_spec, packing_spec),
            
            updated_at = now(),
            updated_by = v_user_id -- [KEY] Ghi nhận người sửa để Trigger hoạt động
        WHERE id = p_id;

        -- 3. Update Tồn kho Min/Max (Giữ nguyên logic cũ)
        IF p_inventory_settings IS NOT NULL AND p_inventory_settings <> '{}'::jsonb THEN
            DELETE FROM public.product_inventory WHERE product_id = p_id;
            
            FOR v_warehouse_key IN SELECT * FROM jsonb_object_keys(p_inventory_settings)
            LOOP
                SELECT id INTO v_warehouse_id FROM public.warehouses WHERE key = v_warehouse_key;
                IF v_warehouse_id IS NOT NULL THEN
                    v_min_stock := (p_inventory_settings -> v_warehouse_key ->> 'min')::INT;
                    v_max_stock := (p_inventory_settings -> v_warehouse_key ->> 'max')::INT;
                    
                    INSERT INTO public.product_inventory (product_id, warehouse_id, stock_quantity, min_stock, max_stock, updated_by)
                    VALUES (p_id, v_warehouse_id, 0, COALESCE(v_min_stock,0), COALESCE(v_max_stock,0), v_user_id)
                    ON CONFLICT (product_id, warehouse_id) 
                    DO UPDATE SET min_stock = EXCLUDED.min_stock, max_stock = EXCLUDED.max_stock, updated_by = v_user_id;
                END IF;
            END LOOP;
        END IF;
    END;
    $function$
