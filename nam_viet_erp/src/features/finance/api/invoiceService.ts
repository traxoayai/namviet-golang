// src/services/invoiceService.ts
import { v4 as uuidv4 } from "uuid";

import { safeRpc } from "@/shared/lib/safeRpc";
import { supabase } from "@/shared/lib/supabaseClient";

interface InvoiceFilters {
  status?: string;
  search?: string;
  dateFrom?: string;
  dateTo?: string;
  direction?: string;
}

type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

interface InvoicePayload {
  invoice_number?: string;
  invoice_symbol?: string;
  invoice_date?: string | null;
  supplier_name_raw?: string;
  supplier_tax_code?: string;
  buyer_tax_code?: string;
  total_amount_pre_tax?: number;
  tax_amount?: number;
  total_amount_post_tax?: number;
  total_tax?: number;
  raw_items?: Json;
  items?: Json;
  [key: string]: Json | undefined;
}

export const invoiceService = {
  // 1. Upload ảnh lên Bucket 'invoices'
  async uploadInvoiceImage(file: File) {
    const fileExt = file.name.split(".").pop();
    const fileName = `${uuidv4()}.${fileExt}`;
    const filePath = `raw/${fileName}`;

    const { error } = await supabase.storage
      .from("invoices")
      .upload(filePath, file);

    if (error) throw error;

    const { data } = supabase.storage.from("invoices").getPublicUrl(filePath);
    return data.publicUrl;
  },

  // 2. Gọi AI Scan (FIXED: Simple Object Body)
  // mode='extract_only' → backend không insert/update finance_invoices, chỉ
  // trả parsed_data. Dùng cho flow nhập kho từ phiếu xuất NCC để auto-fill
  // lot/expiry mà không tạo VAT invoice rác.
  async scanInvoiceWithAI(
    fileUrl: string,
    mimeType: string = "image/jpeg",
    options?: { mode?: "invoice" | "extract_only" }
  ) {
    console.log("[Frontend] Calling AI Scan (Clean Object)...", {
      fileUrl,
      mimeType,
      mode: options?.mode,
    });

    const { data, error } = await supabase.functions.invoke(
      "scan-invoice-gemini",
      {
        // FIX: Truyền Object trực tiếp, KHÔNG stringify, KHÔNG header thủ công.
        // SDK sẽ tự động xử lý tất cả.
        body: {
          file_url: fileUrl,
          mime_type: mimeType,
          mode: options?.mode,
        },
      }
    );

    if (error) {
      console.error("Edge Function Error Detail:", error);

      // --- CẬP NHẬT MỚI: Xử lý lỗi 409 (Trùng lặp) ---
      // Supabase Functions trả về lỗi trong object `error` hoặc `context`
      // CORE trả về JSON { success: false, error: "..." } nên ta ưu tiên lấy message đó

      let errorMsg = "Lỗi quét hóa đơn";

      // Case 1: Lỗi từ response JSON của Function (CORE custom error)
      // (Lưu ý: supabase-js đôi khi ném lỗi, đôi khi trả về data chứa error)

      // Nếu data trả về có success: false (dù status 200)
      if (data && data.success === false) {
        errorMsg = data.error;
      }
      // Nếu throw error (status 4xx/5xx)
      else if (typeof error === "object" && error !== null) {
        // Thử lấy message từ body response nếu có
        // (Supabase client wraps error, ta cố gắng lấy message chuẩn nhất)
        errorMsg =
          (error as { message?: string }).message ||
          (error as { context?: { statusText?: string } }).context
            ?.statusText ||
          "Lỗi không xác định từ AI";
      }

      // Check keyword từ CORE để hiển thị đẹp hơn
      if (errorMsg.includes("đã được nhập kho")) {
        errorMsg = "⚠️ CẢNH BÁO: " + errorMsg; // Thêm icon cảnh báo
      }

      throw new Error(errorMsg);
    }

    console.log("[Frontend] AI Scan Success:", data);
    return data;
  },

  // 3. Lấy danh sách Hóa đơn
  async getInvoices(page: number, pageSize: number, filters: InvoiceFilters) {
    let query = supabase
      .from("finance_invoices")
      .select("*, suppliers:supplier_id(name), finance_invoice_items(*)", { count: "exact" })
      .order("created_at", { ascending: false })
      .range((page - 1) * pageSize, page * pageSize - 1);

    if (filters.status) {
      query = query.eq("status", filters.status);
    }
    if (filters.direction) {
      query = query.eq("direction", filters.direction);
    }
    if (filters.search) {
      query = query.or(
        `invoice_number.ilike.%${filters.search}%,supplier_name_raw.ilike.%${filters.search}%,buyer_company_name.ilike.%${filters.search}%,buyer_name.ilike.%${filters.search}%`
      );
    }
    if (filters.dateFrom && filters.dateTo) {
      query = query
        .gte("invoice_date", filters.dateFrom)
        .lte("invoice_date", filters.dateTo);
    }

    const { data, error, count } = await query;
    if (error) throw error;

    return { data: data || [], total: count || 0 };
  },

  // 3b. Lấy hóa đơn theo ID
  async getInvoiceById(id: number) {
    const { data, error } = await supabase
      .from("finance_invoices")
      .select("*, suppliers:supplier_id(name), finance_invoice_items(*)")
      .eq("id", id)
      .single();
    if (error) throw error;
    return data;
  },

  // 4. Xóa hóa đơn (Atomic: reverse VAT + delete trong 1 transaction)
  async deleteInvoice(id: number) {
    try {
      // Đầu tiên gọi RPC atomic nếu tồn tại
      await safeRpc("delete_invoice_atomic", { p_invoice_id: id });
      return true;
    } catch (atomicError: unknown) {
      const errMsg =
        atomicError instanceof Error
          ? atomicError.message
          : String(atomicError);
      // Fallback: Nếu RPC chưa tồn tại, dùng flow cũ (2 bước)
      if (errMsg.includes("does not exist")) {
        console.warn("RPC delete_invoice_atomic chưa tồn tại, dùng flow cũ");

        try {
          await safeRpc("reverse_vat_invoice_entry", { p_invoice_id: id });
        } catch (rpcError: unknown) {
          const rpcMsg =
            rpcError instanceof Error ? rpcError.message : String(rpcError);
          if (rpcMsg.includes("violates check constraint")) {
            throw new Error(
              "Không thể xóa: Tồn kho VAT không đủ để trừ (hàng đã được xuất bán)."
            );
          }
          throw rpcError;
        }

        const { error: deleteError } = await supabase
          .from("finance_invoices")
          .delete()
          .eq("id", id);
        if (deleteError) throw deleteError;

        return true;
      } else {
        if (errMsg.includes("violates check constraint")) {
          throw new Error(
            "Không thể xóa: Tồn kho VAT không đủ để trừ (hàng đã được xuất bán)."
          );
        }
        throw atomicError;
      }
    }
  },

  async deleteInvoices(ids: number[]) {
    // Delete multiple invoices concurrently
    await Promise.all(ids.map((id) => this.deleteInvoice(id)));
    return true;
  },

  // 1. Hàm gọi VAT Engine
  async processVatEntry(invoiceId: number) {
    await safeRpc("process_vat_invoice_entry", {
      p_invoice_id: invoiceId,
    });
  },

  // 3. Hàm Tạo Mới (Insert) - Luôn tạo draft, KHÔNG tự động nhập kho VAT
  async createInvoice(payload: InvoicePayload) {
    const { items_json, ...invoiceData } = payload;
    const { data, error } = await safeRpc("upsert_finance_invoice", {
      p_invoice_data: {
        ...invoiceData,
        status: "draft",
        created_at: new Date().toISOString(),
      },
      p_items_data: items_json || [],
    });

    if (error) throw error;

    // Trả về { id: data } do RPC return bigint
    return { id: data };
  },

  // 4. Xác nhận hóa đơn + nhập kho VAT
  async verifyInvoice(id: number, payload: InvoicePayload) {
    // Check status hiện tại để chỉ verify từ draft
    const { data: existing } = await supabase
      .from("finance_invoices")
      .select("status")
      .eq("id", id)
      .single();

    if (existing?.status !== "draft") {
      throw new Error("Chỉ có thể xác nhận hóa đơn ở trạng thái Nháp");
    }

    const { items_json, ...invoiceData } = payload;
    
    // GỌI GOLANG API MỚI THAY VAT RPC
    const { data: sessionInfo } = await supabase.auth.getSession();
    const token = sessionInfo?.session?.access_token;
    
    const goPayload = {
      id: id,
      ...invoiceData,
      items_data: items_json || []
    };

    const backendUrl = import.meta.env.VITE_BACKEND_API_URL || "http://localhost:8080";
    const res = await fetch(`${backendUrl}/api/v1/finance/invoices/upsert`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`
      },
      body: JSON.stringify(goPayload)
    });

    if (!res.ok) {
      const errData = await res.json();
      throw new Error(errData.error || errData.message || "Failed to verify invoice on Go Backend");
    }

    return true;
  },

  // [NEW] Kiểm tra trùng lặp
  async checkInvoiceExists(taxCode: string, symbol: string, number: string) {
    const { data } = await safeRpc("check_invoice_exists", {
      p_tax_code: taxCode,
      p_symbol: symbol,
      p_number: number,
    });
    return data as boolean; // True nếu đã tồn tại
  },

  // 5. Lưu Nháp (Create/Update with status='draft', Skip VAT Entry)
  async saveDraft(id: number | null, payload: InvoicePayload) {
    const { items_json, ...invoiceData } = payload;

    if (id) {
      // Update — chỉ cho phép update nếu đang ở trạng thái draft
      const { data: existing } = await supabase
        .from("finance_invoices")
        .select("status")
        .eq("id", id)
        .single();

      if (existing && existing.status !== "draft") {
        throw new Error(
          `Không thể cập nhật nháp: Hóa đơn đang ở trạng thái "${existing.status}"`
        );
      }
    }

    const { data: upsertId, error: upsertError } = await safeRpc("upsert_finance_invoice", {
      p_invoice_data: {
        ...invoiceData,
        id: id || undefined,
        status: "draft",
        ...(id ? {} : { created_at: new Date().toISOString() }), // Set created_at nếu là insert mới
      },
      p_items_data: items_json || [],
    });

    if (upsertError) throw upsertError;

    return { id: upsertId };
  },

  // 2. Hàm Lấy Mapping (Sửa lỗi để tránh lỗi null unit)
  async getMappedProduct(
    taxCode: string,
    productName: string,
    vendorUnit: string
  ) {
    const response = await safeRpc("get_mapped_product", {
      p_tax_code: taxCode,
      p_product_name: productName,
      p_vendor_unit: vendorUnit || "", // <-- QUAN TRỌNG: Tránh gửi null/undefined
    });
    
    const data = response.data as any[];

    if (data && data.length > 0) {
      return {
        productId: data[0].internal_product_id,
        unit: data[0].internal_unit,
        internal_product_unit_id: data[0].internal_product_unit_id,
        conversion_rate: data[0].conversion_rate,
      };
    }
    return null;
  },

  // [UPDATED] Lưu mapping mới (Có thêm Unit và SKU)
  async upsertVendorProductMapping(
    vendorTaxCode: string,
    vendorProductName: string,
    vendorUnit: string,
    internalProductId: number,
    internalUnit: string,
    supplierSku?: string,
    preVatPrice?: number,
    vatOfSupplier?: number,
    internalProductUnitId?: number
  ) {
    const { error } = await safeRpc("upsert_vendor_product_mapping", {
      p_vendor_tax_code: vendorTaxCode,
      p_vendor_product_name: vendorProductName,
      p_vendor_unit: vendorUnit || "",
      p_internal_product_id: internalProductId,
      p_internal_unit: internalUnit || "",
      p_supplier_sku: supplierSku || null,
      p_pre_vat_price: preVatPrice || null,
      p_vat_of_supplier: vatOfSupplier || null,
      p_internal_product_unit_id: internalProductUnitId || null,
    });
    if (error) throw error;
  },

  // Tạo hóa đơn xuất kho VAT (Outbound - Trừ kho)
  async createOutboundInvoice(payload: InvoicePayload, isDraft: boolean = false) {
    const { data: sessionInfo } = await supabase.auth.getSession();
    const token = sessionInfo?.session?.access_token;

    const goPayload = {
      ...payload,
      is_draft: isDraft,
      items_data: payload.items_data || []
    };

    const backendUrl = import.meta.env.VITE_BACKEND_API_URL || "http://localhost:8080";
    const res = await fetch(`${backendUrl}/api/v1/finance/invoices/upsert`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`
      },
      body: JSON.stringify(goPayload)
    });

    if (!res.ok) {
      const errData = await res.json();
      throw new Error(errData.error || errData.message || "Lỗi khi lưu hóa đơn xuất kho");
    }

    const savedInvoice = await res.json();
    return savedInvoice.data;
  },

  async syncGdtInvoices(payload: any[]) {
    const { data: sessionInfo } = await supabase.auth.getSession();
    const token = sessionInfo?.session?.access_token;
    
    const backendUrl = import.meta.env.VITE_BACKEND_API_URL || "http://localhost:8080";
    const response = await fetch(`${backendUrl}/api/v1/finance/invoices/sync`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`,
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const errData = await response.json().catch(() => ({}));
      throw new Error(errData.error || errData.message || "Failed to sync invoices");
    }
    
    return await response.json();
  },

  async getGdtStatus() {
    const backendUrl = import.meta.env.VITE_BACKEND_API_URL || "http://localhost:8080";
    const response = await fetch(`${backendUrl}/api/v1/finance/invoices/gdt-status`);
    if (!response.ok) {
      throw new Error("Failed to get GDT status");
    }
    return await response.json();
  },

  async syncGdtNow() {
    const { data: sessionInfo } = await supabase.auth.getSession();
    const token = sessionInfo?.session?.access_token;
    
    const backendUrl = import.meta.env.VITE_BACKEND_API_URL || "http://localhost:8080";
    const response = await fetch(`${backendUrl}/api/v1/finance/invoices/gdt-sync-now`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': `Bearer ${token}` } : {})
      }
    });

    if (!response.ok) {
      throw new Error(`GDT sync error: ${response.status}`);
    }
    return await response.json();
  }
};
