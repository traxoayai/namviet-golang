-- Drop the existing function first
DROP FUNCTION IF EXISTS "public"."get_purchase_orders_master"(integer, integer, text, text, text, text, timestamp with time zone, timestamp with time zone);

CREATE OR REPLACE FUNCTION "public"."get_purchase_orders_master"("p_page" integer, "p_page_size" integer, "p_search" text, "p_status_delivery" text, "p_status_payment" text, "p_status" text DEFAULT NULL::text, "p_date_from" timestamp with time zone DEFAULT NULL::timestamp with time zone, "p_date_to" timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS TABLE("id" bigint, "code" text, "supplier_id" bigint, "supplier_name" text, "delivery_method" text, "shipping_partner_name" text, "delivery_status" text, "payment_status" text, "status" text, "final_amount" numeric, "total_paid" numeric, "total_quantity" numeric, "total_cartons" numeric, "delivery_progress" numeric, "expected_delivery_date" timestamp with time zone, "expected_delivery_time" timestamp with time zone, "created_at" timestamp with time zone, "carrier_name" text, "carrier_contact" text, "carrier_phone" text, "total_packages" integer, "shipping_partner_id" bigint, "shipping_fee" numeric, "shipping_paid" numeric, "full_count" bigint)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  DECLARE
      v_offset INTEGER;
  BEGIN
      v_offset := (p_page - 1) * p_page_size;
  
      RETURN QUERY
      WITH po_metrics AS (
          SELECT
              poi.po_id,
              COALESCE(SUM(poi.quantity_ordered), 0) as _total_qty,
              COALESCE(SUM(poi.quantity_received), 0) as _total_received,
              ROUND(SUM(poi.quantity_ordered::NUMERIC / COALESCE(NULLIF(poi.conversion_factor, 0), 1)), 1) AS _total_cartons
          FROM public.purchase_order_items poi
          GROUP BY poi.po_id
      ),
      base_query AS (
          SELECT
              po.id, po.code, po.supplier_id,
              COALESCE(s.name, 'N/A') as supplier_name,
              po.delivery_method,
              sp.name as shipping_partner_name,
              po.delivery_status, po.payment_status, po.status,
              po.final_amount,
              COALESCE(po.total_paid, 0) as total_paid,
              COALESCE(pm._total_qty, 0)::NUMERIC as total_quantity,
              COALESCE(pm._total_cartons, 0) as total_cartons,
              CASE
                  WHEN COALESCE(pm._total_qty, 0) = 0 THEN 0
                  ELSE ROUND((COALESCE(pm._total_received, 0)::NUMERIC / pm._total_qty) * 100, 0)
              END as delivery_progress,
              po.expected_delivery_date, po.expected_delivery_time, po.created_at,
              po.carrier_name, po.carrier_contact, po.carrier_phone,
              COALESCE(po.total_packages, 0) as total_packages,
              po.shipping_partner_id,
              COALESCE(po.shipping_fee, 0) as shipping_fee,
              COALESCE(ft_shipping.paid, 0) as shipping_paid
          FROM public.purchase_orders po
          LEFT JOIN po_metrics pm ON po.id = pm.po_id
          LEFT JOIN public.suppliers s ON po.supplier_id = s.id
          LEFT JOIN public.shipping_partners sp ON po.shipping_partner_id = sp.id
          LEFT JOIN LATERAL (
              SELECT SUM(amount) as paid
              FROM public.finance_transactions ft
              WHERE ft.ref_type = 'purchase_order' 
                AND ft.ref_id = po.id::text 
                AND ft.partner_type = 'shipping_partner'
                AND ft.status != 'cancelled'
          ) as ft_shipping ON true
          WHERE
              (p_status IS NULL OR p_status = '' OR LOWER(po.status) = LOWER(p_status))
              AND (p_status_delivery IS NULL OR p_status_delivery = '' OR LOWER(po.delivery_status) = LOWER(p_status_delivery))
              AND (p_status_payment IS NULL OR p_status_payment = '' OR LOWER(po.payment_status) = LOWER(p_status_payment))
              AND (p_date_from IS NULL OR po.created_at >= p_date_from)
              AND (p_date_to IS NULL OR po.created_at <= p_date_to)
              AND (
                  p_search IS NULL OR p_search = ''
                  OR po.code ILIKE ('%' || p_search || '%')
                  OR s.name ILIKE ('%' || p_search || '%')
                  OR EXISTS (
                      SELECT 1 FROM public.purchase_order_items poi2
                      JOIN public.products pr ON poi2.product_id = pr.id
                      WHERE poi2.po_id = po.id
                      AND pr.name ILIKE ('%' || p_search || '%')
                  )
              )
      )
      SELECT *, COUNT(*) OVER() as full_count FROM base_query
      ORDER BY created_at DESC
      LIMIT p_page_size OFFSET v_offset;
  END;
  $$;
