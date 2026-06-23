# Bàn Giao Logic 06: Module Khuyến Mãi (Promotions & Marketing)

Tài liệu này thay thế logic của RPC `verify_promotion_code`.

## 1. Yêu Cầu Kiến Trúc (Backend)
- Gói: `promotion_handler.go`, `promotion_service.go`.
- Đặc biệt lưu ý hiệu năng, các flash-sale sẽ gọi API verify voucher hàng chục ngàn lần một giây. Cần có cơ chế Cache Redis trước khi vào Database nếu có thể.

## 2. API & Logic Cốt Lõi

### API 1: Xác Thực Mã Khuyến Mãi (Verify Voucher)
- **Endpoint:** `POST /api/v1/promotions/verify`
- **Nghiệp vụ:**
  1. Nhận `voucher_code`, `customer_id`, `order_value`.
  2. **[QUAN TRỌNG]** Mở Transaction và Lock dòng Promotion: `tx.Clauses(clause.Locking{Strength: "UPDATE"}).Where("code = ?", code).First(&promo)`. Điều này ngăn chặn 10.000 user cùng dùng 1 mã voucher chỉ có 100 lượt.
  3. Validate:
     - Trạng thái `active`.
     - Nằm trong khung giờ `valid_from` và `valid_to`.
     - `usage_count < total_usage_limit`.
     - `order_value >= min_order_value`.
  4. Nếu Voucher cá nhân (type `personal`), kiểm tra `promo.customer_id == customer_id`.
  5. Tính toán giảm giá: Nếu `discount_type == percentage`, tính `(order_value * value)/100`, không vượt quá `max_discount_value`.
  6. Trả về `discount_amount` và `promotion_id`. Không update `usage_count` ở API này (sẽ update ở API Submit Order).
