# Bàn Giao Logic 07: Module Mua Hàng & Nhà Cung Cấp (Purchasing)

Tài liệu này thay thế logic của RPC `create_purchase_order`.

## 1. Yêu Cầu Kiến Trúc (Backend)
- Gói: `purchasing_handler.go`, `purchasing_service.go`, `purchasing_repository.go`.

## 2. API & Logic Cốt Lõi

### API 1: Tạo Đơn Đặt Hàng (Purchase Order)
- **Endpoint:** `POST /api/v1/purchasing/orders`
- **Nghiệp vụ:**
  1. Parse Body Request (supplier_id, items: `[{product_id, quantity_ordered, unit, unit_price, is_bonus}]`).
  2. Bắt đầu Transaction `tx := db.Begin()`.
  3. Insert bảng `purchase_orders` với `status = 'pending'`, sinh mã PO tự động (VD: `PO-2606-ABCD`).
  4. Duyệt từng mặt hàng:
     - Nếu `is_bonus = true` (Hàng tặng), ép buộc `unit_price = 0`.
     - Truy vấn bảng `products` để lấy `wholesale_unit` và `items_per_carton`.
     - **Tính toán hệ số (Conversion Factor):** Nếu `unit == wholesale_unit` thì `conversion_factor = items_per_carton`, ngược lại là 1. Tính `base_qty`.
     - Insert bảng `purchase_order_items`.
  5. Cập nhật `total_amount` của đơn hàng.
  6. Commit transaction.
