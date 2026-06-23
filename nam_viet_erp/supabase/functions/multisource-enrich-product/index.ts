// Setup: deno install --allow-net --allow-env --allow-read index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") || "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

function getCorsOrigin(req: Request) {
  const origin = req.headers.get("origin") || "";
  if (ALLOWED_ORIGINS.length === 0) return origin; // Dev fallback
  return ALLOWED_ORIGINS.includes(origin) ? origin : "";
}

function buildCorsHeaders(req: Request) {
  return {
    "Access-Control-Allow-Origin": getCorsOrigin(req),
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Max-Age": "86400",
  };
}

async function callGemini(model: string, geminiApiKey: string, prompt: string, textData: string) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiApiKey}`;
  const resp = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      contents: [
        {
          parts: [
            { text: prompt },
            { text: textData }
          ],
        },
      ],
      generationConfig: {
        responseMimeType: "application/json",
      }
    }),
  });

  const data = await resp.json();
  if (!resp.ok) {
    throw new Error(`Gemini ${model} fail: ${data?.error?.message ?? `HTTP ${resp.status}`}`);
  }
  return data;
}

serve(async (req) => {
  const corsHeaders = buildCorsHeaders(req);
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const supabase = supabaseUrl && supabaseKey ? createClient(supabaseUrl, supabaseKey) : null;

  if (!supabase) {
    return new Response(
      JSON.stringify({ success: false, error: "Server misconfigured" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    const rawBody = await req.text();
    if (!rawBody) throw new Error("Empty Request Body");
    const body = JSON.parse(rawBody);

    const { sku, name, source_url, raw_text } = body;
    if (!sku) throw new Error("Missing sku in payload");
    if (!raw_text) throw new Error("Missing raw_text in payload");

    // Lấy product_id từ SKU
    const { data: prodData, error: prodErr } = await supabase
      .from("products")
      .select("id")
      .eq("sku", sku)
      .maybeSingle();

    if (prodErr || !prodData) {
      throw new Error(`Product not found for SKU: ${sku}`);
    }
    const product_id = prodData.id;

    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiApiKey) throw new Error("Missing GEMINI_API_KEY");
    const primaryModel = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash";

    const prompt = `
      Bạn là chuyên gia y tế và dữ liệu. Nhiệm vụ của bạn là phân tích văn bản thô (inner text) được cào từ một trang web bán thuốc (VD: An Khang, Long Châu...). Văn bản này rất lộn xộn, bạn cần đọc và tìm ra thông tin của sản phẩm thuốc có tên là "${name}", sau đó trích xuất thành định dạng JSON chuẩn.
      
      YÊU CẦU:
      1. description: Gộp Mô tả, Chỉ định, Chống chỉ định, Tác dụng phụ, Điều kiện bảo quản thành một văn bản hoàn chỉnh, rõ ràng, phân đoạn bằng ký tự xuống dòng '\\n'. Lấy dựa trên văn bản web.
      2. active_ingredients: Trả về một mảng (array) các hoạt chất. Mỗi phần tử gồm name (tên hoạt chất, tiếng Anh hoặc tiếng Việt chuẩn hóa), strength_value (số hàm lượng), strength_unit (đơn vị như mg, g, ml...). Nếu không có hàm lượng thì để null.
      3. usage_instructions: TUYỆT ĐỐI TUÂN THỦ FORMAT JSON: {"0_2": "", "2_6": "", "6_12": "", "18_plus": "", "contraindication": ""}. Trích xuất liều dùng theo từng độ tuổi và chống chỉ định vào đúng các trường này. Nếu không có thông tin cho nhóm tuổi nào, hãy để chuỗi rỗng "". KHÔNG THÊM BẤT KỲ TRƯỜNG NÀO KHÁC VÀO usage_instructions.
      4. manufacturer_name: Tên nhà sản xuất.
      5. image_url: Tìm trong chuỗi (nếu có URL ảnh nào hợp lý), không có thì để null.
      6. item_type: Phân loại sản phẩm. Chọn 1 trong: 'drug', 'supplement', 'medical_device', 'herbal', 'cosmetic'.
      7. prescription_class: Phân loại kê đơn. Chọn 'rx' hoặc 'otc'. Trả về null nếu không phải thuốc.
      8. special_control_type: Phân loại kiểm soát đặc biệt. Chọn 1 trong: 'none', 'narcotic', 'psychotropic', 'precursor', 'combination', 'toxic', 'radioactive'. BẠN HÃY DÙNG KIẾN THỨC Y KHOA ĐỂ PHÂN LOẠI. Mặc định là 'none'.
      9. is_essential: Thuốc có thuộc danh mục thiết yếu hay không (boolean). BẠN HÃY DÙNG CẢ KIẾN THỨC Y KHOA BÊN NGOÀI CỦA MÌNH ĐỂ ĐÁNH GIÁ (VD: Paracetamol, Nystatin... là thuốc thiết yếu). Nếu chắc chắn là thuốc thiết yếu thì chọn true, ngược lại false.
      10. is_vaccine: Có phải là vaccine không (boolean). BẠN HÃY DÙNG KIẾN THỨC Y KHOA ĐỂ PHÂN LOẠI.
      11. category_name: Đặt tên danh mục phù hợp nhất cho sản phẩm này dựa vào công dụng (Ví dụ: "Thuốc hô hấp & Cảm cúm", "Vitamin & Khoáng chất", "Tim mạch"...).
      12. product_contents: Tạo dữ liệu chuẩn SEO cho website. Bao gồm: short_description (mô tả ngắn ngọn), description_html (mô tả dạng HTML, bôi đậm ý chính), seo_title (tiêu đề SEO, tối đa 60 ký tự), seo_description (mô tả SEO, tối đa 160 ký tự), seo_keywords (mảng các từ khóa SEO).

      Output JSON format BẮT BUỘC:
      {
        "description": "string",
        "active_ingredients": [
          { "name": "string", "strength_value": 0, "strength_unit": "string" }
        ],
        "usage_instructions": {
          "0_2": "string", "2_6": "string", "6_12": "string", "18_plus": "string", "contraindication": "string"
        },
        "manufacturer_name": "string",
        "image_url": "string | null",
        "product_images": [],
        "category_name": "string",
        "product_contents": {
          "short_description": "string",
          "description_html": "string",
          "seo_title": "string",
          "seo_description": "string",
          "seo_keywords": ["string"]
        },
        "regulatory": {
          "item_type": "string", "prescription_class": "string | null", "special_control_type": "string", "is_essential": true, "is_vaccine": true
        }
      }
    `;

    console.log(`[Gemini] Processing multisource product SKU: ${sku}...`);
    const aiData = await callGemini(primaryModel, geminiApiKey, prompt, raw_text);
    
    const parts = aiData.candidates?.[0]?.content?.parts ?? [];
    const textPart = parts.find((p: any) => typeof p?.text === "string" && p.text.trim().length > 0);
    const rawOutput = textPart?.text ?? "{}";
    
    let parsedData;
    try {
      parsedData = JSON.parse(rawOutput.replace(/```json|```/g, "").trim());
    } catch (e) {
      throw new Error("Failed to parse Gemini output as JSON: " + rawOutput);
    }

    function toSlug(str: string) {
      return str.toLowerCase().trim()
        .replace(/[^\w\s-]/g, '')
        .replace(/[\s_-]+/g, '-')
        .replace(/^-+|-+$/g, '');
    }

    // Process category
    let finalCategoryId = null;
    if (parsedData.category_name) {
      const catName = parsedData.category_name;
      const catSlug = toSlug(catName);
      
      const { data: existingCat } = await supabase
        .from("categories")
        .select("id")
        .eq("slug", catSlug)
        .maybeSingle();
        
      if (existingCat) {
        finalCategoryId = existingCat.id;
      } else {
        const { data: newCat, error: catErr } = await supabase
          .from("categories")
          .insert({ name: catName, slug: catSlug, status: 'active' })
          .select("id")
          .single();
        if (!catErr && newCat) {
          finalCategoryId = newCat.id;
        }
      }
    }

    // Update DB products
    const dbPayload: any = {
      description: parsedData.description,
      usage_instructions: parsedData.usage_instructions,
      manufacturer_name: parsedData.manufacturer_name,
      updated_at: new Date().toISOString()
    };
    
    if (parsedData.image_url) {
      dbPayload.image_url = parsedData.image_url;
    }
    
    if (finalCategoryId) {
      dbPayload.category_id = finalCategoryId;
    }

    const dbResult = await supabase
      .from("products")
      .update(dbPayload)
      .eq("id", product_id)
      .select("id")
      .single();

    if (dbResult.error) throw dbResult.error;

    // Process product_contents
    if (parsedData.product_contents) {
      const pc = parsedData.product_contents;
      const pcPayload = {
        product_id: product_id,
        channel: 'retail',
        short_description: pc.short_description || null,
        description_html: pc.description_html || null,
        seo_title: pc.seo_title || null,
        seo_description: pc.seo_description || null,
        seo_keywords: Array.isArray(pc.seo_keywords) ? pc.seo_keywords : null,
        is_published: true,
        updated_at: new Date().toISOString()
      };
      
      await supabase
        .from("product_contents")
        .upsert(pcPayload, { onConflict: 'product_id, channel' });
    }

    // Upsert into product_regulatory
    if (parsedData.regulatory) {
      const reg = parsedData.regulatory;
      const regPayload = {
        product_id: product_id,
        item_type: reg.item_type || "drug",
        prescription_class: reg.prescription_class || null,
        special_control_type: reg.special_control_type || "none",
        is_essential: reg.is_essential || false,
        is_vaccine: reg.is_vaccine || false,
        is_restricted_retail: false,
        updated_at: new Date().toISOString()
      };

      const regResult = await supabase
        .from("product_regulatory")
        .upsert(regPayload, { onConflict: 'product_id' });
    }

    // Update Active Ingredients
    if (parsedData.active_ingredients && Array.isArray(parsedData.active_ingredients)) {
      await supabase
        .from('product_active_ingredients')
        .delete()
        .eq('product_id', product_id);

      let sortOrder = 0;
      for (const ing of parsedData.active_ingredients) {
        if (!ing.name || typeof ing.name !== 'string') continue;
        const slug = toSlug(ing.name);
        if (!slug) continue;

        let { data: existingIng } = await supabase
          .from('active_ingredients')
          .select('id')
          .eq('slug', slug)
          .maybeSingle();

        let active_ingredient_id;
        if (existingIng) {
          active_ingredient_id = existingIng.id;
        } else {
          const { data: newIng, error: insertErr } = await supabase
            .from('active_ingredients')
            .insert({ name: ing.name, slug: slug })
            .select('id')
            .single();
          if (insertErr) continue;
          active_ingredient_id = newIng.id;
        }

        await supabase
          .from('product_active_ingredients')
          .insert({
            product_id: product_id,
            active_ingredient_id: active_ingredient_id,
            strength_value: typeof ing.strength_value === 'number' ? ing.strength_value : null,
            strength_unit: typeof ing.strength_unit === 'string' ? ing.strength_unit : null,
            is_primary: sortOrder === 0,
            sort_order: sortOrder
          });
        
        sortOrder++;
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        product_id: product_id,
        source: source_url
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error: any) {
    console.error("Fatal:", error.message);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
