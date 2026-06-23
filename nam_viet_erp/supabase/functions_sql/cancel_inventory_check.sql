CREATE OR REPLACE FUNCTION public.cancel_inventory_check(p_check_id bigint, p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    BEGIN
        -- Chỉ hủy được khi đang là DRAFT
        UPDATE public.inventory_checks
        SET 
            status = 'CANCELLED',
            verified_by = p_user_id, -- Người hủy
            completed_at = NOW(),    -- Thời điểm hủy
            updated_at = NOW()
        WHERE id = p_check_id 
          AND status = 'DRAFT';
          
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Phiếu không tồn tại hoặc đã hoàn tất/hủy.';
        END IF;
    END;
    $function$
