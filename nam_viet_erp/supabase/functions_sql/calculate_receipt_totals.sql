CREATE OR REPLACE FUNCTION public.calculate_receipt_totals()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    BEGIN
        -- Cập nhật lại tổng tiền hàng trong Header
        UPDATE public.inventory_receipts
        SET 
            total_goods_amount = (
                SELECT COALESCE(SUM(sub_total), 0) 
                FROM public.inventory_receipt_items 
                WHERE receipt_id = COALESCE(NEW.receipt_id, OLD.receipt_id)
            ),
            updated_at = NOW()
        WHERE id = COALESCE(NEW.receipt_id, OLD.receipt_id);
        
        -- Cập nhật Final Amount (Tổng hàng - CK + Ship + Phí)
        UPDATE public.inventory_receipts
        SET final_amount = total_goods_amount - discount_order + shipping_fee + other_fee
        WHERE id = COALESCE(NEW.receipt_id, OLD.receipt_id);

        RETURN NULL;
    END;
    $function$
