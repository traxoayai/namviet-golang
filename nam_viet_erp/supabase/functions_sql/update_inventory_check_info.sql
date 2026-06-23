CREATE OR REPLACE FUNCTION public.update_inventory_check_info(p_check_id bigint, p_note text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    BEGIN
        UPDATE public.inventory_checks
        SET 
            note = p_note,
            total_actual_value = (
                SELECT COALESCE(SUM(actual_quantity * cost_price), 0)
                FROM public.inventory_check_items WHERE check_id = p_check_id
            ),
            updated_at = NOW()
        WHERE id = p_check_id 
          AND status = 'DRAFT';
    END;
    $function$
