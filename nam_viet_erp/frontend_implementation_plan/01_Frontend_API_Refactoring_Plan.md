# Frontend API Refactoring Plan (Supabase RPC to Golang API)

Thay thế hoàn toàn việc gọi trực tiếp Supabase RPC (`supabase.rpc`) cho các thao tác ghi (POST/PUT/DELETE) bằng việc gọi qua Application Layer (Golang API) theo đúng chuẩn kiến trúc mới của NamViet ERP V3.

## Mục tiêu (Goal)
Đảm bảo tính đồng bộ dữ liệu, an toàn giao dịch (tránh Race Condition) và hiệu năng thời gian thực tốt hơn bằng cách:
1. Định tuyến toàn bộ logic ghi/cập nhật dữ liệu về Backend Golang.
2. Tích hợp JWT Token từ Supabase Auth vào HTTP Headers để Backend xác thực.
3. Chuyển đổi Supabase Realtime sang Native WebSocket kết nối với Golang.

> [!WARNING]
> Mọi thay đổi này sẽ diễn ra song song (Parallel Run). Chúng ta không xóa code cũ ngay lập tức mà sẽ refactor và migrate từng Module (Bắt đầu từ Inventory & Orders theo đúng Handover của Backend).

## User Review Required
- Cần xác nhận việc cài đặt thư viện `axios` để quản lý interceptors (bắt và đính kèm Bearer Token tự động) dễ dàng hơn so với dùng `fetch` thuần túy.
- Cần xác nhận việc cài đặt thư viện `openapi-typescript` để tự động gen Type từ `swagger.json` của Backend.

## Open Questions
> [!IMPORTANT]
> 1. Theo Backend Master Directive, Phase 1 là **Module Kho (Inventory) & Module Bán Hàng (Orders)**. Chúng ta sẽ bắt đầu refactor UI của 2 Module này trước tiên, đúng không?
> 2. Có bất kỳ repository riêng nào cho Swagger UI/JSON không, hay tôi sẽ trực tiếp đọc file `D:\29.NamVietErp-V3\nam_viet_erp_backend\docs\swagger.json` để tạo file Typescript?

## Proposed Changes

### 1. Cấu hình & Base Layer
Tạo nền tảng giao tiếp HTTP chuẩn mực và an toàn với Backend.

#### [NEW] `src/shared/utils/axiosClient.ts`
Khởi tạo instance Axios. Viết Interceptors:
- Request: Tự động lấy `session.access_token` từ `supabase.auth.getSession()` và đính kèm vào header `Authorization: Bearer <token>`.
- Response: Xử lý lỗi chung (như 401 Unauthorized thì force logout).

#### [NEW] `src/shared/types/api.types.ts` (Auto-generated)
Chạy script `openapi-typescript` đọc từ `swagger.json` của Backend để tạo ra toàn bộ interface/type definitions chính xác 100%.

### 2. Xây dựng API Services Layer (Phase 1: Orders & Inventory)
Tạo các service riêng rẽ cho từng nghiệp vụ để tách biệt logic gọi API khỏi UI Component.

#### [NEW] `src/services/api/orderApi.ts`
Chứa các hàm gọi REST API: `createOrder`, `updateOrderStatus`, v.v...

#### [NEW] `src/services/api/inventoryApi.ts`
Chứa các hàm gọi REST API: `validateInventory`, `createReceipt`, v.v...

### 3. Cập nhật Hooks & State Management
Cập nhật các custom hooks hiện tại đang dùng `supabase.rpc` sang dùng các hàm từ `orderApi.ts` và `inventoryApi.ts`.

#### [MODIFY] `src/features/orders/hooks/useOrders.ts` (Ví dụ)
Thay thế `supabase.rpc('create_order', payload)` bằng `orderApi.createOrder(payload)`.

### 4. Cập nhật WebSocket (Clinic Queue - Phase 3)
Chuyển đổi SDK Supabase Realtime sang Native WebSocket hook.

#### [NEW] `src/shared/hooks/useWebSocket.ts`
Hook quản lý kết nối WebSocket tới `wss://[CLOUD_RUN_URL]`, hỗ trợ tự động reconnect và auth token.

## Verification Plan

### Automated Tests
- Chạy lại các luồng test E2E (Playwright) cho chức năng Tạo đơn hàng, Nhập kho để đảm bảo API mới hoạt động mượt mà và không làm hỏng UI cũ.

### Manual Verification
1. Mở giao diện "Tạo Đơn Khách Sỉ/Lẻ".
2. Thử đặt một đơn hàng. Kiểm tra Network Tab xem request POST đã chuyển hướng về `NEXT_PUBLIC_API_URL` với Header chứa Bearer Token chưa.
3. Kiểm tra thông báo lỗi (nếu có) có được handle và hiển thị đúng trên UI bằng Ant Design `message`/`notification` hay không.
