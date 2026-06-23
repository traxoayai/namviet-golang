CREATE OR REPLACE FUNCTION public.get_purchase_order_details(p_id bigint)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_po RECORD;
    v_items JSON;
BEGIN
    SELECT po.*, s.name as supplier_name 
    INTO v_po 
    FROM public.purchase_orders po
    LEFT JOIN public.suppliers s ON po.supplier_id = s.id
    WHERE po.id = p_id;
    
    IF v_po IS NULL THEN RETURN NULL; END IF;
    
    SELECT json_agg(json_build_object(
        'id', poi.id,
        'product_id', poi.product_id,
        'product_name', prod.name,
        'product_sku', prod.sku,
        'quantity_ordered', poi.quantity_ordered,
        'quantity_received', poi.quantity_received,
        'unit_price', poi.unit_price,
        'unit', poi.unit,
        'total_line', (poi.quantity_ordered * poi.unit_price)
    )) INTO v_items
    FROM public.purchase_order_items poi
    JOIN public.products prod ON poi.product_id = prod.id
    WHERE poi.po_id = p_id;
    
    RETURN json_build_object(
        'po', row_to_json(v_po),
        'items', COALESCE(v_items, '[]'::json)
    );
END;
$function$
