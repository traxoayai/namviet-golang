import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SEPAY_BASE_URL =
  Deno.env.get("SEPAY_BASE_URL") || "https://einvoice-api-sandbox.sepay.vn";
const SEPAY_CLIENT_ID = Deno.env.get("SEPAY_CLIENT_ID") || "";
const SEPAY_CLIENT_SECRET = Deno.env.get("SEPAY_CLIENT_SECRET") || "";
const SEPAY_TEMPLATE_CODE = Deno.env.get("SEPAY_TEMPLATE_CODE") || "1";
const SEPAY_INVOICE_SERIES = Deno.env.get("SEPAY_INVOICE_SERIES") || "C26TSE";
const SEPAY_PROVIDER_ACCOUNT_ID =
  Deno.env.get("SEPAY_PROVIDER_ACCOUNT_ID") || "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// --- HELPER: Caching Token in Memory ---
let cachedToken: string | null = null;
let tokenExpiresAt = 0;

async function getSepayToken() {
  const now = Math.floor(Date.now() / 1000);

  // Dùng lại token nếu còn hạn trên 5 phút
  if (cachedToken && tokenExpiresAt > now + 300) {
    return cachedToken;
  }

  const SEPAY_BASE_URL =
    Deno.env.get("SEPAY_BASE_URL") || "https://einvoice-api-sandbox.sepay.vn";
  const clientId = Deno.env.get("SEPAY_CLIENT_ID");
  const clientSecret = Deno.env.get("SEPAY_CLIENT_SECRET");

  if (!clientId || !clientSecret) {
    throw new Error(
      "Thiếu SEPAY_CLIENT_ID hoặc SEPAY_CLIENT_SECRET trong biến môi trường"
    );
  }

  // Tuyệt chiêu mã hóa Basic Authentication cho SePay
  const basicAuth = btoa(`${clientId}:${clientSecret}`);

  // Gọi API lấy Token chuẩn xác theo tài liệu
  const res = await fetch(`${SEPAY_BASE_URL}/v1/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${basicAuth}`,
    },
    // Tài liệu ghi chú: Gửi yêu cầu với body rỗng (không cần request body)
  });

  const data = await res.json();
  if (!data.success) {
    throw new Error("Lỗi xác thực lấy Token từ SePay: " + JSON.stringify(data));
  }

  // Lưu vào RAM
  cachedToken = data.data.access_token;
  tokenExpiresAt = now + data.data.expires_in;

  return cachedToken;
}

