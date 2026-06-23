CREATE OR REPLACE FUNCTION public.get_mapped_product(p_tax_code text, p_product_name text, p_vendor_unit text, p_supplier_sku text DEFAULT NULL::text)
 RETURNS TABLE(internal_product_id bigint, internal_unit text, internal_product_unit_id bigint, conversion_rate numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_internal_id bigint;
    v_internal_unit text;
    v_internal_unit_id bigint;
    v_conversion_rate numeric;
BEGIN
    -- LUỒNG A: Tìm bằng vendor_tax_code + supplier_sku
    IF p_supplier_sku IS NOT NULL AND p_supplier_sku != '' THEN
        SELECT 
            v.internal_product_id,
            v.internal_unit,
            v.internal_product_unit_id,
            COALESCE(pu.conversion_rate, 1::numeric)
        INTO v_internal_id, v_internal_unit, v_internal_unit_id, v_conversion_rate
        FROM public.vendor_product_mappings v
        LEFT JOIN public.product_units pu ON v.internal_product_unit_id = pu.id
        WHERE v.vendor_tax_code = p_tax_code 
          AND v.supplier_sku = p_supplier_sku
        LIMIT 1;
    END IF;

    -- LUỒNG B: Tìm bằng vendor_tax_code + vendor_product_name (Nếu Luồng A thất bại)
    IF v_internal_id IS NULL THEN
        SELECT 
            v.internal_product_id,
            v.internal_unit,
            v.internal_product_unit_id,
            COALESCE(pu.conversion_rate, 1::numeric)
        INTO v_internal_id, v_internal_unit, v_internal_unit_id, v_conversion_rate
        FROM public.vendor_product_mappings v
        LEFT JOIN public.product_units pu ON v.internal_product_unit_id = pu.id
        WHERE v.vendor_tax_code = p_tax_code 
          AND v.vendor_product_name = p_product_name 
          AND (v.vendor_unit = p_vendor_unit OR (v.vendor_unit IS NULL AND p_vendor_unit = ''))
        LIMIT 1;
    END IF;

    -- LUỒNG C: Fuzzy Match qua bảng products (Nếu Luồng B thất bại)
    IF v_internal_id IS NULL AND p_product_name IS NOT NULL AND p_product_name != '' THEN
        SELECT 
            p.id,
            pu.unit_name,
            pu.id,
            pu.conversion_rate
        INTO v_internal_id, v_internal_unit, v_internal_unit_id, v_conversion_rate
        FROM public.products p
        LEFT JOIN public.product_units pu ON p.id = pu.product_id AND pu.unit_type = 'wholesale'
        WHERE p.status = 'active'
        ORDER BY similarity(unaccent(lower(p.name)), unaccent(lower(p_product_name))) DESC
        LIMIT 1;
        -- Ghi chú: Có thể thêm điều kiện sim_score >= 0.3 nếu muốn chặt chẽ hơn.
    END IF;

    -- TRẢ VỀ KẾT QUẢ
    IF v_internal_id IS NOT NULL THEN
        RETURN QUERY SELECT v_internal_id, v_internal_unit, v_internal_unit_id, COALESCE(v_conversion_rate, 1::numeric);
    END IF;
END;
$function$
