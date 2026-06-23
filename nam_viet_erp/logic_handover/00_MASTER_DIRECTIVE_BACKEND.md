# CHỈ THỊ THỰC THI DỰ ÁN REFACTOR GOLANG API (NAM VIỆT ERP)
**Người gửi:** [Product Owner / Project Manager]
**Người nhận:** Toàn bộ Team Backend (Golang Architect, Backend Developers)
**Độ ưu tiên:** CAO NHẤT (CRITICAL)

---

Chào Team Backend,

Hệ thống ERP của chúng ta đang chuẩn bị bước vào giai đoạn Scale-up. Để khắc phục các "điểm mù" về Race Condition và giảm tải cho Database, chúng ta sẽ bắt đầu chiến dịch **"Big Bang Refactor"**: Chuyển đổi toàn bộ >500 hàm RPCs và Triggers từ PL/pgSQL (Supabase) sang tầng Application bằng **Golang API (Gin & GORM)**.

Team Business Analyst (BA) đã phân tích toàn bộ logic cũ và bóc tách thành 9 tài liệu Bàn Giao Logic cực kỳ chi tiết. Dưới đây là mệnh lệnh thực thi dành cho toàn bộ Team:

## 1. NGUYÊN TẮC TỐI THƯỢNG (BẮT BUỘC TUÂN THỦ)
1. **KHÔNG ĐƯỢC XÓA CODE CŨ:** Tuyệt đối KHÔNG xóa, KHÔNG sửa đổi các hàm RPC (`functions_sql`) và Trigger (`triggers_sql`) hiện tại trong Database. Hệ thống cũ (Frontend hiện tại) vẫn đang vận hành và kiếm tiền. Chúng ta code API mới chạy song song (Parallel Run).
2. **Sử dụng Connection Pooler:** Mọi kết nối GORM phải đi qua cổng `6543` (Supavisor/PgBouncer) của Supabase để chịu tải.
3. **Database Transaction & Lock:** Các module thao tác với tiền và tồn kho (Kho, Đơn hàng, Công nợ, Khuyến mãi) **bắt buộc** phải gom vào chung 1 Global Transaction (`tx := db.Begin()`) và sử dụng khóa dòng `tx.Clauses(clause.Locking{Strength: "UPDATE"})` để chống Race Condition triệt để.

## 2. TÀI LIỆU CẦN ĐỌC KỸ TRƯỚC KHI CODE
Toàn bộ base logic đã được thiết kế sẵn. Các bạn KHÔNG tự chế ra logic mới mà hãy bám sát vào các thư mục sau trong Source Code:

👉 **A. Đọc thư mục Bàn giao Logic (Logic Handover):**
Đường dẫn: `D:\29.NamVietErp-V3\nam_viet_erp\logic_handover\`
Trong này chứa 9 files cho 9 Module cốt lõi (Kho, Đơn hàng, Tài chính, Y Tế, Logistics...).
Đọc file `01_Inventory_Logic.md` đến `09_System_AI_Logic.md` để biết chính xác API nào cần viết, quy tắc trừ tiền/kho ra sao.

👉 **B. Đọc thư mục Kịch bản Test (QA Test Cases):**
Đường dẫn: `D:\29.NamVietErp-V3\nam_viet_erp\docs\test_cases\`
Trong này chứa các test case từ `TC_01` đến `TC_09`. Đây là thước đo nghiệm thu của Team QA. Backend code xong phải pass được các kịch bản này (như bắn 5 request đồng thời, test chống trùng lịch) mới được tính là hoàn thành.

## 3. CÔNG VIỆC CỤ THỂ CỦA TEAM BACKEND
Các bạn tiến hành làm việc theo trình tự sau:

1. **Khởi tạo Base Project:** Dựng khung Golang, Gin, GORM. Cấu hình middleware bắt Supabase JWT. Cài đặt các package như `gorm.io/datatypes` để xử lý mảng và JSONB.
2. **Chia Module Thực Thi:** Bắt đầu code theo thứ tự ưu tiên của tài liệu Handover:
   - Phase 1: Module Kho (Inventory) & Module Bán Hàng (Orders).
   - Phase 2: Module Tài Chính (Finance) & Công Nợ B2B (CRM). *(Lưu ý: Viết thuật toán Knapsack trên RAM Golang để chẻ hóa đơn).*
   - Phase 3: Module Y Tế (Clinic) - Setup `LISTEN/NOTIFY` Postgres kết hợp WebSocket Server.
   - Phase 4: Các Module còn lại (Khuyến mãi, Vận chuyển, AI...).
3. **Viết Swagger:** Sau khi xong API nào, phải comment `swag init` cho API đó ngay lập tức để team Frontend có tài liệu đối chiếu.
4. **Self-Test:** Viết Unit Test và dùng file `.http` để tự test các luồng trong thư mục `test_cases` trước khi bàn giao sang QA/Frontend.

Yêu cầu anh em Backend Architect vào nhận Job, đọc kỹ file Bàn giao và lên kế hoạch Sprint. Có chỗ nào chưa rõ về logic, báo lại ngay cho BA để điều chỉnh.

Thực thi ngay!
