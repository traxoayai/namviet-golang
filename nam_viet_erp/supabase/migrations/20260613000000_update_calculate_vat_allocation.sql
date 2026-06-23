CREATE OR REPLACE FUNCTION public.calculate_vat_invoice_allocation(p_customer_id bigint, p_customer_type text, p_target_amount numeric, p_items jsonb, p_action text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_sales_permissions jsonb;
    v_item jsonb;
    v_result jsonb := '[]'::jsonb;
    v_gap numeric := p_target_amount;
    v_current_total numeric := 0;
    
    v_prod_id bigint;
    v_source_qty numeric;
    v_source_price numeric;
    v_source_unit text;
    v_source_conv_rate integer;
    v_base_qty numeric;
    v_base_price numeric;
    
    v_target_unit_type text := CASE WHEN p_customer_type = 'B2B' THEN 'wholesale' ELSE 'retail' END;
    v_target_unit text;
    v_target_conv_rate integer;
    
    v_target_req_qty integer;
    v_target_req_price numeric;
    
    v_base_max_vat_qty numeric;
    v_vat_rate numeric;
    v_base_cost_price numeric;
    v_target_cost_price numeric;
    v_target_max_vat_qty integer;
    
    v_normal_price numeric;
    v_max_price numeric;
    
    v_allocated_qty integer;
    v_allocated_price numeric;
    v_amount_to_add numeric;
    
    v_random_prod record;
    v_is_valid boolean;
    v_allow_rx boolean := false;
    v_rx_class text;
BEGIN
    IF p_customer_type = 'B2B' AND p_customer_id IS NOT NULL THEN
        SELECT sales_permissions INTO v_sales_permissions
        FROM public.customers_b2b
        WHERE id = p_customer_id;
        
        IF v_sales_permissions IS NOT NULL THEN
            IF v_sales_permissions->>'is_rx' = 'true' OR v_sales_permissions->>'allow_rx' = 'true' THEN
                v_allow_rx := true;
            END IF;
        END IF;
    END IF;

    DROP TABLE IF EXISTS tmp_vat_items;
    CREATE TEMP TABLE tmp_vat_items (
        product_id bigint,
        name text,
        unit text,
        original_qty integer,
        vat_qty integer,
        price numeric,
        max_price numeric,
        vat_rate numeric,
        max_vat_qty integer,
        is_random boolean DEFAULT false,
        conversion_rate integer DEFAULT 1
    ) ON COMMIT DROP;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_prod_id := (v_item->>'id')::bigint;
        v_source_qty := (v_item->>'qty')::numeric;
        v_source_price := (v_item->>'price')::numeric;
        v_source_unit := v_item->>'unit';
        
        v_is_valid := true;
        
        IF p_action = 'SWAP_AND_ALLOCATE' AND p_customer_type = 'B2B' THEN
            SELECT prescription_class INTO v_rx_class
            FROM public.product_regulatory
            WHERE product_id = v_prod_id;
            
            IF v_rx_class = 'rx' AND NOT v_allow_rx THEN
                v_is_valid := false;
            END IF;
        END IF;

        IF v_is_valid THEN
            SELECT conversion_rate INTO v_source_conv_rate
            FROM public.product_units
            WHERE product_id = v_prod_id AND unit_name = v_source_unit
            LIMIT 1;
            IF v_source_conv_rate IS NULL THEN v_source_conv_rate := 1; END IF;

            SELECT unit_name, conversion_rate INTO v_target_unit, v_target_conv_rate
            FROM public.product_units
            WHERE product_id = v_prod_id AND unit_type = v_target_unit_type
            ORDER BY conversion_rate DESC LIMIT 1;

            IF v_target_unit IS NULL THEN
                SELECT unit_name, conversion_rate INTO v_target_unit, v_target_conv_rate
                FROM public.product_units
                WHERE product_id = v_prod_id
                ORDER BY conversion_rate ASC LIMIT 1;
            END IF;
            IF v_target_unit IS NULL THEN
                v_target_unit := 'Viên';
                v_target_conv_rate := 1;
            END IF;

            v_base_qty := v_source_qty * v_source_conv_rate;
            v_base_price := CASE WHEN v_source_conv_rate > 0 THEN v_source_price / v_source_conv_rate ELSE v_source_price END;

            v_target_req_qty := FLOOR(v_base_qty / v_target_conv_rate);
            v_target_req_price := v_base_price * v_target_conv_rate;

            SELECT 
                quantity_balance, 
                vat_rate,
                CASE WHEN quantity_balance > 0 THEN total_value_balance / quantity_balance ELSE 0 END
            INTO v_base_max_vat_qty, v_vat_rate, v_base_cost_price
            FROM public.vat_inventory_ledger
            WHERE product_id = v_prod_id;

            IF v_base_max_vat_qty IS NULL THEN v_base_max_vat_qty := 0; END IF;
            IF v_vat_rate IS NULL THEN v_vat_rate := 0; END IF;
            IF v_base_cost_price IS NULL THEN v_base_cost_price := 0; END IF;

            v_target_max_vat_qty := FLOOR(v_base_max_vat_qty / v_target_conv_rate);
            v_target_cost_price := v_base_cost_price * v_target_conv_rate;

            v_allocated_qty := LEAST(v_target_req_qty, v_target_max_vat_qty);
            
            IF v_allocated_qty > 0 THEN
                INSERT INTO tmp_vat_items(product_id, name, unit, original_qty, vat_qty, price, max_price, vat_rate, max_vat_qty, conversion_rate)
                VALUES (
                    v_prod_id, 
                    v_item->>'name', 
                    v_target_unit, 
                    v_target_req_qty, 
                    v_allocated_qty, 
                    v_target_req_price, 
                    v_target_cost_price + (30000 * v_target_conv_rate), 
                    v_vat_rate, 
                    v_target_max_vat_qty,
                    v_target_conv_rate
                );
                
                v_current_total := v_current_total + (v_allocated_qty * v_target_req_price);
            END IF;
        END IF;
    END LOOP;

    v_gap := p_target_amount - v_current_total;

    -- Step 3: Add Random Products FIRST to fill the gap using a normal price (e.g. 10% margin)
    IF v_gap > 0 THEN
        FOR v_random_prod IN 
            SELECT p.id as product_id, p.name, v.quantity_balance, v.vat_rate, 
                   (v.total_value_balance / v.quantity_balance) as base_cost_price
            FROM public.vat_inventory_ledger v
            JOIN public.products p ON p.id = v.product_id
            LEFT JOIN public.product_regulatory pr ON pr.product_id = p.id
            WHERE v.quantity_balance > 0
              AND (p_action != 'SWAP_AND_ALLOCATE' OR p_customer_type != 'B2B' OR v_allow_rx OR pr.prescription_class IS DISTINCT FROM 'rx')
              AND NOT EXISTS (SELECT 1 FROM tmp_vat_items WHERE product_id = p.id)
            ORDER BY random()
        LOOP
            SELECT unit_name, conversion_rate INTO v_target_unit, v_target_conv_rate
            FROM public.product_units
            WHERE product_id = v_random_prod.product_id AND unit_type = v_target_unit_type
            ORDER BY conversion_rate DESC LIMIT 1;

            IF v_target_unit IS NULL THEN
                SELECT unit_name, conversion_rate INTO v_target_unit, v_target_conv_rate
                FROM public.product_units
                WHERE product_id = v_random_prod.product_id
                ORDER BY conversion_rate ASC LIMIT 1;
            END IF;
            IF v_target_unit IS NULL THEN
                v_target_unit := 'Viên';
                v_target_conv_rate := 1;
            END IF;

            v_target_max_vat_qty := FLOOR(v_random_prod.quantity_balance / v_target_conv_rate);
            
            IF v_target_max_vat_qty > 0 THEN
                v_target_cost_price := v_random_prod.base_cost_price * v_target_conv_rate;
                
                -- Use normal price (e.g. cost + 10%)
                v_normal_price := v_target_cost_price * 1.1;
                IF v_normal_price <= 0 THEN v_normal_price := 1000 * v_target_conv_rate; END IF;

                v_max_price := v_target_cost_price + (30000 * v_target_conv_rate);
                
                IF v_gap >= v_normal_price * v_target_max_vat_qty THEN
                    v_allocated_qty := v_target_max_vat_qty;
                    v_allocated_price := v_normal_price;
                ELSE
                    v_allocated_qty := CEIL(v_gap / v_normal_price);
                    v_allocated_price := v_gap / v_allocated_qty;
                END IF;

                INSERT INTO tmp_vat_items(product_id, name, unit, original_qty, vat_qty, price, max_price, vat_rate, max_vat_qty, is_random, conversion_rate)
                VALUES (
                    v_random_prod.product_id, 
                    v_random_prod.name, 
                    v_target_unit, 
                    0,
                    v_allocated_qty, 
                    v_allocated_price, 
                    v_max_price, 
                    v_random_prod.vat_rate, 
                    v_target_max_vat_qty,
                    true,
                    v_target_conv_rate
                );

                v_gap := v_gap - (v_allocated_qty * v_allocated_price);
                EXIT WHEN v_gap <= 0.01;
            END IF;
        END LOOP;
    END IF;

    -- Step 4: Fine-tune Prices (if there's still a gap)
    IF v_gap > 0.01 THEN
        FOR v_random_prod IN SELECT * FROM tmp_vat_items
        LOOP
            v_amount_to_add := LEAST(v_gap, (v_random_prod.max_price - v_random_prod.price) * v_random_prod.vat_qty);
            IF v_amount_to_add > 0 THEN
                UPDATE tmp_vat_items 
                SET price = price + (v_amount_to_add / vat_qty)
                WHERE product_id = v_random_prod.product_id;
                
                v_gap := v_gap - v_amount_to_add;
            END IF;
            EXIT WHEN v_gap <= 0.01;
        END LOOP;
    ELSIF v_gap < -0.01 THEN
        FOR v_random_prod IN SELECT * FROM tmp_vat_items
        LOOP
            v_amount_to_add := LEAST(ABS(v_gap), (v_random_prod.price - 1) * v_random_prod.vat_qty);
            IF v_amount_to_add > 0 THEN
                UPDATE tmp_vat_items 
                SET price = price - (v_amount_to_add / vat_qty)
                WHERE product_id = v_random_prod.product_id;
                
                v_gap := v_gap + v_amount_to_add;
            END IF;
            EXIT WHEN v_gap >= -0.01;
        END LOOP;
    END IF;

    IF v_gap > 0.01 THEN
        RAISE EXCEPTION 'Không đủ tồn kho VAT để phân bổ - Hãy báo lại Kế Toán hoặc Quản Lý Đơn Hàng này';
    END IF;

    SELECT jsonb_agg(jsonb_build_object(
        'id', product_id,
        'name', name,
        'unit', unit,
        'qty', original_qty,
        'vat_qty', vat_qty,
        'price', price,
        'vat_rate', vat_rate,
        'max_vat_qty', max_vat_qty,
        'conversion_rate', conversion_rate,
        'has_ledger', true,
        'status', 'enough',
        'is_random', is_random
    )) INTO v_result
    FROM tmp_vat_items;

    IF v_result IS NULL THEN
        v_result := '[]'::jsonb;
    END IF;

    RETURN v_result;
END;
$function$;
