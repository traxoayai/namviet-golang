CREATE OR REPLACE FUNCTION public.portal_cart_upsert_delta(p_portal_user_id uuid, p_product_id bigint, p_uom text, p_delta_qty integer, p_unit_price numeric, p_conversion_factor integer, p_max_stock integer DEFAULT NULL::integer)
 RETURNS TABLE(final_qty integer, oversold boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_qty INT;
BEGIN
  IF p_delta_qty IS NULL OR p_delta_qty <= 0 THEN
    RAISE EXCEPTION 'p_delta_qty must be > 0 (got %)', p_delta_qty;
  END IF;

  -- Atomic upsert: nếu row tồn tại → cộng dồn quantity (Postgres giữ row lock
  -- giữa các transaction concurrent nên không bị lost-update). unit_price &
  -- conversion_factor refresh theo giá mới nhất (giữ behavior cũ).
  INSERT INTO public.portal_cart_items (
    portal_user_id, product_id, uom, quantity, unit_price, conversion_factor
  )
  VALUES (
    p_portal_user_id, p_product_id, p_uom, p_delta_qty, p_unit_price, p_conversion_factor
  )
  ON CONFLICT (portal_user_id, product_id, uom)
  DO UPDATE SET
    quantity          = public.portal_cart_items.quantity + EXCLUDED.quantity,
    unit_price        = EXCLUDED.unit_price,
    conversion_factor = EXCLUDED.conversion_factor
  RETURNING quantity INTO v_qty;

  -- Stock guard sau upsert. Trừ ĐÚNG delta của request này (p_delta_qty),
  -- không đụng delta của request song song khác nếu chúng đã insert trước.
  IF p_max_stock IS NOT NULL AND v_qty > p_max_stock THEN
    UPDATE public.portal_cart_items
       SET quantity = public.portal_cart_items.quantity - p_delta_qty
     WHERE portal_user_id = p_portal_user_id
       AND product_id     = p_product_id
       AND uom            = p_uom
    RETURNING quantity INTO v_qty;

    -- Nếu sau revert quantity <= 0 (row chỉ chứa delta của mình) → DELETE
    -- để không vi phạm CHECK (quantity > 0).
    IF v_qty IS NULL OR v_qty <= 0 THEN
      DELETE FROM public.portal_cart_items
       WHERE portal_user_id = p_portal_user_id
         AND product_id     = p_product_id
         AND uom            = p_uom;
      v_qty := 0;
    END IF;

    RETURN QUERY SELECT v_qty, TRUE;
    RETURN;
  END IF;

  RETURN QUERY SELECT v_qty, FALSE;
END;
$function$
