CREATE OR REPLACE FUNCTION public.fn_notify_order_status_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_status_label TEXT;
  v_title        TEXT;
  v_body         TEXT;
BEGIN
  -- Chỉ fire khi status thực sự thay đổi
  IF OLD.status IS NOT DISTINCT FROM NEW.status THEN
    RETURN NEW;
  END IF;

  -- Chỉ xử lý đơn B2B (có customer_id)
  IF NEW.customer_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Map status sang label tiếng Việt
  v_status_label := CASE NEW.status
    WHEN 'DRAFT'     THEN 'Nháp'
    WHEN 'PENDING'   THEN 'Chờ xác nhận'
    WHEN 'CONFIRMED' THEN 'Đã xác nhận'
    WHEN 'PACKED'    THEN 'Đã đóng gói'
    WHEN 'SHIPPING'  THEN 'Đang giao hàng'
    WHEN 'DELIVERED' THEN 'Đã giao hàng'
    WHEN 'COMPLETED' THEN 'Hoàn thành'
    WHEN 'CANCELLED' THEN 'Đã hủy'
    ELSE NEW.status
  END;

  v_title := 'Đơn hàng ' || COALESCE(NEW.code, NEW.id::text) || ' — ' || v_status_label;
  v_body  := 'Đơn hàng ' || COALESCE(NEW.code, NEW.id::text)
             || ' đã chuyển sang trạng thái: ' || v_status_label || '.';

  INSERT INTO public.b2b_notifications (
    customer_b2b_id, type, title, body, data
  ) VALUES (
    NEW.customer_id,
    'order_status',
    v_title,
    v_body,
    jsonb_build_object(
      'order_id', NEW.id,
      'order_code', NEW.code,
      'old_status', OLD.status,
      'new_status', NEW.status
    )
  );

  RETURN NEW;
END;
$function$
