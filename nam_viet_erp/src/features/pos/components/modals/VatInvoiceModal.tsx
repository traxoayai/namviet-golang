// src/features/pos/components/modals/VatInvoiceModal.tsx
import { FileExcelOutlined, ThunderboltOutlined, PrinterOutlined,
  SaveOutlined
} from "@ant-design/icons";
import {
  Modal,
  Form,
  Input,
  Table,
  InputNumber,
  Tag,
  Button,
  Space,
  App,
} from "antd";

import React, { useEffect, useState } from "react";
import * as XLSX from "xlsx";

import { safeRpc } from "@/shared/lib/safeRpc";

import { supabase } from "@/shared/lib/supabaseClient";
import { moneyMul, moneyDiv, moneyAdd } from "@/shared/utils/money";
import { printVatDraftInvoice } from "@/shared/utils/printTemplates";
import { invoiceService } from "@/features/finance/api/invoiceService";

export interface OrderItem {
  id: number;
  name: string;
  sku?: string;
  barcode?: string;
  unit?: string;
  qty: number;
  price: number;
  image_url?: string | null;
  code?: string;
}

interface VatItem extends OrderItem {
  conversion_rate?: number;
  product_unit_id?: number;
  max_vat_qty: number;
  vat_qty: number;
  vat_rate: number;
  has_ledger: boolean;
  status: string;
  is_random?: boolean;
  is_allocated?: boolean;
  units?: any[];
}

interface Customer {
  id?: number;
  name?: string;
  buyer_name?: string | null;
  tax_code?: string | null;
  id_card_number?: string | null;
  address?: string | null;
  email?: string | null;
  phone?: string | null;
  payment_method?: string | null;
  customer_type?: "B2B" | "B2C";
}

interface Props {
  visible: boolean;
  onCancel: () => void;
  orderItems: OrderItem[];
  customer?: Customer | null;
  orderId?: string | number | null; // [NEW] Thêm orderId
  isPaid?: boolean;
  onOk?: () => void;
}

