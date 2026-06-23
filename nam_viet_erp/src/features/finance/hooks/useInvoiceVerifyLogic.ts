// src/features/finance/hooks/useInvoiceVerifyLogic.ts
import { App, Form } from "antd";
import dayjs from "dayjs";
import { useState, useEffect } from "react";
import { useNavigate, useParams, useLocation } from "react-router-dom";

import { invoiceService } from "../api/invoiceService";
import { calcInvoiceTotals } from "@/shared/utils/money";

import { useProductStore } from "@/features/product/stores/productStore";
import { supabase } from "@/shared/lib/supabaseClient";

export const useInvoiceVerifyLogic = () => {
  const { message } = App.useApp();
  const navigate = useNavigate();
  const { id } = useParams();
  const location = useLocation();
  const [form] = Form.useForm();

  const routerState = location.state;

  // Get returnTo and poId from URL search params as fallback
  const searchParams = new URLSearchParams(location.search);
  const linkedPoId = searchParams.get("poId") || null;
  

  const { suppliers, products, fetchCommonData } = useProductStore();

  const [loading, setLoading] = useState(false);
  const [isReadOnly, setIsReadOnly] = useState(false);
  const [isXmlSource, setIsXmlSource] = useState(false);
  const [xmlRawItems, setXmlRawItems] = useState<any[]>([]);
  const [loadedXmlData, setLoadedXmlData] = useState<any>(null);
  const [invoiceDirection, setInvoiceDirection] = useState<string>("inbound");

  const calculateTotal = (items: any[] = [], totalFeeAmount: number = 0) => calcInvoiceTotals(items, totalFeeAmount);

  // --- ACTIONS ---
  const handleRecalculate = () => {
    const items = form.getFieldValue("items");
    const totalFeeAmount = Number(form.getFieldValue("total_fee_amount")) || 0;
    const totals = calculateTotal(items, totalFeeAmount);
    form.setFieldsValue({ 
      total_price_excludes_vat: totals.totalGoods,
      total_trade_discount: totals.totalDiscount,
      total_amount_pre_tax: totals.totalPreTax,
      tax_amount: totals.totalTax,
      total_amount_post_tax: totals.final 
    });
  };

  const removeRow = (name: number) => {
    const items = form.getFieldValue("items") || [];
    items.splice(name, 1);
    form.setFieldsValue({ items: [...items] });
    setTimeout(() => handleRecalculate(), 0);
  };

  const loadInvoiceFromDB = async (invoiceId: number) => {
    try {
      setLoading(true);
      const rawRecord = await invoiceService.getInvoiceById(invoiceId);
      if (rawRecord) {
        const record = rawRecord as any; // Cast to any to bypass TS missing types
        if (record.direction) setInvoiceDirection(record.direction);
        if (record.status !== "draft" || record.direction === "outbound") setIsReadOnly(true);

        const supplierTax = record.supplier_tax_code || record.parsed_data?.header?.supplier_tax_code;
        
        const rawItems = (record.finance_invoice_items && record.finance_invoice_items.length > 0)
           ? record.finance_invoice_items.map((fi: any) => ({
                product_id: fi.product_id,
                internal_product_unit_id: fi.product_unit_id,
                name: fi.vendor_product_name,
                xml_unit: fi.vendor_unit,
                unit: fi.vendor_unit,
                supplier_sku: fi.supplier_sku,
                quantity: fi.quantity,
                quantity_buyer: fi.quantity_buyer,
                xml_quantity: fi.quantity,
                pre_vat_price: fi.pre_vat_price,
                xml_unit_price: fi.pre_vat_price,
                unit_price: fi.pre_vat_price,
                discount_percentage: fi.discount_percentage,
                discount_rate: fi.discount_percentage,
                discount_amount: fi.discount_amount,
                vat_rate: fi.vat_rate,
                tax_amount: fi.vat_amount,
                vat_amount: fi.vat_amount,
                amount_before_tax: fi.total_amount_pre_vat,
                total_amount_pre_vat: fi.total_amount_pre_vat
           }))
           : (record.items_json as any[]) || [];

        // Map products via getMappedProduct for items loaded from DB
        const mappedItems = await Promise.all(
          rawItems.map(async (item: any, idx: number) => {
            if (record.direction === "outbound") {
              return { ...item, key: idx, internal_unit: item.internal_product_unit_id };
            }

            // If product_id is already mapped, just return it
            if (item.product_id) return { ...item, key: idx, internal_unit: item.internal_product_unit_id };

            // Try auto-mapping
            if (supplierTax && item.name && item.xml_unit) {
              const dbMatch = await invoiceService.getMappedProduct(
                supplierTax,
                item.name,
                item.xml_unit
              );
              
              if (dbMatch) {
                return {
                  ...item,
                  key: idx,
                  product_id: dbMatch.productId,
                  internal_unit: dbMatch.unit,
                  internal_product_unit_id: dbMatch.internal_product_unit_id || null,
                  conversion_rate: dbMatch.conversion_rate || 1,
                  unit_price: Number(item.xml_unit_price || item.unit_price),
                  quantity: Number(item.xml_quantity || item.quantity),
                };
              }
            }
            return { ...item, key: idx };
          })
        );

        form.setFieldsValue({
          invoice_number: record.invoice_number,
          invoice_symbol: record.invoice_symbol,
          invoice_date: record.invoice_date ? dayjs(record.invoice_date) : null,
          supplier_id: record.supplier_id,
          total_amount_post_tax: record.total_amount_post_tax,
          total_price_excludes_vat: record.total_price_excludes_vat,
          total_trade_discount: record.total_trade_discount,
          total_amount_pre_tax: record.total_amount_pre_tax,
          tax_amount: record.tax_amount,
          total_fee_amount: record.total_fee_amount,
          paid_amount: record.paid_amount,
          payment_status: record.payment_status === "PAID" ? "Đã thanh toán" : record.payment_status === "PARTIAL" ? "Thanh toán một phần" : "Chưa thanh toán",
          items: mappedItems.map(item => ({
            ...item,
            expiry_date: item.expiry_date ? dayjs(item.expiry_date) : null,
            xml_unit_price: item.xml_unit_price || item.unit_price,
            xml_quantity: item.xml_quantity || item.quantity,
          })),
        });

        // Restore XML source if parsed_data exists
        if (record.parsed_data) {
          setIsXmlSource(true);
          setXmlRawItems(record.parsed_data.items || []);
          setLoadedXmlData(record.parsed_data);
        }
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const onFinish = async (values: any) => {
    if (isReadOnly) return;
    setLoading(true);

    try {
      // 1. VỆ SINH DỮ LIỆU (DATA SANITIZATION)
      let safeSupplierId = values.supplier_id
        ? Number(values.supplier_id)
        : null;
      if (typeof safeSupplierId === "number" && isNaN(safeSupplierId)) {
        safeSupplierId = null;
      }

      if (!safeSupplierId) {
        message.error("Lỗi: Chưa chọn Nhà Cung Cấp hợp lệ.");
        setLoading(false);
        return;
      }

      // 2. AUTO LEARN MAPPING
      if (isXmlSource) {
        const supplierTax = (
          suppliers.find((s) => s.id === safeSupplierId) as any
        )?.tax_code;
        if (supplierTax) {
          const mappingPromises = values.items.map(
            async (item: any, index: number) => {
              const originalName = xmlRawItems[index]?.name;
              const originalUnit = xmlRawItems[index]?.unit;

              // Ép kiểu ID sản phẩm, nếu lỗi -> 0
              let selectedId = item.product_id ? Number(item.product_id) : 0;
              if (isNaN(selectedId)) selectedId = 0;

              const selectedUnit = item.internal_unit;

              if (originalName && selectedId > 0 && selectedUnit) {
                const supplierSku = xmlRawItems[index]?.supplier_sku;
                const preVatPrice = xmlRawItems[index]?.unit_price;
                const vatRate = xmlRawItems[index]?.vat_rate;
                const internalProductUnitId = item.internal_product_unit_id; // Added from state

                await invoiceService.upsertVendorProductMapping(
                  supplierTax,
                  originalName,
                  originalUnit || null,
                  selectedId,
                  selectedUnit,
                  supplierSku,
                  preVatPrice,
                  vatRate,
                  internalProductUnitId || null
                );
              }
            }
          );
          await Promise.all(mappingPromises);
        }
      }

      // 3. CHUẨN BỊ PAYLOAD (CẬP NHẬT MỚI)
      const totals = calculateTotal(values.items);
      const xmlFileUrl = isXmlSource ? routerState?.xmlData?.fileUrl : null;

      // [FIX] Lấy thông tin Raw từ XML Header
      let parsedDataToSave = null;
      if (isXmlSource) {
          const raw = routerState?.xmlData || loadedXmlData;
          if (raw) {
              const { fileRaw, ...rest } = raw; // Remove fileRaw (File object) which can break JSON.stringify
              parsedDataToSave = rest;
          }
      }
      
      const xmlHeader = parsedDataToSave?.header || {};

      const payload = {
        invoice_number: values.invoice_number || "Unknown",
        invoice_symbol: values.invoice_symbol || "",
        invoice_date: values.invoice_date
          ? dayjs(values.invoice_date).format("YYYY-MM-DD")
          : dayjs().format("YYYY-MM-DD"),
        supplier_id: safeSupplierId,

        file_url: isXmlSource
          ? xmlFileUrl || "no_file_uploaded_error"
          : undefined,

        // [NEW] Bổ sung các trường Raw để hiển thị ngoài danh sách
        supplier_name_raw: xmlHeader.supplier_name || null,
        supplier_tax_code: xmlHeader.supplier_tax_code || null,
        supplier_address_raw: xmlHeader.supplier_address || null,
        parsed_data: parsedDataToSave, // Lưu lại toàn bộ cục JSON XML để sau này debug

        total_price_excludes_vat: totals.totalGoods,
        total_trade_discount: totals.totalDiscount,
        total_fee_amount: Number(values.total_fee_amount) || 0,
        total_amount_pre_tax: totals.totalPreTax,
        tax_amount: totals.totalTax,
        total_amount_post_tax: totals.final,

        items_json: values.items.map((item: any) => {
          let pId = item.product_id ? Number(item.product_id) : null;
          if (typeof pId === "number" && isNaN(pId)) pId = null;

          return {
            ...item,
            product_id: pId,
            internal_product_unit_id: item.internal_unit ? Number(item.internal_unit) : null,
            unit: item.xml_unit || item.unit,
            internal_unit: item.internal_unit || null,
            expiry_date: item.expiry_date
              ? dayjs(item.expiry_date).format("YYYY-MM-DD")
              : null,
            discount_rate: Number(item.discount_rate) || 0,
            discount_amount: Number(item.discount_amount) || 0,
            amount_before_tax: Number(item.amount_before_tax) || 0,
          };
        }),
      };

      // 4. PHÂN LUỒNG: OUTBOUND vs INBOUND
      const direction = routerState?.direction;

      if (direction === "outbound") {
        // --- OUTBOUND: Tạo hóa đơn xuất kho (trừ VAT) ---
        const outboundPayload = {
          invoice_number: payload.invoice_number,
          invoice_symbol: payload.invoice_symbol,
          invoice_date: payload.invoice_date,
          supplier_name_raw: payload.supplier_name_raw,
          buyer_tax_code: values.buyer_tax_code || "",
          total_amount_pre_tax: totals.totalPreTax,
          total_tax: totals.totalTax,
          total_amount_post_tax: totals.final,
          items: (values.items || []).map((item: any) => ({
            product_id: item.product_id ? Number(item.product_id) : null,
            product_name: item.product_name || item.name,
            unit: item.internal_unit || item.unit,
            quantity: Number(item.quantity) || 0,
            unit_price: Number(item.unit_price) || 0,
            vat_rate: Number(item.vat_rate) || 0,
          })),
        };
        await invoiceService.createOutboundInvoice(outboundPayload);
        message.success("Da xuat kho VAT thanh cong!");
        setIsReadOnly(true); // [FIX] Lock buttons after success
      } else {
        // --- INBOUND: Flow cũ (tạo mới / cập nhật) ---
        if (!id || id === "new-xml") {
          // Tạo mới (từ XML hoặc manual) → create draft rồi verify luôn
          const result = await invoiceService.createInvoice(payload);
          const newInvoiceId = (result as any)?.id;

          // Auto-link to PO if poId provided
          if (linkedPoId && newInvoiceId) {
            await supabase.from("finance_invoice_allocations").insert({
              invoice_id: newInvoiceId,
              po_id: Number(linkedPoId),
              allocated_amount: totals.final,
            });
          }

          // Verify ngay (trigger processVatEntry để nhập kho VAT)
          if (newInvoiceId) {
            await invoiceService.verifyInvoice(newInvoiceId, payload);
          }

          message.success("Đã tạo và nhập kho VAT thành công!");
          setIsReadOnly(true); // [FIX] Lock buttons after success
          navigate(`/finance/invoices/verify/${newInvoiceId}`, { replace: true });
          return;
        } else {
          // Update existing invoice
          await invoiceService.verifyInvoice(Number(id), payload);
          message.success("Đã cập nhật hóa đơn!");
          setIsReadOnly(true); // [FIX] Lock buttons after success
        }
      }
    } catch (error: any) {
      console.error(error);
      message.error("Lỗi: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  const onSaveDraft = async (values: any) => {
    if (isReadOnly) {
      message.warning("Hóa đơn đã được xác nhận, không thể lưu nháp.");
      return;
    }
    setLoading(true);
    try {
      const totals = calculateTotal(values.items);
      let safeSupplierId = values.supplier_id
        ? Number(values.supplier_id)
        : null;
      if (typeof safeSupplierId === "number" && isNaN(safeSupplierId))
        safeSupplierId = null;

      let parsedDataToSave = null;
      if (isXmlSource) {
          const raw = routerState?.xmlData || loadedXmlData;
          if (raw) {
              const { fileRaw, ...rest } = raw;
              parsedDataToSave = rest;
          }
      }
      
      const xmlFileUrl = parsedDataToSave?.fileUrl || null;
      const xmlHeader = parsedDataToSave?.header || {};

      const payload = {
        invoice_number: values.invoice_number || "Draft",
        invoice_symbol: values.invoice_symbol || "",
        invoice_date: values.invoice_date
          ? dayjs(values.invoice_date).format("YYYY-MM-DD")
          : dayjs().format("YYYY-MM-DD"),
        supplier_id: safeSupplierId,
        file_url: isXmlSource ? xmlFileUrl || "" : undefined,

        supplier_name_raw: xmlHeader.supplier_name || null,
        supplier_tax_code: xmlHeader.supplier_tax_code || null,
        supplier_address_raw: xmlHeader.supplier_address || null,
        parsed_data: parsedDataToSave,

        total_price_excludes_vat: totals.totalGoods,
        total_trade_discount: totals.totalDiscount,
        total_fee_amount: Number(values.total_fee_amount) || 0,
        total_amount_pre_tax: totals.totalPreTax,
        tax_amount: totals.totalTax,
        total_amount_post_tax: totals.final,

        items_json: values.items.map((item: any) => ({
          ...item,
          product_id: item.product_id ? Number(item.product_id) : null,
          internal_product_unit_id: item.internal_unit ? Number(item.internal_unit) : null,
          unit: item.xml_unit || item.unit,
          expiry_date: item.expiry_date
            ? dayjs(item.expiry_date).format("YYYY-MM-DD")
            : null,
          // Explicitly save these 3 fields for Reload Logic
          xml_quantity: item.xml_quantity,
          xml_unit_price: item.xml_unit_price,
          internal_unit: item.internal_unit || null,
          discount_rate: Number(item.discount_rate) || 0,
          discount_amount: Number(item.discount_amount) || 0,
          amount_before_tax: Number(item.amount_before_tax) || 0,
        })),

        status: "draft", // FORCE STATUS
      };

      const draftResult = await invoiceService.saveDraft(
        id ? Number(id) : null,
        payload
      );

      // Auto-link to PO if poId provided
      if (linkedPoId && draftResult?.id) {
        await supabase
          .from("finance_invoice_allocations")
          .upsert(
            {
              invoice_id: draftResult.id,
              po_id: Number(linkedPoId),
              allocated_amount: totals.final || 0,
            },
            { onConflict: "invoice_id,po_id" }
          )
          .then(() => {});
      }

      message.success("Đã lưu nháp hóa đơn!");
      if (!id || id === "new-xml") {
        navigate(`/finance/invoices/verify/${draftResult?.id}`, { replace: true });
      }
    } catch (error: any) {
      console.error(error);
      message.error("Lỗi lưu nháp: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  // --- INIT EFFECT ---
  useEffect(() => {
    const init = async () => {
      if (suppliers.length === 0 || products.length === 0) {
        await fetchCommonData();
      }

      if (routerState?.source === "xml" && routerState.xmlData) {
        const { header, items } = routerState.xmlData;
        setIsXmlSource(true);
        setXmlRawItems(items);

        const matchedSupplier = suppliers.find(
          (s: any) =>
            s.tax_code?.replace(/\D/g, "") ===
            header.supplier_tax_code?.replace(/\D/g, "")
        );

          form.setFieldsValue({
            invoice_number: header.invoice_number,
            invoice_symbol: header.invoice_symbol,
            invoice_date: header.invoice_date
              ? dayjs(header.invoice_date, ["YYYY-MM-DD", "DD/MM/YYYY"])
              : dayjs(),
            supplier_id: matchedSupplier ? matchedSupplier.id : undefined,
            total_fee_amount: header.total_fee_amount || 0,
            items: items.map((item: any, idx: number) => ({
              key: idx,
              name: item.name,
              xml_unit: item.unit,
              quantity: item.quantity,
              xml_quantity: item.quantity, // [NEW] Base quantity for conversion calc
              unit_price: item.unit_price,
              xml_unit_price: item.unit_price, // [NEW] Base price for scaling
              vat_rate: item.vat_rate,
              discount_rate: item.discount_percentage || item.discount_rate || 0, // Fallback to new percentage
              discount_amount: item.discount || item.discount_amount || 0, // Fallback to XML discount
              amount_before_tax: item.total || item.amount_before_tax || (item.quantity * item.unit_price) - (item.discount || 0),
              product_id: item.internal_product_id
                ? Number(item.internal_product_id)
                : undefined,
              internal_unit: item.internal_unit || undefined,
              internal_product_unit_id: item.internal_product_unit_id || undefined,
              conversion_rate: item.conversion_rate || 1,
              expiry_date: null,
            })),
          });
          setTimeout(() => handleRecalculate(), 0);

      } else if (id || routerState?.data) {
        const dataToLoad = routerState?.data;
        if (dataToLoad) {
          // Logic fillForm cũ (nếu từ AI Scan) - có thể bổ sung sau
        } else await loadInvoiceFromDB(Number(id));
      }
    };
    init();
  }, [id, routerState, suppliers.length, products.length]);

  return {
    form,
    loading,
    isReadOnly,
    isXmlSource,
    xmlRawItems,
    suppliers,
    products,
    navigate,
    onFinish,
    handleRecalculate,
    removeRow,
    onSaveDraft,
    routerState,
    loadedXmlData,
    invoiceDirection,
  };
};
