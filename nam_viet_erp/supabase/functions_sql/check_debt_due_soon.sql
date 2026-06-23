CREATE OR REPLACE FUNCTION public.check_debt_due_soon()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT DISTINCT d.customer_b2b_id,
           sum(d.remaining_amount) AS total_amount,
           min(d.due_date) AS earliest_due
    FROM b2b_customer_debt_view d
    WHERE d.due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '3 days'
      AND d.remaining_amount > 0
    GROUP BY d.customer_b2b_id
  LOOP
    -- Chi tao 1 thong bao/ngay/khach hang de tranh spam
    IF NOT EXISTS (
      SELECT 1 FROM b2b_notifications
      WHERE customer_b2b_id = r.customer_b2b_id
        AND type = 'debt_reminder'
        AND created_at::date = CURRENT_DATE
    ) THEN
      INSERT INTO b2b_notifications (customer_b2b_id, type, title, body, data)
      VALUES (
        r.customer_b2b_id,
        'debt_reminder',
        'Cong no sap den han: ' || to_char(r.total_amount, 'FM999,999,999') || 'd',
        'Ban co cong no ' || to_char(r.total_amount, 'FM999,999,999') || 'd sap den han ngay ' || to_char(r.earliest_due, 'DD/MM/YYYY') || '.',
        jsonb_build_object('link', '/cong-no')
      );
    END IF;
  END LOOP;
END;
$function$
