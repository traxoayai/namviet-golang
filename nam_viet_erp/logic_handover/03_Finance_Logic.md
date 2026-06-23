# Bàn Giao Logic 03: Module Tài Chính & Kế Toán (Finance)

Tài liệu này là chỉ thị tuyệt đối cho Team Backend thay thế các RPC: `create_finance_transaction`, `calculate_vat_invoice_allocation`, và quá trình `process_vat_invoice_entry`.

> [!WARNING]
> Tuyệt đối KHÔNG xóa các RPC/Trigger cũ trong CSDL. Code Golang chạy song song.

## 1. Yêu Cầu Kiến Trúc (Backend)
- Gói: `finance_handler.go`, `finance_service.go`, `finance_repository.go`.
- Config: Luật thuế (ví dụ hạn mức 5.000.000đ phải chuyển khoản) bắt buộc đưa vào file `.env` hoặc `config.yaml`, KHÔNG hardcode.

## 2. Danh Sách API Cần Viết & Logic Cốt Lõi

### API 1: Tạo Giao Dịch Thu/Chi (Finance Transaction)
- **Endpoint:** `POST /api/v1/finance/transactions`
- **Nghiệp vụ:** Viết lại RPC `create_finance_transaction`.
  1. Kiểm tra nếu giao dịch này dùng để thanh toán cho Hóa Đơn VAT (`ref_type = 'INVOICE'`).
  2. Lấy Config `VAT_BANK_TRANSFER_THRESHOLD = 5000000`.
  3. **Quy tắc chặn (Business Rule):** Nếu `amount >= VAT_BANK_TRANSFER_THRESHOLD` VÀ Hóa đơn này có thuế VAT, bắt buộc `fund_account.type` phải là `bank`. Nếu trả bằng `cash`, chặn lại và trả `HTTP 400`.
  4. **Logic Chẻ Phiếu:** Nếu khách thanh toán số tiền lớn hơn hoặc nhỏ hơn giá trị Hóa đơn:
     - Phiếu chính: Ghi vào sổ `BOTH` (Nội bộ & Thuế) với số tiền đúng bằng giá trị hóa đơn.
     - Phiếu phụ (Bù trừ): Ghi vào sổ `INTERNAL` với phần chênh lệch (Chiết khấu hoặc Phụ phí).
  5. Cập nhật `paid_amount` của Hóa đơn. Trạng thái `PAID`, `PARTIAL`, hoặc `UNPAID`.

### API 2: Phân Bổ Hóa Đơn VAT Bán Ra (VAT Allocation)
- **Endpoint:** `POST /api/v1/finance/vat-allocation`
- **Vấn đề cũ:** Thuật toán phân bổ hóa đơn trên PL/pgSQL chạy rất chậm và ngốn CPU DB.
- **Nghiệp vụ (Golang Optimization):**
  1. Frontend gửi yêu cầu: "Tôi cần xuất một Hóa Đơn đỏ tổng giá trị 20.000.000đ cho Khách hàng A".
  2. Golang truy vấn lấy toàn bộ `order_items` của Khách hàng A chưa xuất hóa đơn (chưa có `invoice_id`).
  3. **Thuật toán (Knapsack 0/1):** Chạy thuật toán quy hoạch động (Dynamic Programming) trực tiếp trên RAM của Server Golang để chọn ra một tập hợp các `order_items` sao cho tổng tiền ghép lại gần khớp nhất (hoặc bằng chính xác) với con số 20.000.000đ.
  4. Golang tạo ra một bản nháp (`draft_invoice`). Trả kết quả mảng `items` được chọn về cho Frontend duyệt.

### API 3: Webhook Lắng nghe Hóa đơn điện tử (Tích hợp AI)
- **Endpoint:** `POST /api/v1/webhooks/vat-invoices`
- **Nghiệp vụ:** Khi có file PDF/XML hóa đơn từ Tổng cục thuế đẩy về:
  1. Golang nhận file, upload lên Cloudinary.
  2. Gọi sang API của Google Gemini (Prompt đã có sẵn) để bóc tách (OCR) lấy danh sách mặt hàng, thuế suất.
  3. Trả về Frontend để Kế toán map với mã hàng nội bộ.
