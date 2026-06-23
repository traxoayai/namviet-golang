# Nam Viet ERP - V3 Migration Workflow

**Mục tiêu:** Chuyển đổi tính năng từ hệ thống RPC cũ sang Golang + Cloud Run + WebSockets.

**Bước 1: Phân tích & Viết Test Case (AI BA & QA)**

- Yêu cầu AI đọc file `D:\29.NamVietErp-V3\nam_viet_erp\system_feature.md` và `D:\29.NamVietErp-V3\nam_viet_erp\database_schema.md`.
- AI viết ra các file Test Case nghiệp vụ và lưu vào thư mục `D:\29.NamVietErp-V3\nam_viet_erp\docs\test_cases\`.

**Bước 2: Xây dựng Backend & Bàn giao (AI Backend Architect)**

- Đọc Test Case ở Bước 1.
- Viết mã nguồn Golang (Gin, GORM, WebSockets).
- **Nhiệm vụ bắt buộc 1:** Nếu có thay đổi DB, tạo file migration `.sql` và cập nhật đè vào `database_schema.md`.
- **Nhiệm vụ bắt buộc 2:** Chạy `swag init` để sinh file `swagger.json`.
- **Nhiệm vụ bắt buộc 3:** Viết file Bàn giao Logic đánh số thứ tự (Ví dụ: `01_Product_Sync_Logic.md`) lưu vào `D:\29.NamVietErp-V3\nam_viet_erp\docs\handover\`.
- **Nhiệm vụ bắt buộc 4:** Tự động chạy Unit Test hoặc viết script `.http` để test API cục bộ.

**Bước 3: Xây dựng Giao diện (AI Frontend Architect)**

- Đọc file Bàn giao Logic ở Bước 2.
- Cập nhật types TypeScript từ file `swagger.json`.
- Viết các component React/Ant Design đáp ứng đúng nghiệp vụ và thiết kế (hỗ trợ cả Desktop & Mobile PWA).

**Bước 4: Kiểm thử tự động (AI QA Automation)**

- Chạy các kịch bản kiểm thử (Playwright/Puppeteer) vào UI/API vừa hoàn thành. Báo cáo kết quả lại cho người dùng.
