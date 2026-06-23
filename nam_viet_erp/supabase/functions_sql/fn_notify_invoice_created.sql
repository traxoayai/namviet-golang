CREATE OR REPLACE FUNCTION public.fn_notify_invoice_created()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_title TEXT;
  v_body  TEXT;
BEGIN
  -- Chỉ xử lý hóa đơn B2B (có customer_id)
  IF NEW.customer_id IS NULL THEN
    RETURN NEW;
  END IF;

  v_title := 'Hóa đơn mới: ' || COALESCE(NEW.invoice_number, 'HĐ-' || NEW.id::text);
  v_body  := 'Hóa đơn ' || COALESCE(NEW.invoice_number, 'HĐ-' || NEW.id::text)
             || ' đã được tạo với tổng tiền '
             || COALESCE(to_char(NEW.final_amount, 'FM999,999,999,999'), '0') || ' đ.';

  INSERT INTO public.b2b_notifications (
    customer_b2b_id, type, title, body, data
  ) VALUES (
    NEW.customer_id,
    'invoice',
    v_title,
    v_body,
    jsonb_build_object(
      'invoice_id', NEW.id,
      'invoice_number', NEW.invoice_number,
      'final_amount', NEW.final_amount,
      'order_id', NEW.order_id
    )
  );

  RETURN NEW;
END;
$function$
