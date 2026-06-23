# QUY TẮC CẤU TRÚC VÀ ĐẶT TÊN FILE (STRICT FILE STRUCTURE RULES)

Mọi AI khi tạo file mới trên môi trường `D:\29.NamVietErp-V3\...` BẮT BUỘC phải tuân thủ quy tắc đặt tên **phản ánh chính xác mục đích và nghiệp vụ**, tuyệt đối không đặt tên chung chung như `main.go`, `index.tsx`, `helper.go`.

## 1. Đối với Backend (Golang)

Áp dụng cấu trúc Clean Architecture. Tên file `.go` phải là tiếng Anh, viết thường, phân cách bằng dấu gạch dưới (snake_case) và chứa "hậu tố" chỉ định rõ vai trò của file:

- **Tầng Handler (Giao tiếp API/WebSocket):** `[tên_nghiệp_vụ]_handler.go` (VD: `invoice_sepay_handler.go`, `order_websocket_handler.go`).
- **Tầng Service (Logic cốt lõi):** `[tên_nghiệp_vụ]_service.go` (VD: `inventory_allocation_service.go`, `promotion_calculator_service.go`).
- **Tầng Repository (Truy xuất DB GORM):** `[tên_bảng]_repository.go` (VD: `finance_invoices_repository.go`, `product_inventory_repository.go`).
- **Tầng Models/Entities (Cấu trúc dữ liệu):** `[tên_bảng]_model.go` (VD: `customer_b2b_model.go`).
- **Tầng Middleware/Config:** Cần ghi rõ chức năng (VD: `jwt_auth_middleware.go`, `cloud_run_config.go`).

## 2. Đối với Frontend (React/Vite)

Áp dụng cấu trúc Feature-Sliced Design. Tên file component phải viết hoa chữ cái đầu (PascalCase), tên file hook hoặc utility viết thường (camelCase):

- **Components:** Ghi rõ chức năng (VD: `InvoiceSepayButton.tsx`, `PromotionRuleBuilder.tsx`). Không dùng `index.tsx` để chứa logic chính.
- **Hooks:** Bắt đầu bằng chữ `use` (VD: `useWebSocketOrder.ts`, `useSupabaseAuth.ts`).
- **Services (Gọi API):** `[tên_nghiệp_vụ]Api.ts` (VD: `shippingSpxApi.ts`).

## 3. Đối với Database & Tài liệu

- **File Migration SQL:** `[YYYYMMDD_HHMM]_[hành_động]_[tên_bảng].sql` (VD: `20260623_1430_add_sepay_columns_to_finance_invoices.sql`).
- **File Bàn giao Logic:** `[Số_Thứ_Tự]_[Tên_Module]_Logic.md` (VD: `03_SPX_Shipping_Webhook_Logic.md`).
