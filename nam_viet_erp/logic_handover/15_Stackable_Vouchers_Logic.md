# Bàn Giao Logic 15: Thuật toán Cộng dồn Khuyến Mãi (Stackable Vouchers)

Tài liệu Đặc tả Nghiệp vụ này hướng dẫn Team Backend và Frontend xây dựng cơ chế Cộng dồn Voucher theo chuẩn E-commerce, với thuật toán bảo vệ lợi nhuận và cơ chế Khóa chéo linh hoạt. Đã được phê duyệt bởi Giám đốc Dự án.

## 1. Cơ chế Khóa Chéo Khuyến Mãi (Combinable Logic)
Thay vì dùng 1 cờ `is_stackable` (đúng/sai) đơn giản, hệ thống sẽ sử dụng cơ chế **Nhóm Khuyến Mãi (Combinable Groups)** để cho phép thiết lập logic: "Voucher A được dùng chung với C nhưng không được dùng chung với B".

### Cập nhật Database (Bảng `promotions`)
Backend cần thêm 2 cột mới:
- `promo_group` (Varchar): Định danh nhóm của Voucher này. Gồm các giá trị:
  - `cash` (Giảm tiền mặt)
  - `percent` (Giảm phần trăm)
  - `gift` (Tặng quà / Bậc thang)
  - `freeship` (Miễn phí vận chuyển)
- `combinable_groups` (JSONB Array): Danh sách các nhóm được phép áp dụng chung.
  - VD: Voucher A (cash) có `combinable_groups = ["gift", "freeship"]`. Khi user đẩy lên 2 mã A và B (percent), hệ thống kiểm tra B thuộc nhóm `percent` không nằm trong mảng allowed của A -> Trả lỗi từ chối.

### Cập nhật Frontend (`DiscountCodeManagement.tsx`)
Khi Tạo Voucher mới, thêm 1 trường Multi-Select (Chọn nhiều):
- Label: **"Được phép áp dụng chung với:"**
- Options: Giảm tiền mặt, Giảm %, Tặng Quà, Freeship.
- Value lưu thành mảng gửi xuống API lưu vào `combinable_groups`.

## 2. Thứ tự Tính toán Toán học (Calculation Priority)
Thuật toán tại `POST /api/v1/promotions/verify` BẮT BUỘC tuân thủ trình tự sau (để bảo vệ lợi nhuận):
- **Bước 1 (Gifts):** Lấy tất cả các mã Nhóm `gift` -> Nhét quà tặng vào mảng `gifts`. Tổng tiền (`subtotal`) không đổi.
- **Bước 2 (Cash Deduct):** Lấy mã Nhóm `cash` -> Trừ trực tiếp số tiền giảm vào `subtotal`. (Subtotal mới = Subtotal cũ - Tiền mặt).
- **Bước 3 (Percent Deduct):** Lấy mã Nhóm `percent` -> Tính phần trăm (%) dựa trên **Subtotal mới** (sau khi đã trừ tiền mặt ở Bước 2).
- **Bước 4 (Freeship):** Lấy mã Nhóm `freeship` -> Trừ vào Phí Vận Chuyển, không chạm vào Tiền hàng.

## 3. Quy trình Xử lý của API Verify
Khi nhận được array `codes = ["CODE_A", "CODE_B"]`:
1. Loop qua lấy chi tiết DB của tất cả các codes.
2. Kiểm tra **Cross-Validation**: Duyệt qua từng Code, kiểm tra `promo_group` của các Code còn lại có nằm trong `combinable_groups` của Code hiện tại không. NẾU KHÔNG -> Throw Error 400: *"Mã {CODE_A} không thể áp dụng chung với loại mã {CODE_B}"*.
3. Kiểm tra số lượng: Không cho phép 2 mã cùng thuộc 1 `promo_group` (VD: Không được dùng 2 mã Giảm tiền mặt cùng lúc).
4. Áp dụng Thuật toán trừ tiền 4 Bước nêu trên.
5. Trả về Response: `final_amount`, `discount_amount`, `gifts`.

---
> **Lưu ý cho Backend:** Thuật toán tính phần trăm trên "Giá sau khi trừ tiền mặt" (Bước 2 -> Bước 3) là thuật toán tối thượng để tránh lỗ. Cần test kỹ case này bằng Unit Test.