export const VatInvoiceModal: React.FC<Props> = ({
  visible,
  onCancel,
  orderItems,
  customer,
  orderId,
  // isPaid,
  onOk,
}) => {
  const { message } = App.useApp();
  const [form] = Form.useForm();
  const [vatItems, setVatItems] = useState<VatItem[]>([]);
  const [sepayLoading, setSepayLoading] = useState(false);
  const [allocating, setAllocating] = useState(false);
  
  const [currentFileUrl, setCurrentFileUrl] = useState<string | null>(null);
  const [currentInvoiceId, setCurrentInvoiceId] = useState<number | null>(null);
  const [isLocked, setIsLocked] = useState(false);

  // 1. Auto-fill khi mở modal
  useEffect(() => {
    if (visible) {
      // Auto-fill customer info nếu có
      if (customer) {
        form.setFieldsValue({
          customer_name: customer.buyer_name || customer.name || "",
          tax_code: customer.tax_code || customer.id_card_number || "",
          address: customer.address || "",
          email: customer.email || "",
        });
      }
      
      // Hàm Load dữ liệu: Hóa đơn cũ (nếu có) + Thông tin Kho VAT + Cập nhật vatItems
      const loadData = async () => {
         let existingInvoice = null;
         const uuidRegex = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
         if (orderId && uuidRegex.test(String(orderId))) {
             const { data } = await supabase
               .from("finance_invoices")
               .select(`
                 id, 
                 status, 
                 file_url,
                 finance_invoice_items (
                    product_id,
                    vendor_product_name,
                    vendor_unit,
                    quantity,
                    quantity_buyer,
                    pre_vat_price,
                    vat_rate,
                    discount_amount,
                    product_unit_id
                 )
               `)
               .eq("order_id", orderId)
               .order("created_at", { ascending: false })
               .limit(1)
               .maybeSingle();
             if (data) existingInvoice = data;
         }

         if (existingInvoice) {
             setCurrentFileUrl(existingInvoice.file_url);
             setIsLocked(existingInvoice.status === "verified_outbound" || existingInvoice.status === "issued_outbound");
         } else {
             setCurrentFileUrl(null);
             setIsLocked(false);
         }

         if (orderItems.length > 0 || existingInvoice) {
            let productIds = orderItems.map((i) => i.id);
            if (existingInvoice && existingInvoice.finance_invoice_items) {
                const invoiceProductIds = existingInvoice.finance_invoice_items.map((i: any) => i.product_id);
                productIds = Array.from(new Set([...productIds, ...invoiceProductIds]));
            }

            if (productIds.length > 0) {
              const { data: ledgerData } = await supabase
                .from("vat_inventory_ledger")
                .select("product_id, vat_rate, quantity_balance")
                .in("product_id", productIds);

              const { data: unitsData } = await supabase
                .from("product_units")
                .select("id, product_id, unit_name, conversion_rate")
                .in("product_id", productIds)
                .order("conversion_rate", { ascending: false });

              const unitsMap: Record<string, any[]> = {};
              if (unitsData) {
                unitsData.forEach(u => {
                  if (u.product_id) {
                    const key = String(u.product_id);
                    if (!unitsMap[key]) unitsMap[key] = [];
                    unitsMap[key].push(u);
                  }
                });
              }

              if (existingInvoice && existingInvoice.finance_invoice_items && existingInvoice.finance_invoice_items.length > 0) {
                  // Fetch product names for fallback
                  const itemProductIds = existingInvoice.finance_invoice_items.map((fi: any) => fi.product_id).filter(Boolean);
                  let productNameMap: Record<number, string> = {};
                  if (itemProductIds.length > 0) {
                    const { data: productData } = await supabase
                      .from("product_inventory")
                      .select("id, name")
                      .in("id", itemProductIds);
                    if (productData) {
                      productData.forEach((p: any) => { productNameMap[p.id] = p.name; });
                    }
                  }

                  // Hiển thị lại đúng những mặt hàng đã lưu nháp hoặc đã xuất
                  const savedItems: VatItem[] = existingInvoice.finance_invoice_items.map((fi: any) => {
                      const foundLedger = ledgerData?.find((l) => l.product_id === fi.product_id);
                      const units = unitsMap[String(fi.product_id)] || [];
                      const myUnit = units.find((u: any) => u.unit_name === fi.vendor_unit) || units[0];
                      const conversionRate = myUnit?.conversion_rate || 1;
                      const orderItem = orderItems.find(oi => oi.id === fi.product_id);

                      return {
                          id: fi.product_id,
                          name: fi.vendor_product_name || orderItem?.name || productNameMap[fi.product_id] || `SP #${fi.product_id}`,
                          unit: fi.vendor_unit,
                          price: fi.pre_vat_price,
                          qty: fi.quantity_buyer || fi.quantity,
                          discount: fi.discount_amount || 0,
                          total_amount: (fi.pre_vat_price * fi.quantity) - (fi.discount_amount || 0),
                          product_unit_id: fi.product_unit_id || myUnit?.id,
                          conversion_rate: conversionRate,
                          vat_rate: fi.vat_rate,
                          vat_qty: fi.quantity, // Lấy theo quantity đã nạp
                          max_vat_qty: foundLedger ? Math.floor(foundLedger.quantity_balance / conversionRate) : 0,
                          has_ledger: !!foundLedger,
                          status: existingInvoice.status,
                          units: units,
                          is_allocated: true
                      } as VatItem;
                  });
                  setVatItems(savedItems);
              } else {
                  // Chưa có hóa đơn VAT: load theo đơn hàng gốc
                  const items: VatItem[] = orderItems.map((oi) => {
                    const found = ledgerData?.find((l) => l.product_id === oi.id);
                    const key = String(oi.id);
                    const myUnit = (unitsMap[key] || []).find((u: any) => u.unit_name === oi.unit);
                    return {
                      ...oi,
                      conversion_rate: myUnit?.conversion_rate,
                      product_unit_id: myUnit?.id,
                      max_vat_qty: found
                        ? Math.floor(found.quantity_balance / (myUnit?.conversion_rate || 1))
                        : 0,
                      vat_qty: oi.qty,
                      vat_rate: found ? found.vat_rate : 8, // Default 8%
                      has_ledger: !!found,
                      status: "processing", // initial
                      units: unitsMap[key] || [],
                    } as VatItem;
                  });
                  setVatItems(items);
              }
            }
         }
      };

      loadData().catch(err => {
        console.error(err);
        message.error("Lỗi kiểm tra kho VAT");
      });
    } else {
      form.resetFields();
      setVatItems([]);
      setCurrentFileUrl(null);
      setIsLocked(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [visible, customer, orderItems, orderId]);

  // 2a. Trừ kho VAT sau khi xuất SEPAY thành công (single atomic RPC)
  const deductVatAfterExport = async (items: VatItem[]) => {
    try {
      const deductItems = items
        .filter((item) => item.vat_qty > 0 && item.has_ledger)
        .map((item) => ({
          product_id: item.id,
          unit: item.unit || "Viên",
          quantity: item.vat_qty,
          vat_rate: item.vat_rate,
        }));

      if (deductItems.length === 0) return;

      await safeRpc("batch_deduct_vat_for_pos", {
        p_items:
          deductItems as unknown as import("@/shared/lib/database.types").Json,
      });
    } catch {
      message.warning("Lỗi trừ kho VAT - vui lòng kiểm tra thủ công");
    }
  };

  const handleQtyChange = (val: number, item: VatItem) => {
    setVatItems(prev => prev.map(i => i.id === item.id ? {...i, vat_qty: val} : i));
  };

  const handleAllocate = async (action: "SWAP_AND_ALLOCATE" | "ALLOCATE_ONLY") => {
    try {
      setAllocating(true);
      
      const targetAmount = orderItems.reduce((sum, item) => sum + (item.price * item.qty), 0);
      
      const payloadItems = vatItems.map(i => ({
        id: i.id,
        name: i.name,
        unit: i.unit,
        qty: i.qty,
        price: i.price
      }));

      const { data, error } = await supabase.rpc("calculate_vat_invoice_allocation" as any, {
        p_customer_id: customer?.id || null,
        p_customer_type: customer?.customer_type || "B2C",
        p_target_amount: targetAmount,
        p_items: payloadItems,
        p_action: action
      });

      if (error) throw error;

      if (Array.isArray(data)) {
         setVatItems(data.map(item => ({
            ...item,
            is_allocated: true,
         })));
         message.success(action === "SWAP_AND_ALLOCATE" ? "Đã thay đổi sản phẩm & phân bổ giá!" : "Đã phân bổ giá!");
      }
    } catch (err: any) {
      console.error(err);
      message.error(err.message || "Lỗi khi phân bổ");
    } finally {
      setAllocating(false);
    }
  };

  // 3. Tính toán tổng tiền
  const totals = vatItems.reduce(
    (acc, item) => {
      const vatDivisor = 1 + item.vat_rate / 100;
      const grossTotalLine = moneyMul(item.price, item.vat_qty);
      const netTotalLine = moneyDiv(grossTotalLine, vatDivisor);
      const taxLine = moneyAdd(grossTotalLine, -netTotalLine);

      return {
        goods: moneyAdd(acc.goods, netTotalLine),
        tax: moneyAdd(acc.tax, taxLine),
        pay: moneyAdd(acc.pay, grossTotalLine),
      };
    },
    { goods: 0, tax: 0, pay: 0 }
  );

  const getPaymentMethodCode = (method: string) => {
    const m = (method || "").toLowerCase();
    if (m.includes("chuyển khoản") || m.includes("bank")) return "2";
    if (m.includes("thẻ") || m.includes("card")) return "4";
    if (m.includes("công nợ") || m.includes("debt")) return "5";
    return "1";
  };

  const handleExportExcel = async () => {
    const invalidItems = vatItems.filter((i) => i.vat_qty > i.max_vat_qty);
    if (invalidItems.length > 0) {
      message.error("Có sản phẩm vượt quá tồn kho VAT cho phép!");
      return;
    }
    const validItems = vatItems.filter((i) => i.vat_qty > 0);
    if (validItems.length === 0) {
      message.warning("Không có sản phẩm nào để xuất!");
      return;
    }

    try {
      const values = form.getFieldsValue();
      const headers = [
        "Mã hóa đơn", "Mã số thuế", "Mã QHNSNN", "Tên đơn vị, tổ chức", "Người mua hàng",
        "Số CCCD/Số hộ chiếu", "Địa chỉ", "Số điện thoại", "Email", "Hình thức thanh toán",
        "Số tài khoản ngân hàng", "Tên ngân hàng", "Tiền chiết khấu", "Ghi chú",
        "Loại hàng hóa", "Tên hàng hóa", "Đơn vị tính", "Số lượng", "Đơn giá",
        "Thành tiền", "VAT", "Tổng tiền hàng", "Tổng tiền thuế", "Tổng tiền thanh toán",
      ];

      const invoiceCode = `HD_${orderItems[0]?.code || Date.now()}`;
      const paymentMethod = getPaymentMethodCode(customer?.payment_method || "cash");

      const excelRows = validItems.map((item, index) => {
        const isBaseRow = index === 0;
        const vatRate = Number(item.vat_rate ?? 0);
        const grossPrice = Number(item.price ?? 0);
        
        const vatPercent = vatRate / 100;
        const netPrice = grossPrice / (1 + vatPercent);
        const netAmount = netPrice * item.vat_qty;

        const buyerName = values.customer_name || "";
        const taxCode = values.tax_code || "";
        const companyName = taxCode.length >= 10 && !taxCode.includes("-") ? values.customer_name : "";

        return [
          invoiceCode, taxCode, "", companyName, buyerName, taxCode, values.address || "",
          customer?.phone || "", values.email || "", isBaseRow ? paymentMethod : "",
          "", "", 0, "", "0", item.name, item.unit || "Cái", item.vat_qty,
          parseFloat(netPrice.toFixed(2)), parseFloat(netAmount.toFixed(2)), String(vatRate),
          isBaseRow ? parseFloat(totals.goods.toFixed(0)) : "",
          isBaseRow ? parseFloat(totals.tax.toFixed(0)) : "",
          isBaseRow ? parseFloat(totals.pay.toFixed(0)) : "",
        ];
      });

      const wb = XLSX.utils.book_new();
      const ws = XLSX.utils.aoa_to_sheet([headers, ...excelRows]);
      XLSX.utils.book_append_sheet(wb, ws, "Danh sách hàng hóa");
      
      const fileName = `VAT_${invoiceCode}_${new Date().toISOString().slice(0, 10)}.xlsx`;
      XLSX.writeFile(wb, fileName);

      await deductVatAfterExport(validItems);
      if (onOk) onOk();
      message.success("Đã xuất file Excel thành công!");
      onCancel();
    } catch (err: unknown) {
      console.error(err);
      message.error("Lỗi tạo file Excel: " + (err instanceof Error ? err.message : ""));
    }
  };

  const handleSepayExport = async (action: "DRAFT" | "VERIFIED") => {
    const noLedgerItems = vatItems.filter((i) => !i.has_ledger);
    if (noLedgerItems.length > 0) {
      message.error("Sản phẩm chưa nhập kho VAT. Không thể xuất hóa đơn.");
      return;
    }
    const validItems = vatItems.filter((i) => i.vat_qty > 0);
    if (validItems.length === 0) {
      message.warning("Không có sản phẩm nào để xuất!");
      return;
    }

    try {
      setSepayLoading(true);
      const isDraft = action === "DRAFT";
      
      let finalOrderId = orderId || (window as any).order?.id || form.getFieldValue("order_id");
      const uuidRegex = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
      if (finalOrderId && !uuidRegex.test(String(finalOrderId))) {
         finalOrderId = undefined;
      }

      const payload = {
        id: currentInvoiceId || undefined,
        order_id: finalOrderId,
        invoice_number: isDraft ? `DRAFT-${Math.floor(Date.now() / 1000)}` : `SEP${Math.floor(Date.now() / 1000)}`,
        invoice_symbol: "SP26T",
        invoice_date: new Date().toISOString().split("T")[0],
        supplier_id: null,
        supplier_tax: null,
        buyer_name: form.getFieldValue("customer_name"),
        buyer_address: form.getFieldValue("address"),
        buyer_tax_code: form.getFieldValue("tax_code"),
        buyer_email: form.getFieldValue("email"),
        total_amount: Math.round(totals.pay),
        total_price_excludes_vat: Math.round(totals.goods),
        total_fee_amount: 0,
        status: isDraft ? "draft" : "verified",
        direction: "outbound"
      };

      const itemsPayload = vatItems.map((item) => {
        const totalAmountWithVat = item.price * item.vat_qty;
        const totalAmountPreVat = totalAmountWithVat / (1 + item.vat_rate / 100);

        return {
          product_id: item.id,
          product_unit_id: item.product_unit_id,
          product_name_raw: item.name,
          quantity: item.vat_qty,
          quantity_buyer: item.qty * (item.conversion_rate || 1),
          vendor_unit: item.unit,
          unit_price: item.price,
          total_amount_pre_vat: Math.round(totalAmountPreVat),
          vat_rate: item.vat_rate,
          total_amount_with_vat: Math.round(totalAmountWithVat)
        };
      });

      const fullPayload = {
        ...payload,
        items_data: itemsPayload
      };

      const result = await invoiceService.createOutboundInvoice(fullPayload, isDraft);
      // `result` is savedInvoice
      if (result && result.id) {
        setCurrentInvoiceId(result.id);
        if (result.file_url) {
          setCurrentFileUrl(result.file_url); // Cập nhật file url vào state
          if (!isDraft) {
            window.open(result.file_url, '_blank');
          }
        } else if (!isDraft) {
          message.info("Hóa đơn đang được xử lý, file PDF sẽ có sau ít phút.");
        }
      }

      message.success(isDraft ? "Đã lưu nháp hóa đơn qua SePay!" : "Đã gửi hóa đơn lên CQT thành công!");
      if (!isDraft) onCancel();
    } catch (err) {
      console.error(err);
      message.error("Lỗi: " + (err instanceof Error ? err.message : "Unknown Error"));
    } finally {
      setSepayLoading(false);
    }
  };

  const handlePrintDraft = () => {
    if (currentFileUrl) {
       window.open(currentFileUrl, "_blank");
       return;
    }

    message.info("Đang khởi tạo lệnh in hóa đơn nháp...");
    
    // Thu thập dữ liệu để in
    const validItems = vatItems.filter((i) => i.vat_qty > 0);
    // const invoiceCode = form.getFieldValue("invoice_symbol") || "VAT-DRAFT";
    const paymentMethod = form.getFieldValue("payment_method") || "TM/CK";

    const totalGoods = validItems.reduce((acc, curr) => {
      const totalAmountWithVat = curr.price * curr.vat_qty;
      const totalAmountPreVat = totalAmountWithVat / (1 + curr.vat_rate / 100);
      return acc + totalAmountPreVat;
    }, 0);

    const totalVat = validItems.reduce((acc, curr) => {
      const totalAmountWithVat = curr.price * curr.vat_qty;
      const totalAmountPreVat = totalAmountWithVat / (1 + curr.vat_rate / 100);
      return acc + (totalAmountWithVat - totalAmountPreVat);
    }, 0);

    const totalPay = totalGoods + totalVat;

    const dataToPrint = {
      customerName: customer?.name || "Khách lẻ",
      taxCode: customer?.tax_code || "",
      address: customer?.address || "",
      email: customer?.email || "",
      phone: customer?.phone || "",
      paymentMethod: paymentMethod,
      items: validItems.map((i, index) => {
        const withVat = i.price * i.vat_qty;
        const preVat = withVat / (1 + i.vat_rate / 100);
        return {
          stt: index + 1,
          name: i.name,
          dispUnit: i.unit,
          dispQty: i.vat_qty,
          netPrice: preVat / i.vat_qty,
          netAmount: preVat,
          vat: i.vat_rate
        };
      }),
      totals: {
        goods: totalGoods,
        tax: totalVat,
        pay: totalPay
      }
    };

    printVatDraftInvoice(dataToPrint);
  };

  const formatMultiUnit = (baseQty: number, units?: any[]) => {
    if (!units || units.length === 0) return baseQty.toString();
    let remaining = baseQty;
    const parts: string[] = [];
    for (const u of units) {
      const qty = Math.floor(remaining / u.conversion_rate);
      if (qty > 0) {
        parts.push(`${qty} ${u.unit_name}`);
        remaining = remaining % u.conversion_rate;
      }
    }
    if (remaining > 0 || parts.length === 0) {
       if (parts.length === 0) parts.push(`${remaining}`);
    }
    return parts.join(" - ");
  };

  const columns = [
    { 
      title: "Sản phẩm", 
      dataIndex: "name",
      render: (name: string, r: VatItem) => (
        <div>
          {name}
          {r.is_random && <Tag color="warning" className="ml-2">Thay thế</Tag>}
          {r.is_allocated && !r.is_random && <Tag color="processing" className="ml-2">Đã phân bổ giá</Tag>}
        </div>
      )
    },
    {
      title: "SL Mua",
      dataIndex: "qty",
      align: "center" as const,
      render: (v: number) => <span className="text-gray-400">{v}</span>,
      width: 100,
    },
    {
      title: "ĐVT",
      dataIndex: "unit",
      align: "center" as const,
      width: 60,
      render: (u: string) => <Tag>{u || "Cái"}</Tag>,
    },
    {
      title: "SL Xuất VAT",
      width: 150,
      render: (_: unknown, r: VatItem) => (
        <div>
          <InputNumber
            min={1}
            value={r.vat_qty}
            size="small"
            onChange={(val) => {
              if (val) handleQtyChange(val, r);
            }}
          />
          <span className="text-gray-500 text-xs mt-1 block">
            Kho: {formatMultiUnit(r.max_vat_qty, r.units)}
            {r.qty > r.max_vat_qty && (
              <span style={{ color: "#ff4d4f", marginLeft: 4 }}>Thiếu</span>
            )}
          </span>
        </div>
      ),
    },
    {
      title: "VAT (%)",
      dataIndex: "vat_rate",
      align: "center" as const,
      render: (v: number) => <Tag color="blue">{v}%</Tag>,
    },

    // [NEW COLUMN] Hiển thị đơn giá Net để User đối chiếu
    {
      title: "Đơn giá (Net)",
      align: "right" as const,
      render: (_: unknown, r: VatItem) => {
        const netPrice = r.price / (1 + r.vat_rate / 100);
        return (
          <div>
            <div className="font-medium">
              {netPrice.toLocaleString(undefined, { maximumFractionDigits: 0 })}
            </div>
            <div className="text-[10px] text-gray-400">
              Giá bán: {r.price.toLocaleString()}
            </div>
          </div>
        );
      },
    },

    {
      title: "Thành tiền (Net)",
      align: "right" as const,
      render: (_: unknown, r: VatItem) => {
        const netPrice = r.price / (1 + r.vat_rate / 100);
        return (netPrice * r.vat_qty).toLocaleString(undefined, {
          maximumFractionDigits: 0,
        });
      },
    },
  ];

  return (
    <Modal
      title={
        <div className="flex items-center gap-2">
          <span className="text-blue-600 font-bold">XUẤT HÓA ĐƠN VAT</span>{" "}
          <Tag color="geekblue">E-Invoice</Tag>
        </div>
      }
      open={visible}
      onCancel={onCancel}
      width={950}
      footer={
        <div className="flex justify-between items-center w-full">
          <Space>
            <Button icon={<PrinterOutlined />} onClick={handlePrintDraft}>
              In HĐ
            </Button>
            <Button 
              icon={<SaveOutlined />} 
              onClick={() => handleSepayExport("DRAFT")}
              loading={sepayLoading}
              disabled={isLocked}
            >
              Lưu nháp
            </Button>
          </Space>
          <Space>
            <Button onClick={onCancel}>Hủy</Button>
            <Button icon={<FileExcelOutlined />} onClick={handleExportExcel}>
              Tải file Excel
            </Button>
            <Button
              type="primary"
              icon={<ThunderboltOutlined />}
              onClick={() => handleSepayExport("VERIFIED")}
              loading={sepayLoading}
              disabled={isLocked}
            >
              Xuất qua SEPAY (E-Invoice)
            </Button>
          </Space>
        </div>
      }
    >
      <Form form={form} layout="vertical" className="mb-4">
        <div className="grid grid-cols-2 gap-4 bg-gray-50 p-4 rounded-lg border border-gray-200">
          <Form.Item
            name="customer_name"
            label={
              <Space>
                Tên Đơn vị / Khách hàng
                {customer?.customer_type === "B2B" && <Tag color="orange" className="ml-2 m-0">Khách B2B</Tag>}
                {customer?.customer_type === "B2C" && <Tag color="green" className="ml-2 m-0">Khách B2C</Tag>}
              </Space>
            }
            rules={[{ required: true }]}
          >
            <Input placeholder="Nhập tên..." />
          </Form.Item>
          <Form.Item
            name="tax_code"
            label="Mã số thuế / CCCD"
            rules={[{ required: true }]}
          >
            <Input placeholder="Nhập MST..." />
          </Form.Item>
          <Form.Item
            name="address"
            label="Địa chỉ xuất hóa đơn"
            className="col-span-2"
            rules={[{ required: true }]}
          >
            <Input />
          </Form.Item>
          <Form.Item
            name="email"
            label="Email nhận hóa đơn"
            className="col-span-2"
          >
            <Input placeholder="khachhang@example.com" />
          </Form.Item>
        </div>
      </Form>

      <div className="flex justify-between items-center mb-2 mt-4">
        <h4 className="font-semibold text-gray-700 m-0">Chi tiết sản phẩm xuất Hóa Đơn</h4>
        <Space>
          <Button 
            loading={allocating} 
            disabled={isLocked}
            onClick={() => handleAllocate("ALLOCATE_ONLY")}
          >
            Phân bổ Giá
          </Button>
          <Button 
            type="primary" 
            ghost 
            loading={allocating} 
            disabled={isLocked}
            onClick={() => handleAllocate("SWAP_AND_ALLOCATE")}
          >
            Thay đổi Sản Phẩm
          </Button>
        </Space>
      </div>

      <Table
        dataSource={vatItems}
        columns={columns}
        pagination={false}
        size="small"
        rowKey="id"
        scroll={{ y: 250 }}
      />

      <div className="flex justify-end mt-4 text-right gap-8 bg-blue-50 p-4 rounded-lg border border-blue-100">
        <div>
          <div className="text-xs text-gray-500">Tổng tiền hàng (Net)</div>
          <div className="font-bold">
            {totals.goods.toLocaleString(undefined, {
              maximumFractionDigits: 0,
            })}
          </div>
        </div>
        <div>
          <div className="text-xs text-gray-500">Tiền thuế GTGT</div>
          <div className="font-bold text-red-600">
            {totals.tax.toLocaleString(undefined, { maximumFractionDigits: 0 })}
          </div>
        </div>
        <div>
          <div className="text-xs text-gray-500">Tổng thanh toán</div>
          <div className="font-bold text-xl text-blue-700">
            {totals.pay.toLocaleString(undefined, { maximumFractionDigits: 0 })}
          </div>
          <div className="text-[10px] text-gray-400">(Khớp giá bán lẻ)</div>
        </div>
      </div>
    </Modal>
  );
};
