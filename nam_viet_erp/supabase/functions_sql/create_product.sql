CREATE OR REPLACE FUNCTION public.create_product(p_name text, p_sku text, p_barcode text, p_active_ingredient text, p_image_url text, p_category_name text, p_manufacturer_name text, p_distributor_id bigint, p_status text, p_invoice_price numeric, p_actual_cost numeric, p_wholesale_unit text, p_retail_unit text, p_conversion_factor integer, p_wholesale_margin_value numeric, p_wholesale_margin_type text, p_retail_margin_value numeric, p_retail_margin_type text, p_items_per_carton integer, p_inventory_settings jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_product_id BIGINT;
    v_warehouse_key TEXT;
    v_warehouse_id BIGINT;
    v_min_stock INT;
    v_max_stock INT;
BEGIN
    -- Insert Sản phẩm
    INSERT INTO public.products (
        name, sku, barcode, active_ingredient, image_url,
        category_name, manufacturer_name, distributor_id, status,
        invoice_price, actual_cost, wholesale_unit, retail_unit, conversion_factor,
        wholesale_margin_value, wholesale_margin_type, retail_margin_value, retail_margin_type,
        items_per_carton -- <-- CẬP NHẬT
    )
    VALUES (
        p_name, p_sku, p_barcode, p_active_ingredient, p_image_url,
        p_category_name, p_manufacturer_name, p_distributor_id, p_status,
        p_invoice_price, p_actual_cost, p_wholesale_unit, p_retail_unit, p_conversion_factor,
        p_wholesale_margin_value, p_wholesale_margin_type, p_retail_margin_value, p_retail_margin_type,
        COALESCE(p_items_per_carton, 1) -- Mặc định là 1
    )
    RETURNING id INTO v_product_id;

    -- Insert Tồn kho Min/Max
    FOR v_warehouse_key IN SELECT * FROM jsonb_object_keys(p_inventory_settings)
    LOOP
        SELECT id INTO v_warehouse_id FROM public.warehouses WHERE key = v_warehouse_key;
        IF v_warehouse_id IS NOT NULL THEN
            v_min_stock := (p_inventory_settings -> v_warehouse_key ->> 'min')::INT;
            v_max_stock := (p_inventory_settings -> v_warehouse_key ->> 'max')::INT;

            INSERT INTO public.product_inventory (product_id, warehouse_id, stock_quantity, min_stock, max_stock)
            VALUES (v_product_id, v_warehouse_id, 0, v_min_stock, v_max_stock);
        END IF;
    END LOOP;

    RETURN v_product_id;
END;
$function$
