CREATE OR REPLACE FUNCTION public.trigger_notify_warehouse_po()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Nếu đơn hàng chuyển sang 'pending' (Đã gửi NCC, chờ nhập)
  -- Hoặc tạo mới ở trạng thái pending
  IF NEW.delivery_status = 'pending' AND (OLD.delivery_status IS NULL OR OLD.delivery_status != 'pending') THEN
    PERFORM notify_users_by_permission(
      'inv-stock-view',
      'Đơn mua hàng mới',
      'Đơn PO ' || NEW.code || ' đang chờ nhập kho. Vui lòng kiểm tra.',
      'info',
      'purchase_order',
      jsonb_build_object('po_id', NEW.id, 'po_code', NEW.code)
    );
  END IF;
  RETURN NEW;
END;
$function$
