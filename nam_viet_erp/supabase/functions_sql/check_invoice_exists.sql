CREATE OR REPLACE FUNCTION public.check_invoice_exists(p_tax_code text, p_symbol text, p_number text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    BEGIN
        -- Trả về True nếu tìm thấy hóa đơn trùng mà chưa bị reject
        RETURN EXISTS (
            SELECT 1 
            FROM public.finance_invoices
            WHERE supplier_tax_code = p_tax_code
              AND invoice_symbol = p_symbol
              AND invoice_number = p_number
              AND status != 'rejected'
        );
    END;
    $function$
