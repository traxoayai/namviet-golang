CREATE OR REPLACE FUNCTION public.acc_get_or_create_period(p_book text, p_date date)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_id bigint; v_y int := extract(year from p_date); v_m int := extract(month from p_date);
BEGIN
  SELECT id INTO v_id FROM public.accounting_periods WHERE book=p_book AND year=v_y AND month=v_m;
  IF v_id IS NULL THEN
    INSERT INTO public.accounting_periods(book,year,month) VALUES (p_book,v_y,v_m)
    ON CONFLICT (book,year,month) DO UPDATE SET book=EXCLUDED.book RETURNING id INTO v_id;
  END IF;
  RETURN v_id;
END $function$
