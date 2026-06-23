-- 1. Bảng lưu trữ chi tiết dòng hóa đơn
CREATE TABLE IF NOT EXISTS public.finance_invoice_items (
    id bigserial primary key,
    invoice_id bigint references public.finance_invoices(id) on delete cascade not null,
    product_id bigint references public.products(id) on delete restrict,
    product_unit_id bigint references public.product_units(id) on delete restrict,
    vendor_product_name text,
    vendor_unit text,
    supplier_sku text,
    quantity numeric default 0,
    pre_vat_price numeric default 0,
    discount_percentage numeric default 0,
    discount_amount numeric default 0,
    vat_rate numeric default 0,
    vat_amount numeric default 0,
    total_amount_pre_vat numeric default 0,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- 2. Cập nhật RPC get_mapped_product để trả về conversion_rate
DROP FUNCTION IF EXISTS public.get_mapped_product(text, text, text);

CREATE OR REPLACE FUNCTION public.get_mapped_product(p_tax_code text, p_product_name text, p_vendor_unit text)
 RETURNS TABLE(internal_product_id bigint, internal_unit text, internal_product_unit_id bigint, conversion_rate numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        v.internal_product_id,
        v.internal_unit,
        v.internal_product_unit_id,
        COALESCE(pu.conversion_rate, 1::numeric) as conversion_rate
    FROM public.vendor_product_mappings v
    LEFT JOIN public.product_units pu ON v.internal_product_unit_id = pu.id
    WHERE v.vendor_tax_code = p_tax_code 
      AND v.vendor_product_name = p_product_name 
      AND (v.vendor_unit = p_vendor_unit OR (v.vendor_unit IS NULL AND p_vendor_unit = ''))
    LIMIT 1;
END;
$function$;

-- 3. Cập nhật RPC upsert_vendor_product_mapping để nhận thêm trường mới
DROP FUNCTION IF EXISTS public.upsert_vendor_product_mapping;

CREATE OR REPLACE FUNCTION public.upsert_vendor_product_mapping(
    p_vendor_tax_code text,
    p_vendor_product_name text,
    p_vendor_unit text,
    p_internal_product_id bigint,
    p_internal_unit text,
    p_supplier_sku text DEFAULT NULL,
    p_pre_vat_price numeric DEFAULT NULL,
    p_vat_of_supplier numeric DEFAULT NULL,
    p_internal_product_unit_id bigint DEFAULT NULL
)
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
$function$;
