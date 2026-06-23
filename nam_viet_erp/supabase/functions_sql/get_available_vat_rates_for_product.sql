CREATE OR REPLACE FUNCTION public.get_available_vat_rates_for_product(p_product_id bigint)
 RETURNS TABLE(vat_rate numeric, quantity_base numeric, unit_base text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        l.vat_rate,
        l.quantity_balance,
        p.retail_unit -- Lấy tên đơn vị lẻ để hiển thị
    FROM public.vat_inventory_ledger l
    JOIN public.products p ON l.product_id = p.id
    WHERE l.product_id = p_product_id AND l.quantity_balance > 0
    ORDER BY l.vat_rate DESC;
END;
$function$
