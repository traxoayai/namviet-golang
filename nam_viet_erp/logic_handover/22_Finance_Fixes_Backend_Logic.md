# Bàn Giao Logic 22: Phục Hồi & Nâng Cấp API Phân Hệ Tài Chính (Backend)

Tài liệu này yêu cầu Team Backend bổ sung các trường dữ liệu bị thiếu và viết thêm 2 API Workflow để khép kín quy trình Duyệt - Thu/Chi tiền.

## 1. Cập Nhật Database Model (Struct Golang)
Trong file `domain/finance.go`, bổ sung các trường sau vào struct `FinanceTransaction` để map chính xác với cấu trúc bảng dưới DB Supabase:
- `PartnerType` (string)
- `PartnerID` (string/uuid)
- `PartnerNameCache` (string) -> Để Frontend có thể hiển thị Tên Người Nhận/Nộp tiền.
- `TargetBankInfo` (jsonb) -> Lưu cấu trúc: `{"bin": "970415", "account_no": "123456", "account_name": "NGUYEN VAN A"}`. Frontend cần cục này để sinh mã QR.
- `BankReferenceID` (string)
- `BusinessType` (string)
- `IsPosted` (bool)

> **Lưu ý:** Nếu khi Insert giao dịch mới (hàm `CreateTransaction`), User truyền lên các trường này, Backend cũng phải map và save xuống Database.

## 2. API Workflow (Chuyển đổi trạng thái Phiếu)
**Quy tắc Nghiệp vụ cốt lõi:**
- Phiếu Thu (Flow = `in`): `pending` (Tạo) -> `completed` (Đã Thu Tiền). (Bỏ qua bước Approve theo chỉ đạo Giám đốc).
- Phiếu Chi (Flow = `out`): `pending` (Tạo) -> `approved` (Quản lý Duyệt Chi) -> `completed` (Đã Xuất Tiền).

### A. API Duyệt Chi
**Endpoint:** `POST /api/v1/finance/transactions/:id/approve`
- **Mục đích:** Dành riêng cho Phiếu Chi (`flow = 'out'`).
- **Validation:** Bắt lỗi nếu phiếu này là Phiếu Thu (`flow = 'in'`), trả về lỗi *"Phiếu thu không cần qua bước Duyệt, vui lòng thu tiền trực tiếp"*.
- **Logic:** Chuyển `status` từ `pending` sang `approved`. (Chưa thao tác gì đến quỹ tiền ở bước này).

### B. API Xuất/Thu Tiền (Hoàn tất)
**Endpoint:** `POST /api/v1/finance/transactions/:id/complete`
- **Mục đích:** Xác nhận dòng tiền thực tế đã vào/ra khỏi công ty.
- **Validation:** 
  - Nếu là Phiếu Chi (`flow = 'out'`), kiểm tra xem trạng thái hiện tại phải là `approved` mới cho phép đi tiếp.
  - Nếu là Phiếu Thu (`flow = 'in'`), cho phép đi tiếp từ trạng thái `pending`.
- **Logic Giao dịch (DB Transaction - Bắt buộc):**
  1. Cập nhật `status = 'completed'`, `is_posted = true`.
  2. Cập nhật bảng `fund_accounts`: 
     - Nếu `in`: Cộng tiền vào quỹ.
     - Nếu `out`: Trừ tiền khỏi quỹ.
  3. Xử lý Chứng từ gốc (`RefType`, `RefID`):
     - Nếu liên kết với Đơn mua/bán (VD: `RefType = 'ORDER'` hoặc `'PURCHASE_ORDER'`), query bảng tương ứng. Tính toán tổng tiền đã thu/chi, nếu đủ tiền thì chuyển `payment_status` của Đơn sang `'paid'` (Đã TT).
