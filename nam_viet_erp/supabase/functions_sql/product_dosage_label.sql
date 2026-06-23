CREATE OR REPLACE FUNCTION public.product_dosage_label(spec text)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
DECLARE
  s text := lower(coalesce(spec, ''));
BEGIN
  IF position('viên nén' in s) > 0 THEN RETURN 'Viên nén'; END IF;
  IF position('viên nang cứng' in s) > 0 THEN RETURN 'Viên nang cứng'; END IF;
  IF position('viên nang mềm' in s) > 0 THEN RETURN 'Viên nang mềm'; END IF;
  IF position('viên nang' in s) > 0 THEN RETURN 'Viên nang'; END IF;
  IF position('viên ngậm' in s) > 0 THEN RETURN 'Viên ngậm'; END IF;
  IF position('viên sủi' in s) > 0 THEN RETURN 'Viên sủi'; END IF;
  IF position('dung dịch' in s) > 0 AND position('ống' in s) > 0 THEN RETURN 'Dung dịch'; END IF;
  IF position('chai' in s) > 0 OR position('lọ' in s) > 0 OR position('siro' in s) > 0 OR position('syrup' in s) > 0 THEN RETURN 'Dung dịch'; END IF;
  IF position('gói' in s) > 0 OR position('bột' in s) > 0 OR position('cốm' in s) > 0 THEN RETURN 'Dạng bột'; END IF;
  IF position('kem' in s) > 0 OR position('gel' in s) > 0 OR position('nhũ tương' in s) > 0 THEN RETURN 'Nhũ tương (Gel)'; END IF;
  IF position('xịt' in s) > 0 OR position('phun sương' in s) > 0 THEN RETURN 'Xịt/Phun sương'; END IF;
  IF position('miếng dán' in s) > 0 THEN RETURN 'Miếng dán'; END IF;
  RETURN NULL;
END;
$function$
