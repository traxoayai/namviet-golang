// src/features/sales/types/b2b.types.ts

// 1. Dá»¯ liá»‡u tá»«ng dÃ²ng Ä‘Æ¡n hÃ ng
export interface B2BOrderItem {
  id: string;
  code: string;
  customer_name: string;
  status:
    | "DRAFT"
    | "QUOTE"
    | "CONFIRMED"
    | "SHIPPING"
    | "DELIVERED"
    | "CANCELLED";
  payment_status: "paid" | "partial" | "unpaid";
  final_amount: number;
  paid_amount: number;
  created_at: string;
}

// 2. Dá»¯ liá»‡u thá»‘ng kÃª (Header)
export interface B2BOrderStats {
  sales_this_month: number;
  draft_count: number;
  pending_payment: number;
}

// 3. Response tá»•ng thá»ƒ tá»« RPC
export interface B2BOrderViewResponse {
  data: B2BOrderItem[];
  total: number;
  stats: B2BOrderStats;
}

// 4. Params filter (Input cho Service)
export interface B2BOrderFilters {
  page: number;
  pageSize: number;
  search?: string;
  status?: string;
  // date_from, date_to náº¿u cáº§n má»Ÿ rá»™ng sau nÃ y
}

// 5. Chi tiáº¿t Ä‘Æ¡n hÃ ng (Detail Page)
export interface B2BOrderDetailItem {
  id: string;
  product_id: string;
  batch_no?: string;
  expiry_date?: string;
  product_name: string;
  product_image?: string;
  quantity: number;
  unit_price: number;
  total_price: number;
  unit_name?: string;
  /** Vá»‹ trÃ­ ká»‡ táº¡i kho xuáº¥t bÃ¡n â€” lookup tá»« product_inventory.shelf_location */
  shelf_location?: string;
}

export interface B2BOrderDetail {
  id: string;
  code: string;
  status: B2BOrderItem["status"];
  created_at: string;
  note?: string;
  payment_method?: "cash" | "credit" | "bank_transfer";
  delivery_method?: "cod" | "standard" | "express";
  delivery_staff_id?: string;

  // ThÃ´ng tin khÃ¡ch hÃ ng (Join)
  customer_id: string;
  customer_name: string;
  customer_phone?: string;
  delivery_address?: string;
  tax_code?: string;
  customer_email?: string;

  // Tá»•ng káº¿t tÃ i chÃ­nh
  sub_total: number;
  discount_amount: number;
  shipping_fee: number;
  final_amount: number;
  paid_amount: number;
  payment_status: "paid" | "partial" | "unpaid";

  // Danh sÃ¡ch sáº£n pháº©m
  items: B2BOrderDetailItem[];

  // ThÃ´ng tin hÃ³a Ä‘Æ¡n VAT
  sales_invoices?: {
    id: number;
    status: "pending" | "processing" | "issued" | "verified";
    invoice_number?: string;
    created_at: string;
  } | null;
  customer_b2b?: any;
}
