-- ==============================================================================
-- UNIT TEST: upsert_finance_invoice for Outbound direction
-- ==============================================================================

-- 1. Create a mock product and product unit for testing
INSERT INTO products (id, name) 
VALUES (-999, 'Test Product for Outbound VAT') 
ON CONFLICT (id) DO NOTHING;

INSERT INTO product_units (id, product_id, unit_name, conversion_rate) 
VALUES (-999, -999, 'Cái', 1) 
ON CONFLICT (id) DO NOTHING;

-- 2. Call the RPC to upsert an outbound finance invoice with quantity_buyer
DO $$
DECLARE
    v_invoice_data jsonb;
    v_items_data jsonb;
    v_result jsonb;
BEGIN
    v_invoice_data := '{
        "invoice_number": "DRAFT-TEST-OUTBOUND",
        "invoice_symbol": "SP26T",
        "invoice_date": "2026-06-11",
        "supplier_id": null,
        "supplier_tax": null,
        "buyer_name": "Công ty TNHH B2B Bán Ra",
        "buyer_tax_code": "0101234567",
        "buyer_address": "Hà Nội",
        "buyer_email": "b2b@example.com",
        "total_amount": 11000,
        "total_price_excludes_vat": 10000,
        "total_fee_amount": 0,
        "status": "draft",
        "direction": "outbound"
    }'::jsonb;

    v_items_data := '[
        {
            "product_id": -999,
            "product_unit_id": -999,
            "product_name_raw": "Test Product for Outbound VAT",
            "quantity": 10,
            "quantity_buyer": 100,
            "vendor_unit": "Cái",
            "unit_price": 1000,
            "total_amount_pre_vat": 10000,
            "vat_rate": 10,
            "total_amount_with_vat": 11000
        }
    ]'::jsonb;

    -- Call the RPC
    v_result := upsert_finance_invoice(v_invoice_data, v_items_data);

    -- Log output
    RAISE NOTICE 'RPC Result: %', v_result;
END $$;

-- 3. Assertions (Check if data was correctly written)
DO $$
DECLARE
    v_inserted_invoice_id bigint;
    v_buyer_name text;
    v_buyer_tax_code text;
    v_quantity_buyer numeric;
BEGIN
    -- Get the ID of the newly created invoice
    SELECT id, buyer_name, buyer_tax_code
    INTO v_inserted_invoice_id, v_buyer_name, v_buyer_tax_code
    FROM finance_invoices 
    WHERE invoice_number = 'DRAFT-TEST-OUTBOUND' 
    ORDER BY created_at DESC LIMIT 1;

    IF v_inserted_invoice_id IS NULL THEN
        RAISE EXCEPTION 'Test Failed: Invoice not created';
    END IF;

    IF v_buyer_name != 'Công ty TNHH B2B Bán Ra' THEN
        RAISE EXCEPTION 'Test Failed: buyer_name mismatch. Expected: Công ty TNHH B2B Bán Ra, Got: %', v_buyer_name;
    END IF;

    -- Get the inserted item
    SELECT quantity_buyer
    INTO v_quantity_buyer
    FROM finance_invoice_items 
    WHERE invoice_id = v_inserted_invoice_id;

    IF v_quantity_buyer != 100 THEN
        RAISE EXCEPTION 'Test Failed: quantity_buyer mismatch. Expected: 100, Got: %', v_quantity_buyer;
    END IF;

    RAISE NOTICE 'UNIT TEST PASSED: Outbound invoice successfully created with quantity_buyer = 100 and mapped buyer fields.';
END $$;