serve(async (req) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const supabase = createClient(supabaseUrl, supabaseKey);

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new Error("Missing Authorization header");

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));
    if (authError || !user) throw new Error("Unauthorized");

    const { invoice_id, is_draft = false } = await req.json();
    if (!invoice_id) throw new Error("Missing invoice_id");

    // Lấy thông tin hóa đơn từ DB
    const { data: invoice, error: invoiceError } = await supabase
      .from("finance_invoices")
      .select("*")
      .eq("id", invoice_id)
      .single();

    if (invoiceError || !invoice) throw new Error("Khong tim thay hoa don VAT");
    if (invoice.direction !== "outbound")
      throw new Error("Chi ap dung cho hoa don ban ra");

    // Lấy danh sách items
    const { data: itemsData, error: itemsError } = await supabase
      .from("finance_invoice_items")
      .select("*")
      .eq("invoice_id", invoice_id);

    // Chuẩn bị Payload
    const items = (itemsData || []).map((item, index) => {
      const unitPricePreVat = item.quantity
        ? item.total_amount_pre_vat / item.quantity
        : 0;
      return {
        line_number: index + 1,
        line_type: 1, // 1: hàng hóa dịch vụ
        item_name: item.vendor_product_name || "Hàng hóa",
        item_code: `SP${item.product_id || 999}`,
        unit: item.vendor_unit || "Cái",
        quantity: item.quantity,
        unit_price: Math.round(unitPricePreVat),
        tax_rate:
          item.vat_rate === 0
            ? 0
            : item.vat_rate === 5
              ? 5
              : item.vat_rate === 8
                ? 8
                : 10,
      };
    });

    if (invoice.total_trade_discount && invoice.total_trade_discount > 0) {
      items.push({
        line_number: items.length + 1,
        line_type: 3, // 3: Chiết khấu thương mại
        item_name: "Chiết khấu thương mại",
        item_code: "CKTM",
        unit: "",
        quantity: 0,
        unit_price: 0,
        tax_rate: 0,
        before_discount_and_tax_amount: Math.round(
          invoice.total_trade_discount
        ),
      } as any);
    }

    const sepayPayload = {
      template_code: SEPAY_TEMPLATE_CODE,
      invoice_series: SEPAY_INVOICE_SERIES,
      issued_date: invoice.invoice_date
        ? `${invoice.invoice_date} 00:00:00`
        : "2026-01-26 00:00:00",
      currency: "VND",
      buyer: {
        type:
          invoice.buyer_tax_code && invoice.buyer_tax_code.length >= 10
            ? "company"
            : "personal",
        name: invoice.buyer_name || invoice.buyer_company_name || "Khách hàng",
        legal_name:
          invoice.buyer_company_name || invoice.buyer_name || "Khách hàng",
        tax_code: invoice.buyer_tax_code || "",
        address: invoice.buyer_address || "",
        email: invoice.buyer_email || "",
      },
      items: items,
      total_amount: Math.round(invoice.total_amount_post_tax),
      payment_method: "TM/CK",
      provider_account_id: SEPAY_PROVIDER_ACCOUNT_ID,
      notes: "Ghi chú hóa đơn ERP",
      is_draft: is_draft,
    };

    // Gọi API SePay
    const token = await getSepayToken();
    const res = await fetch(`${SEPAY_BASE_URL}/v1/invoices/create`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(sepayPayload),
    });

    const resData = await res.json();
    if (!resData.success) {
      throw new Error(
        "Loi tu SePay: " + (resData.error?.message || JSON.stringify(resData))
      );
    }

    const trackingCode = resData.data?.tracking_code || resData.tracking_code;
    let initialPdfUrl = resData.data?.pdf_url || resData.pdf_url;

    // Short-polling 3 lần để lấy kết quả ngay lập tức
    let referenceCode = null;
    let draftDetails = null;
    let finalStatus = "pending";

    for (let i = 0; i < 4; i++) {
      await new Promise((resolve) => setTimeout(resolve, 1500)); // Sleep 1.5s
      const checkRes = await fetch(
        `${SEPAY_BASE_URL}/v1/invoices/create/check/${trackingCode}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      const checkData = await checkRes.json();
      if (checkData.success && checkData.data.status === "Success") {
        referenceCode = checkData.data.reference_code;
        draftDetails = checkData.data.invoice;
        finalStatus = "success";
        break;
      } else if (checkData.success && checkData.data.status === "Failed") {
        finalStatus = "failed";
        break;
      }
    }

    if (finalStatus === "success") {
      const finalPdfUrl = draftDetails?.pdf_url || initialPdfUrl;
      const dbStatus = is_draft ? "draft" : "issued_outbound";

      await supabase
        .from("finance_invoices")
        .update({
          sepay_tracking_code: trackingCode,
          sepay_status: "success",
          sepay_reference_code: referenceCode,
          parsed_data: draftDetails,
          file_url: finalPdfUrl,
          status: dbStatus,
        })
        .eq("id", invoice_id);

      return new Response(
        JSON.stringify({
          success: true,
          tracking_code: trackingCode,
          pdf_url: finalPdfUrl,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    } else if (finalStatus === "failed") {
      // Nếu lỗi ngay, rollback luôn
      await supabase
        .from("finance_invoices")
        .update({
          sepay_status: "failed",
          status: is_draft ? "draft" : "draft_outbound",
        })
        .eq("id", invoice_id);

      if (!is_draft) {
        await supabase.rpc("rollback_vat_export_entry", {
          invoice_id_input: invoice_id,
        });
      }

      return new Response(
        JSON.stringify({
          success: false,
          error: "Tạo hóa đơn thất bại từ SePay",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Nếu vẫn pending sau 6 giây, để cronjob lo
    const pendingDbStatus = is_draft ? "draft" : "verified_outbound";
    await supabase
      .from("finance_invoices")
      .update({
        sepay_tracking_code: trackingCode,
        sepay_status: "pending",
        file_url: initialPdfUrl,
        status: pendingDbStatus,
      })
      .eq("id", invoice_id);

    return new Response(
      JSON.stringify({
        success: true,
        tracking_code: trackingCode,
        pdf_url: initialPdfUrl,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
