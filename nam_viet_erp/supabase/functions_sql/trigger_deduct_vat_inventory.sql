CREATE OR REPLACE FUNCTION public.trigger_deduct_vat_inventory()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    BEGIN
        -- Logic: Chỉ trừ kho khi trạng thái chuyển sang 'issued' hoặc 'verified'
        -- Và trạng thái cũ KHÔNG PHẢI là 'issued'/'verified' (để tránh trừ 2 lần)
        IF NEW.status IN ('issued', 'verified') 
           AND (OLD.status IS NULL OR OLD.status NOT IN ('issued', 'verified')) THEN
            
            PERFORM public.process_sales_invoice_deduction(NEW.id);
            
        END IF;
        RETURN NEW;
    END;
    $function$
