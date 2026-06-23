CREATE OR REPLACE FUNCTION public.update_purchase_order_logistics(p_po_id bigint, p_delivery_method text DEFAULT NULL::text, p_shipping_partner_id bigint DEFAULT NULL::bigint, p_shipping_fee numeric DEFAULT NULL::numeric, p_total_packages integer DEFAULT NULL::integer, p_expected_delivery_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_note text DEFAULT NULL::text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    UPDATE public.purchase_orders
    SET
        delivery_method = COALESCE(p_delivery_method, delivery_method),
        shipping_partner_id = COALESCE(p_shipping_partner_id, shipping_partner_id),
        shipping_fee = COALESCE(p_shipping_fee, shipping_fee),
        total_packages = COALESCE(p_total_packages, total_packages),
        expected_delivery_date = COALESCE(p_expected_delivery_date, expected_delivery_date),
        note = COALESCE(p_note, note),
        updated_at = NOW()
    WHERE id = p_po_id;

    RETURN TRUE;
END;
$function$
