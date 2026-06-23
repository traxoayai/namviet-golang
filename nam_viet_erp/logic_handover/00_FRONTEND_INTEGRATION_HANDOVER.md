# 🚀 MASTER HANDOVER: FRONTEND INTEGRATION GUIDE (GOLANG BACKEND)

**Dự án:** NamViet ERP V3
**Tài liệu dành cho:** Frontend Team / Frontend Architect Agent
**Mục tiêu:** Cung cấp hướng dẫn toàn diện để chuyển đổi Frontend từ kiến trúc cũ (gọi trực tiếp Supabase RPC) sang kiến trúc mới (gọi qua Application Layer bằng Golang).

---

## 1. THAY ĐỔI KIẾN TRÚC CỐT LÕI (PARADIGM SHIFT)

> [!WARNING]
> **Dừng hoàn toàn việc sử dụng Supabase RPC (`supabase.rpc`) cho các tác vụ ghi/xử lý logic.**
> Cơ sở dữ liệu Supabase giờ đây đóng vai trò thuần lưu trữ. Mọi business logic đã được chuyển lên Golang Cloud Run.

### Quy trình mới:
1. **Đọc dữ liệu (Read/GET):** Vẫn có thể giữ nguyên cách sử dụng `supabase.from('table').select(...)` trực tiếp trên Frontend để tận dụng tốc độ và RLS (Row Level Security) của Supabase.
2. **Ghi dữ liệu (Write/POST/PUT/DELETE):** Bắt buộc phải gọi qua các **HTTP REST API** của Backend Golang.
3. **Realtime (WebSocket):** Bỏ Supabase Realtime SDK ở các tính năng nghẽn cổ chai (như Hàng đợi Y tế). Thay bằng Native WebSocket kết nối thẳng tới Golang.

---

## 2. XÁC THỰC VÀ PHÂN QUYỀN (AUTHENTICATION)

Backend Golang sử dụng nguyên bản cơ chế cấp token của Supabase. Frontend không cần thay đổi quy trình đăng nhập.

**Cách tích hợp API:**
Với mỗi HTTP Request gửi lên Backend Golang, bắt buộc phải đính kèm Header `Authorization` chứa JWT Access Token lấy từ phiên đăng nhập hiện tại của người dùng.

```javascript
// Ví dụ mẫu (Sử dụng fetch API)
const { data: { session } } = await supabase.auth.getSession();
const token = session.access_token;

const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/v1/orders`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}` // Bắt buộc
  },
  body: JSON.stringify(payload)
});
```

---

## 3. DANH SÁCH CÁC ENDPOINT QUAN TRỌNG

Mọi Endpoint đều có tiền tố: `https://[CLOUD_RUN_URL]/api/v1`

### A. Module Bán Hàng & Tồn Kho (Orders & Inventory)
> [!NOTE] 
> Chỉ cần gọi 1 API `POST /orders`, hệ thống Backend sẽ tự động xử lý toàn bộ: Tạo đơn, tính tổng tiền, kiểm tra tồn kho, xuất kho FEFO, ghi nhận giao dịch tài chính và cộng điểm Loyalty.

- **Tạo Đơn Hàng Mới:**
  - `POST /orders`
  - Body: `{ "customer_id": 1, "warehouse_id": 1, "payment_method": "cash", "voucher_code": "SUMMER", "items": [...] }`

- **Nghiệp vụ Kho lẻ:**
  - `POST /inventory/validate` (Kiểm tra xem kho có đủ hàng không trước khi thêm vào giỏ).
  - `POST /inventory/receipt` (Tạo phiếu nhập kho, tự động sinh Batch Code).

### B. Module Tài Chính (Finance)
- **Cấp Token GDT (Tổng Cục Thuế):**
  - `POST /finance/invoices/gdt-token`
- **Khởi chạy thuật toán chia nhỏ Hóa Đơn VAT (Knapsack DP):**
  - `POST /finance/vat-allocation` (Tự động chia tách công nợ thành các Hóa đơn VAT dưới mức trần 5 triệu VNĐ trả bằng tiền mặt).

### C. Module Y Tế & Phòng Khám (Clinic)
- **Tạo Lịch Khám:**
  - `POST /clinic/appointments` (Backend sẽ tự động block nếu trùng giờ).
- **Check-in Bệnh Nhân:**
  - `POST /clinic/appointments/:id/check-in`

> [!IMPORTANT]
> **Realtime Clinic Queue:**
> Để lắng nghe hàng đợi phòng khám (bệnh nhân đổi trạng thái), Frontend phải kết nối WebSocket thay vì dùng Supabase SDK.
> - **URL:** `wss://[CLOUD_RUN_URL]/ws/v1/clinic/queue`
> - **Cách dùng:** 
>   ```javascript
>   const ws = new WebSocket(process.env.NEXT_PUBLIC_WS_URL + '/ws/v1/clinic/queue');
>   ws.onmessage = (event) => {
>       const data = JSON.parse(event.data);
>       console.log("Cập nhật hàng đợi:", data);
>       // Trigger re-render UI
>   };
>   ```

### D. Module Hệ Thống & Trí Tuệ Nhân Tạo (AI Chat)
- **Trò chuyện với Trợ lý AI (Gemini):**
  - `POST /ai/chat`
  - **Lưu ý:** API này trả về dữ liệu dưới định dạng **Server-Sent Events (SSE) Streaming**. Frontend cần dùng TextDecoder để parse dữ liệu kiểu "chữ chạy" giống UI của ChatGPT.
  - API bị Rate-limit (20 request/1 giờ) và chỉ dành cho roles `admin, pharmacist, doctor`.

### E. Module Vận Chuyển (Logistics)
- **Tạo Vận Đơn (Giao Hàng Nhanh):**
  - `POST /logistics/orders/:id/shipping`
- *(Webhook `POST /webhooks/logistics/status-update` do hãng vận chuyển gọi, Frontend không cần quan tâm).*

### F. Module Khuyến Mãi (Promotions)
- **Kiểm tra Voucher:**
  - `POST /promotions/verify`
  - Trả về tiền được giảm trước khi khách hàng bấm "Thanh toán". Lượt sử dụng được lock cứng bằng DB để chống lạm dụng.

---

## 4. QUY TRÌNH TRIỂN KHAI CHO FRONTEND TEAM

1. **Thiết lập Biến Môi Trường:**
   Tạo file `.env.local` ở Repo Frontend mới:
   ```env
   NEXT_PUBLIC_API_URL=https://namviet-erp-backend-1051286041700.asia-southeast1.run.app
   NEXT_PUBLIC_WS_URL=wss://namviet-erp-backend-1051286041700.asia-southeast1.run.app
   ```
2. **Tạo API Services Layer:** 
   Không gọi fetch trực tiếp rải rác trong Component. Hãy xây dựng một thư mục `src/services/api` chứa các class/hàm gọi API chuẩn có đính kèm Bearer Token (dùng Axios Interceptors).
3. **Refactor Hooks:** 
   Các custom React Hooks trước đây chứa logic `supabase.rpc` cần được cập nhật để sử dụng API Services mới.
4. **Kiểm tra luồng SSE cho AI Chat:** Đảm bảo UI không bị giật lag khi text stream về.

> [!TIP]
> Swagger Documentation (OAS3) có sẵn tại: `https://[CLOUD_RUN_URL]/swagger/index.html` 
> Frontend Team có thể dùng nó để Generate TypeScript Interfaces tự động. Chúc team tích hợp thành công!
