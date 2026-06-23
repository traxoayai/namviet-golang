# NAM VIET ERP - MASTER RULES

Mọi AI Agent tham gia dự án BẮT BUỘC phải tuân thủ nghiêm ngặt các quy tắc sau:

1. **Môi trường:** Hệ thống làm việc trên **Windows OS**. Mọi đường dẫn file phải dùng chuẩn Windows (VD: `D:\29.NamVietErp-V3\nam_viet_erp\...`). Dùng PowerShell cho các lệnh terminal.
2. **Kiến trúc Di sản (Legacy Database):** Tuyệt đối tôn trọng cấu trúc Database PostgreSQL hiện hành (đang chứa các bảng lịch sử và trigger cũ). Không tự ý phá vỡ quan hệ khóa ngoại. Nếu cần thêm bảng/cột, BẮT BUỘC sinh file `.sql` migrate và ghi đè nội dung vào file `database_schema.md`.
3. **Tiêu chuẩn Bảo mật (OWASP API Security):**
   - Mọi API Golang phải có middleware kiểm tra JWT (Authentication) và phân quyền Role-based (Authorization).
   - Bảo vệ tuyệt đối khỏi SQL Injection (Chỉ dùng GORM/Prepared Statements).
   - WebSockets kết nối tới Cloud Run phải có cơ chế cấp/kiểm tra Ticket Token ngắn hạn.
4. **Bàn giao (Handover):** Backend và Frontend KHÔNG giao tiếp bằng lời nói suông. Backend phải cung cấp `swagger.json` và file Markdown "Bàn giao Logic" (đánh số thứ tự). Frontend chỉ được code dựa trên 2 tài liệu này. Các file handover được tạo và lưu trữ tại 'D:\29.NamVietErp-V3\nam_viet_erp\logic_handover'
5. **Viết Implementation Plan:** Backend và Frontend trước khi code, nếu viết file implementation plan và walkthrought thì cần tạo các file riêng biệt (không được ghi đè vào file cũ) và có đánh số thứ tự. Phía backend sẽ lưu 2 loại file này tại đường dẫn 'D:\29.NamVietErp-V3\nam_viet_erp_backend\backend_implementation_plan' và Frontend sẽ lưu 2 loại file này tại đường dẫn 'frontend_implementation_plan'
