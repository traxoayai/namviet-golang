CREATE OR REPLACE FUNCTION public.upsert_vendor_product_mapping(p_vendor_tax_code text, p_vendor_product_name text, p_vendor_unit text, p_internal_product_id bigint, p_internal_unit text, p_supplier_sku text DEFAULT NULL::text, p_pre_vat_price numeric DEFAULT NULL::numeric, p_vat_of_supplier numeric DEFAULT NULL::numeric, p_internal_product_unit_id bigint DEFAULT NULL::bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    INSERT INTO public.vendor_product_mappings (
        vendor_tax_code,
        vendor_product_name,
        vendor_unit,
        internal_product_id,
        internal_unit,
        supplier_sku,
        pre_vat_price,
        vat_of_supplier,
        internal_product_unit_id,
        last_used_at,
        updated_by
    )
    VALUES (
        p_vendor_tax_code,
        p_vendor_product_name,
        p_vendor_unit,
        p_internal_product_id,
        p_internal_unit,
        p_supplier_sku,
        p_pre_vat_price,
        p_vat_of_supplier,
        p_internal_product_unit_id,
        now(),
        auth.uid()
    )
    ON CONFLICT (vendor_tax_code, vendor_product_name, vendor_unit)
    DO UPDATE SET
        internal_product_id = EXCLUDED.internal_product_id,
        internal_unit = EXCLUDED.internal_unit,
        supplier_sku = COALESCE(EXCLUDED.supplier_sku, public.vendor_product_mappings.supplier_sku),
        pre_vat_price = COALESCE(EXCLUDED.pre_vat_price, public.vendor_product_mappings.pre_vat_price),
        vat_of_supplier = COALESCE(EXCLUDED.vat_of_supplier, public.vendor_product_mappings.vat_of_supplier),
        internal_product_unit_id = EXCLUDED.internal_product_unit_id,
        last_used_at = now(),
        updated_by = auth.uid();
END;
$function$
