# Bàn Giao Logic 23: Nâng Cấp Trải Nghiệm Giao Diện Tài Chính (Frontend)

Tài liệu này giao nhiệm vụ cho Team Frontend phối hợp xử lý Hiển thị Dữ liệu Ngân hàng, gen Mã QR VietQR và bổ sung các nút bấm luồng duyệt 3 bước.

## 1. Convert Mã BIN Ngân Hàng sang Tên Hiển Thị
Tại Component `TransactionDetailModal.tsx` hoặc màn hình Tạo Phiếu, trường `target_bank_info` từ API trả về sẽ chứa mã BIN (VD: `{"bin": "970415"}`).
- **Yêu cầu:** Frontend KHÔNG được hiển thị "Ngân hàng: 970415". 
- **Giải pháp:** Sử dụng file JSON cấu hình danh sách Bank NAPAS (đã có sẵn trong dự án hoặc có thể tải từ api vietqr) để tra cứu (Lookup). 
- **Kết quả hiển thị mong muốn:** "Ngân hàng: VietinBank" hoặc "Ngân hàng TMCP Công Thương Việt Nam".

## 2. Generate Mã VietQR Thanh Toán
- Khi chi tiết của một giao dịch thỏa mãn 2 điều kiện: Là **Phiếu Chi (`flow = 'out'`)** VÀ trường **`target_bank_info` có giá trị**, Frontend phải hiển thị một ảnh Mã QR tĩnh trên Modal.
- **Thư viện đề xuất:** `qrcode.react`.
- **String Format VietQR (Chuẩn NAPAS):** 
  Chuỗi data QR cần được sinh tự động theo chuẩn VietQR. (Có thể dùng thư viện `vietqr` trên npm để gen payload cho nhanh).
  Thông số truyền vào: `BIN`, `Account Number`, `Amount`, `Description`.
- Nhờ có mã này, người duyệt/thủ quỹ chỉ việc lấy App ngân hàng quét trực tiếp trên màn hình ERP mà không cần copy paste số tài khoản, tránh sai sót.

## 3. Hệ Thống Nút Bấm Workflow (Approval Buttons)
Bổ sung các cụm nút xử lý (Actions) tại danh sách hoặc chi tiết Phiếu Thu/Chi, hiển thị dựa vào quy tắc sau:

### Phiếu Chi (Payment - Outbound)
1. Phiếu đang ở trạng thái `pending`: Hiển thị nút **[Duyệt Chi]**. Khi bấm, gọi API `POST /approve`.
2. Phiếu đang ở trạng thái `approved`: Hiển thị nút **[Đã Xuất Tiền]**. Khi bấm, gọi API `POST /complete`.
3. Phiếu đang ở trạng thái `completed`: Ẩn toàn bộ nút bấm, đóng băng phiếu.

### Phiếu Thu (Receipt - Inbound)
Theo chỉ đạo mới nhất từ Ban Giám Đốc, Phiếu Thu bỏ qua bước Duyệt trung gian để tác nghiệp nhanh.
1. Phiếu đang ở trạng thái `pending`: Hiển thị nút duy nhất **[Đã Thu Tiền]**. Khi bấm, gọi API thẳng vào `POST /complete` (Bỏ qua `/approve`).
2. Phiếu đang ở trạng thái `completed`: Ẩn nút bấm.
