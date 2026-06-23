CREATE OR REPLACE FUNCTION public.check_vat_availability(p_product_id bigint, p_vat_rate numeric, p_qty_requested numeric)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_balance NUMERIC;
    BEGIN
        SELECT quantity_balance INTO v_balance
        FROM public.vat_inventory_ledger
        WHERE product_id = p_product_id AND vat_rate = p_vat_rate;
        
        -- Nếu không tìm thấy dòng nào -> Tồn = 0 -> Trả về False (nếu request > 0)
        RETURN COALESCE(v_balance, 0) >= p_qty_requested;
    END;
    $function$
