import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SEPAY_BASE_URL = Deno.env.get("SEPAY_BASE_URL") || "https://einvoice-api-sandbox.sepay.vn";
const SEPAY_CLIENT_ID = Deno.env.get("SEPAY_CLIENT_ID") || "";
const SEPAY_CLIENT_SECRET = Deno.env.get("SEPAY_CLIENT_SECRET") || "";

// --- HELPER: Caching Token in Memory ---
let cachedToken: string | null = null;
let tokenExpiresAt = 0;

async function getSepayToken() {
  if (cachedToken && Date.now() < tokenExpiresAt) return cachedToken;
  if (!SEPAY_CLIENT_ID || !SEPAY_CLIENT_SECRET) {
    throw new Error("SEPAY credentials chưa cấu hình (SEPAY_CLIENT_ID / SEPAY_CLIENT_SECRET)");
  }
  const credentials = btoa(`${SEPAY_CLIENT_ID}:${SEPAY_CLIENT_SECRET}`);
  const res = await fetch(`${SEPAY_BASE_URL}/v1/token`, {
    method: "POST",
    headers: { Authorization: `Basic ${credentials}` },
  });
  if (!res.ok) {
    const body = await res.text().catch(()=>"");
    throw new Error(`SEPAY token error (${res.status}): ${body}`);
  }
  const json = await res.json();
  if (!json.success || !json.data?.access_token) {
    throw new Error("SEPAY token response invalid");
  }
  cachedToken = json.data.access_token;
  tokenExpiresAt = Date.now() + (json.data.expires_in - 3600) * 1000;
  return cachedToken;
}

serve(async (req) => {
  // Cronjob usually invoked via Supabase Scheduler, no CORS needed but just in case
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const supabase = createClient(supabaseUrl, supabaseKey);

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new Error("Missing Authorization header");

    const { data: pendingInvoices, error } = await supabase
      .from("finance_invoices")
      .select("id, sepay_tracking_code")
      .eq("direction", "outbound")
      .eq("sepay_status", "pending")
      .not("sepay_tracking_code", "is", null);

    if (error) throw error;

    if (!pendingInvoices || pendingInvoices.length === 0) {
      return new Response("No pending invoices", { status: 200 });
    }

    const token = await getSepayToken();

    for (const inv of pendingInvoices) {
      try {
        const checkRes = await fetch(`${SEPAY_BASE_URL}/v1/invoices/create/check/${inv.sepay_tracking_code}`, {
          method: "GET",
          headers: { Authorization: `Bearer ${token}` }
        });

        const checkData = await checkRes.json();
        
        if (checkData.success && checkData.data.status === "Success") {
          // Thành công
          await supabase.from("finance_invoices").update({
            sepay_status: "success",
            sepay_reference_code: checkData.data.reference_code,
            file_url: checkData.data.invoice?.pdf_url, // Lưu PDF URL
            status: "issued_outbound" // Hoàn tất
          }).eq("id", inv.id);
        } else if (checkData.success && checkData.data.status === "Failed") {
          // Thất bại
          await supabase.from("finance_invoices").update({
            sepay_status: "failed",
            status: "draft_outbound" // Rollback về draf
          }).eq("id", inv.id);
          
          // Hoàn lại kho bằng hàm RPC
          await supabase.rpc('rollback_vat_export_entry', { invoice_id_input: inv.id });
        }
        // Nếu status = "Pending", bỏ qua chờ lần chạy sau
      } catch (err) {
        console.error("Error checking invoice", inv.id, err);
      }
    }

    return new Response("Cron job finished successfully", { status: 200 });

  } catch (err: any) {
    return new Response(JSON.stringify({ success: false, error: err.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});
