import { ParsedInvoiceHeader, ParsedInvoiceItem } from "./xmlParser";

// 1. MỞ RỘNG TYPE TRẢ VỀ: Thêm invoice_source
export const parseGdtJsonInvoice = (
  gdtJson: any
): {
  header: ParsedInvoiceHeader;
  items: ParsedInvoiceItem[];
  raw_data: any;
  direction: "inbound" | "outbound";
  invoice_source: string; // <-- Đã thêm ở đây
} => {
  const direction = gdtJson.direction || "inbound";

  // 2. LẤY INVOICE_SOURCE TỪ DỮ LIỆU CỦA EXTENSION (Mặc định là standard nếu không có)
  const invoiceSource = gdtJson.invoice_source || "standard";

  const header: ParsedInvoiceHeader = {
    invoice_number: String(gdtJson.shdon || ""),
    invoice_symbol: String(gdtJson.khhdon || ""),
    invoice_date: gdtJson.tdlap ? new Date(gdtJson.tdlap).toLocaleDateString("en-CA") : "",
    supplier_name: String(gdtJson.nbten || ""),
    supplier_tax_code: String(gdtJson.nbmst || ""),
    supplier_address: String(gdtJson.nbdchi || ""),
    buyer_name: String(gdtJson.nmten || ""),
    buyer_tax_code: String(gdtJson.nmmst || ""),
    buyer_address: String(gdtJson.nmdchi || ""),
    total_amount_pre_tax: Number(gdtJson.tgtcthue || 0),
    total_discount_commercial: Number(gdtJson.ttcktmai || 0),
    total_tax: Number(gdtJson.tgtthue || 0),
    total_amount_post_tax: Number(gdtJson.tgtttbso || 0),
    tax_breakdowns: [],
  };

  if (Array.isArray(gdtJson.thttltsuat)) {
    header.tax_breakdowns = gdtJson.thttltsuat.map((tb: any) => ({
      vat_rate: tb.tsuat ? parseVatRate(tb.tsuat) : 0,
      total_amount_pre_tax: Number(tb.thtien || 0),
      tax_amount: Number(tb.tthue || 0),
    }));
  }

  const items: ParsedInvoiceItem[] = [];
  if (Array.isArray(gdtJson.hdhhdvu)) {
    gdtJson.hdhhdvu.forEach((item: any, idx: number) => {
      const vatRateStr = item.ltsuat || String(item.tsuat || "");
      const vatRate = parseVatRate(vatRateStr);

      items.push({
        line_number: Number(item.stt || item.sxep || idx + 1),
        supplier_sku: String(item.mhhdvu || ""),
        name: String(item.ten || ""),
        unit: String(item.dvtinh || ""),
        quantity: Number(item.sluong || 0),
        unit_price: Number(item.dgia || 0),
        total: Number(item.thtien || 0),
        vat_rate: vatRate,
        discount_percentage: Number(item.tlckhau || 0),
        discount: Number(item.stckhau || 0),
      });
    });
  }

  // 3. TRẢ VỀ KÈM INVOICE_SOURCE
  return {
    header,
    items,
    raw_data: gdtJson,
    direction,
    invoice_source: invoiceSource,
  };
};

const parseVatRate = (rateStr: string | number): number => {
  if (typeof rateStr === "number") {
    if (rateStr < 1 && rateStr > 0) return Math.round(rateStr * 100);
    return rateStr;
  }
  const str = String(rateStr).toLowerCase();
  if (str.includes("5")) return 5;
  if (str.includes("8")) return 8;
  if (str.includes("10")) return 10;
  return 0;
};
