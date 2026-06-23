# Kế Hoạch Chuyển Đổi "Big Bang Refactor" (Backend Golang)

Dự án này nhắm tới việc chuyển đổi toàn bộ logic phức tạp từ PL/pgSQL (hơn 500 RPCs và Triggers) sang Application Layer bằng Golang (Gin + GORM). Việc chuyển đổi nhằm giải quyết triệt để Race Condition bằng Global Database Transaction và Row-Level Locking, đồng thời giảm tải cho Database.

## 1. Yêu cầu Hệ thống & Base Project (Khởi tạo)

-   **Mô hình Kiến trúc:** Modular Monolith (Core Domain: Inventory, Orders, Finance, Clinic, etc.).
-   **Database Connection:** Sử dụng Connection Pooler (cổng `6543`) để chịu tải cao.
-   **Middleware:**
    -   `Supabase JWT Auth Middleware`: Xác thực Token từ Request Header.
    -   `Role/Permission Middleware`: Phân quyền chi tiết.
-   **Transaction Management:**
    -   Bất kỳ API nào thay đổi trạng thái (Giao dịch tiền, Xuất nhập tồn) đều phải mở Global Transaction (`tx := db.Begin()`) ngay tại Tầng Handler/Service, và truyền `*gorm.DB` xuống các service liên quan để đảm bảo tính ACID.
    -   Sử dụng Row Lock: `tx.Clauses(clause.Locking{Strength: "UPDATE"})`.
-   **Event-Driven & Realtime:**
    -   **EventBus / Goroutine:** Xử lý các tác vụ không đồng bộ (Push Notification FCM, gửi Email) để không block HTTP Request chính.
    -   **WebSockets:** Setup WebSocket Server để push updates trực tiếp xuống Client (Thay thế Supabase Realtime).

## 2. Chiến Lược Thực Thi Chi Tiết

Mặc dù có hơn 500 RPCs và Triggers, chúng ta sẽ bắt đầu refactor theo luồng nghiệp vụ quan trọng nhất (theo các tài liệu Handover), và chuyển đổi song song (hệ thống cũ vẫn chạy).

### Phase 1: Module Kho (Inventory) & Bán Hàng (Orders)
**Dựa trên Handover 01 & 02:**
1.  **Kho (Inventory):**
    -   `POST /api/v1/inventory/validate`: Kiểm tra tồn kho (quy đổi đơn vị).
    -   `POST /api/v1/inventory/deduct`: Trừ tồn kho theo FEFO (First-Expired-First-Out), áp dụng Lock Row.
    -   `POST /api/v1/inventory/receipt`: Nhập kho và phát WebSocket báo realtime.
2.  **Bán Hàng (Orders):**
    -   `POST /api/v1/orders`: Tạo đơn bán (gọi chéo qua Inventory Deduct và Finance Transaction). Gửi sự kiện qua EventBus để Notification Worker đẩy thông báo FCM.

### Phase 2: Module Tài Chính (Finance) & B2B CRM
-   Ghi nhận giao dịch Thu/Chi bằng Transaction.
-   Khấu trừ công nợ khách hàng (Áp dụng thuật toán Knapsack trên RAM của Golang để chẻ/giải quyết hóa đơn nếu có).

### Phase 3 & 4: Clinic, Khuyến mãi, Vận chuyển, AI
-   Thiết lập kênh `LISTEN/NOTIFY` kết hợp WebSocket cho hàng đợi khám bệnh.
-   Áp dụng các logic của Handover còn lại.

## 3. Các Bước Viết Code (Quy Trình Chuẩn)

Với mỗi API:
1.  Tạo interface và struct trong `domain`.
2.  Viết các function truy vấn trong `repository`.
3.  Viết logic nghiệp vụ ở `services`, đảm bảo nhận `tx *gorm.DB`.
4.  Viết HTTP logic ở `handlers` + khai báo `swag init` decorators.
5.  Đăng ký route tại `routes.go`.
6.  Viết `.http` script để tự động test (hoặc Unit Test).
7.  Đánh dấu vào check-list.

## 4. Kế hoạch Kiểm Thử

-   Tạo script `.http` cho từng endpoint.
-   Đảm bảo pass toàn bộ điều kiện trong file `TC_01_Inventory.md` và `TC_02_Orders.md`.
