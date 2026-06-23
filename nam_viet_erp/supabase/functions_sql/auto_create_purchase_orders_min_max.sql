CREATE OR REPLACE FUNCTION public.auto_create_purchase_orders_min_max()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_b2b_warehouse_id BIGINT;
    v_po_count INTEGER := 0;
    v_new_po_id BIGINT;
    v_supplier_id BIGINT;
    v_supplier_record RECORD;
BEGIN
    -- 1. Tìm ID kho B2B
    SELECT id INTO v_b2b_warehouse_id FROM public.warehouses WHERE key = 'b2b';
    IF v_b2b_warehouse_id IS NULL THEN 
        SELECT id INTO v_b2b_warehouse_id FROM public.warehouses ORDER BY id ASC LIMIT 1;
    END IF;

    IF v_b2b_warehouse_id IS NULL THEN 
        RAISE EXCEPTION 'Hệ thống chưa có kho hàng nào.'; 
    END IF;

    -- Đảm bảo xóa bảng tạm cũ nếu còn sót lại
    DROP TABLE IF EXISTS temp_products_to_buy;

    -- 2. TÍNH TOÁN NHU CẦU THEO CHUẨN ĐỒNG NHẤT BASE UNIT
    CREATE TEMP TABLE temp_products_to_buy AS
    SELECT 
        p.id as product_id,
        p.distributor_id as supplier_id,
        u.unit_name as unit_name,
        u.conversion_rate as conversion_factor,
        
        -- Giá nhập = Giá vốn cơ bản * Hệ số quy đổi
        (COALESCE(p.actual_cost, 0) * u.conversion_rate) as unit_price,
        
        -- [CORE FIX V11]: Tính số lượng cần mua (Wholesale Unit)
        -- Lấy (Max Viên - Tồn Viên) / Hệ số quy đổi -> Ra số Hộp cần mua
        CEIL((inv.max_stock - inv.stock_quantity)::NUMERIC / u.conversion_rate)::INTEGER as quantity_needed

    FROM public.product_inventory inv
    JOIN public.products p ON inv.product_id = p.id
    
    -- Khóa mục tiêu lấy đúng Đơn vị Sỉ (Wholesale)
    JOIN LATERAL (
        SELECT unit_name, conversion_rate
        FROM public.product_units pu
        WHERE pu.product_id = p.id 
          AND pu.unit_type = 'wholesale'
        ORDER BY pu.conversion_rate DESC
        LIMIT 1
    ) u ON true

    WHERE inv.warehouse_id = v_b2b_warehouse_id
      AND p.status = 'active'
      AND p.distributor_id IS NOT NULL
      
      -- Chỉ xét những sản phẩm có cài Min/Max hợp lệ
      AND inv.min_stock > 0 
      AND inv.max_stock > 0
      
      -- [CORE FIX V11]: So sánh trực tiếp theo Base Unit (Viên)
      AND inv.stock_quantity <= inv.min_stock
      
      -- Đảm bảo Max > Hiện tại thì mới mua bù
      AND inv.max_stock > inv.stock_quantity
      
      -- Chặn trùng đơn (Không tạo thêm nếu đã có đơn nháp/đang giao chứa sản phẩm này)
      AND NOT EXISTS (
          SELECT 1 
          FROM public.purchase_order_items poi
          JOIN public.purchase_orders po ON poi.po_id = po.id
          WHERE poi.product_id = p.id
            AND po.delivery_status IN ('draft', 'pending', 'ordered', 'shipping', 'partially_delivered')
      );

    -- 3. LOOP TẠO PO (Gom theo Nhà Cung Cấp)
    FOR v_supplier_record IN SELECT DISTINCT supplier_id FROM temp_products_to_buy
    LOOP
        v_supplier_id := v_supplier_record.supplier_id;

        -- Tạo Header PO (Status = draft)
        INSERT INTO public.purchase_orders (
            code, supplier_id, delivery_status, payment_status, note, created_at, updated_at
        ) VALUES (
            'PO-AUTO-' || to_char(now(), 'YYMMDD') || '-' || v_supplier_id || '-' || floor(random()*1000)::text,
            v_supplier_id, 
            'draft', 
            'unpaid',
            'Đơn dự trù tự động (Dưới mức tồn Min)', 
            now(), now()
        ) RETURNING id INTO v_new_po_id;

        -- Tạo Items cho Đơn hàng
        INSERT INTO public.purchase_order_items (
            po_id, product_id, quantity_ordered, unit_price, unit, uom_ordered, conversion_factor, base_quantity
        )
        SELECT 
            v_new_po_id, product_id, quantity_needed, unit_price, unit_name, unit_name, conversion_factor,
            (quantity_needed * conversion_factor)
        FROM temp_products_to_buy
        WHERE supplier_id = v_supplier_id;

        -- Update Tổng tiền
        UPDATE public.purchase_orders
        SET total_amount = (SELECT COALESCE(SUM(quantity_ordered * unit_price), 0) FROM public.purchase_order_items WHERE po_id = v_new_po_id),
            final_amount = (SELECT COALESCE(SUM(quantity_ordered * unit_price), 0) FROM public.purchase_order_items WHERE po_id = v_new_po_id)
        WHERE id = v_new_po_id;

        v_po_count := v_po_count + 1;
    END LOOP;

    -- Dọn dẹp bảng tạm
    DROP TABLE IF EXISTS temp_products_to_buy;
    
    RETURN v_po_count;
END;
$function$
