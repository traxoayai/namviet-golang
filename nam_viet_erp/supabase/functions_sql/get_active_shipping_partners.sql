CREATE OR REPLACE FUNCTION public.get_active_shipping_partners()
 RETURNS TABLE(id bigint, name text, phone text, contact_person text, speed_hours integer, base_fee numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        sp.id, sp.name, sp.phone, sp.contact_person,
        COALESCE((SELECT sr.speed_hours FROM public.shipping_rules sr WHERE sr.partner_id = sp.id LIMIT 1), 24) as speed_hours,
        COALESCE((SELECT sr.fee FROM public.shipping_rules sr WHERE sr.partner_id = sp.id LIMIT 1), 0) as base_fee
    FROM public.shipping_partners sp
    WHERE sp.status = 'active';
END;
$function$
