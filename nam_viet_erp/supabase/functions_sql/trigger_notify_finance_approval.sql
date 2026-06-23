CREATE OR REPLACE FUNCTION public.trigger_notify_finance_approval()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Chỉ báo khi tạo mới và trạng thái là pending
  IF NEW.status = 'pending' THEN
    PERFORM notify_users_by_permission(
      'fin-approve-cash',
      'Yêu cầu duyệt ' || CASE WHEN NEW.flow = 'in' THEN 'Thu' ELSE 'Chi' END,
      'Mã phiếu: ' || NEW.code || ' - Số tiền: ' || to_char(NEW.amount, 'FM999,999,999') || ' đ',
      'warning',
      'expense_approval',
      jsonb_build_object('transaction_id', NEW.id, 'code', NEW.code)
    );
  END IF;
  RETURN NEW;
END;
$function$
