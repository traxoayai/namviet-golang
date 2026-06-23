// src/features/finance/utils/xmlParser.ts

export interface ParsedInvoiceItem {
  line_number: number;
  supplier_sku: string; // MHHDVu
  name: string; // THHDVu
  unit: string; // DVTinh
  quantity: number; // SLuong
  unit_price: number; // DGia
  total: number; // ThTien
  vat_rate: number; // TSuat (ví dụ 8, 10, -1 nếu k chịu thuế)
  discount_percentage: number; // TLCKhau
  discount: number; // STCKhau
}

export interface TaxBreakdown {
  vat_rate: number; // TSuat
  total_amount_pre_tax: number; // ThTien
  tax_amount: number; // TThue
}

export interface ParsedInvoiceHeader {
  invoice_number: string; // SHDon
  invoice_symbol: string; // KHHDon
  invoice_date: string; // NLap (YYYY-MM-DD)
  supplier_name: string; // NBan > Ten
  supplier_tax_code: string; // NBan > MST
  supplier_address: string; // NBan > DChi
  buyer_name?: string; // NMua > Ten
  buyer_tax_code?: string; // NMua > MST
  buyer_address?: string; // NMua > DChi
  total_amount_pre_tax: number; // TgTCThue
  total_discount_commercial: number; // TTCKTMai
  total_tax: number; // TgTThue
  total_amount_post_tax: number; // TgTTTBSo
  tax_breakdowns: TaxBreakdown[]; // THTTLTSuat > LTSuat
}

export const parseInvoiceXML = (
  xmlContent: string
): { header: ParsedInvoiceHeader; items: ParsedInvoiceItem[] } => {
  const parser = new DOMParser();
  const xmlDoc = parser.parseFromString(xmlContent, "text/xml");

  // Helper để lấy text từ tag
  const getText = (parent: Element | Document, tag: string) => {
    return parent.querySelector(tag)?.textContent || "";
  };

  // 1. Parse Header
  const dlHdon = xmlDoc.querySelector("DLHDon");
  if (!dlHdon)
    throw new Error(
      "File XML không đúng định dạng Hóa đơn điện tử (Thiếu thẻ DLHDon)."
    );

  const ttChung = dlHdon.querySelector("TTChung");
  const ndHdon = dlHdon.querySelector("NDHDon");
  if (!ttChung || !ndHdon)
    throw new Error("Thiếu thông tin chung hoặc nội dung hóa đơn.");

  const nBan = ndHdon.querySelector("NBan");
  const nMua = ndHdon.querySelector("NMua");
  const tToan = ndHdon.querySelector("TToan");

  // Parse tax breakdowns
  const taxBreakdowns: TaxBreakdown[] = [];
  const ltSuatNodes = tToan?.querySelectorAll("THTTLTSuat LTSuat") || [];
  ltSuatNodes.forEach((node) => {
    const vatStr = getText(node, "TSuat").replace("%", "");
    let vatRate = 0;
    if (!vatStr.startsWith("KCT") && !vatStr.startsWith("KKK")) {
      vatRate = Number(vatStr) || 0;
    }
    taxBreakdowns.push({
      vat_rate: vatRate,
      total_amount_pre_tax: Number(getText(node, "ThTien") || 0),
      tax_amount: Number(getText(node, "TThue") || 0),
    });
  });

  const header: ParsedInvoiceHeader = {
    invoice_number: getText(ttChung, "SHDon"),
    invoice_symbol: getText(ttChung, "KHHDon"),
    invoice_date: getText(ttChung, "NLap"), // Format chuẩn XML thường là YYYY-MM-DD
    supplier_name: getText(nBan!, "Ten"),
    supplier_tax_code: getText(nBan!, "MST"),
    supplier_address: getText(nBan!, "DChi"),
    buyer_name: nMua ? getText(nMua, "Ten") : undefined,
    buyer_tax_code: nMua ? getText(nMua, "MST") : undefined,
    buyer_address: nMua ? getText(nMua, "DChi") : undefined,
    total_amount_pre_tax: Number(getText(tToan!, "TgTCThue") || 0),
    total_discount_commercial: Number(getText(tToan!, "TTCKTMai") || 0),
    total_tax: Number(getText(tToan!, "TgTThue") || 0),
    total_amount_post_tax: Number(getText(tToan!, "TgTTTBSo") || 0),
    tax_breakdowns: taxBreakdowns,
  };

  // 2. Parse Items
  const items: ParsedInvoiceItem[] = [];
  const hhdVuList = ndHdon.querySelectorAll("DSHHDVu HHDVu");

  hhdVuList.forEach((node) => {
    // Xử lý VAT: XML có thể ghi "8%" hoặc "10" hoặc "-1"
    const vatStr = getText(node, "TSuat").replace("%", "");
    let vatRate = 0;
    if (vatStr.startsWith("KCT") || vatStr.startsWith("KKK"))
      vatRate = 0; // Không chịu thuế
    else vatRate = Number(vatStr) || 0;

    items.push({
      line_number: Number(getText(node, "STT")),
      supplier_sku: getText(node, "MHHDVu"),
      name: getText(node, "THHDVu"),
      unit: getText(node, "DVTinh"),
      quantity: Number(getText(node, "SLuong") || 0),
      unit_price: Number(getText(node, "DGia") || 0),
      total: Number(getText(node, "ThTien") || 0),
      discount_percentage: Number(getText(node, "TLCKhau") || 0),
      discount: Number(getText(node, "STCKhau") || 0),
      vat_rate: vatRate,
    });
  });

  return { header, items };
};
