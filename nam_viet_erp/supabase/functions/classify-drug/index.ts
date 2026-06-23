import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  try {
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiApiKey) throw new Error("Missing GEMINI_API_KEY");

    const rawBody = await req.text();
    if (!rawBody) throw new Error("Empty Request Body");

    let body;
    try {
      body = JSON.parse(rawBody);
    } catch (e) {
      throw new Error("Invalid JSON");
    }

    const { product_name } = body;
    if (!product_name) {
      throw new Error("Missing product_name");
    }

    const promptText = `
Bạn là "Chuyên gia Pháp chế Dược Việt Nam". 
Tôi có một sản phẩm thuốc tên là: "${product_name}".

Nhiệm vụ của bạn:
1. Bóc tách ra danh sách các hoạt chất chính và hàm lượng từ tên thuốc này.
2. Dựa trên Thông tư 20/2017/TT-BYT (Thuốc Không Kê Đơn - OTC), Thông tư 19/2018/TT-BYT (Thuốc Thiết Yếu) và quy định về Thuốc Kiểm Soát Đặc Biệt (Gây nghiện, hướng thần, tiền chất), hãy phân loại thuốc này.

Hãy trả về kết quả chuẩn định dạng JSON sau (không chứa markdown \`\`\`json):
{
  "active_ingredients": [
    {
      "name": "Tên hoạt chất bằng tiếng Anh (VD: Paracetamol)",
      "strength_value": 500,
      "strength_unit": "mg",
      "is_primary": true
    }
  ],
  "item_type": "drug",
  "prescription_class": "rx" hoặc "otc",
  "special_control_type": null hoặc "narcotic" hoặc "psychotropic" hoặc "precursor",
  "is_essential": true hoặc false,
  "reason": "Giải thích lý do phân loại ngắn gọn"
}
`;

    const modelVersion = "gemini-2.5-flash";
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${modelVersion}:generateContent?key=${geminiApiKey}`;

    const response = await fetch(geminiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: promptText }] }],
          generationConfig: {
            temperature: 0.2,
            responseMimeType: "application/json",
          },
        }),
      }
    );

    if (!response.ok) {
      const err = await response.text();
      console.error("Gemini API Error:", err);
      throw new Error(`Gemini API failed with status ${response.status}`);
    }

    const data = await response.json();
    let textResponse = data?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!textResponse) {
      throw new Error("Gemini returned empty or unexpected response format");
    }

    // Clean markdown
    textResponse = textResponse.replace(/```json/gi, "").replace(/```/gi, "").trim();

    return new Response(textResponse, {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error: any) {
    console.error("Function error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
