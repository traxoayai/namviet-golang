# Bàn Giao Logic 16: API Quản lý Khuyến Mãi Nhà Cung Cấp & Bridge B2B (Backend)

Tài liệu Đặc tả Nghiệp vụ này hướng dẫn Team Backend xây dựng phân hệ Quản lý Khuyến Mãi của Nhà Cung Cấp (Supplier Promotions) và Cầu nối (Bridge) chuyển đổi Khuyến Mãi Nhập thành Khuyến Mãi Bán.

## 1. Cấu trúc Database Mới
Tạo bảng `supplier_promotions` để lưu trữ luật Khuyến Mãi chiều Nhập hàng.
```sql
CREATE TABLE supplier_promotions (
    id BIGSERIAL PRIMARY KEY,
    vendor_tax_code TEXT NOT NULL,
    promotion_name TEXT NOT NULL,
    valid_from TIMESTAMP WITH TIME ZONE,
    valid_to TIMESTAMP WITH TIME ZONE,
    advanced_rules JSONB NOT NULL, -- Cấu trúc giống hệt bảng promotions hiện tại
    status TEXT DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 2. API 1: Auto-Suggest Gợi ý Mua hàng
**Endpoint:** `POST /api/v1/supplier-promotions/auto-suggest-for-purchase`
- **Mục đích:** Khi nhân viên Mua hàng đang lên Đơn nháp, gọi API này để xem đơn hàng có thỏa mãn hoặc sắp thỏa mãn Khuyến mãi nào của NCC không.
- **Request Payload:**
  ```json
  {
    "vendor_tax_code": "0101234567",
    "cart_items": [
      { "vendor_product_name": "Panadol Xanh", "quantity": 8 }
    ]
  }
  ```
- **Logic Xử Lý:**
  1. Lấy tất cả `supplier_promotions` đang active của `vendor_tax_code` này.
  2. Chạy thuật toán so khớp `advanced_rules`. Nếu `cart_items` đạt từ 80% - 100% điều kiện, trả về gợi ý: *"Mua thêm 2 sản phẩm nữa để nhận 1 Quà tặng"*.

## 3. API 2: Bridge B2B (Tính Toán Lợi Nhuận Tự Động)
**Endpoint:** `POST /api/v1/supplier-promotions/bridge-b2b`
- **Mục đích:** Khi Nhân viên Mua hàng muốn đẩy Quà tặng của NCC thành chương trình B2B cho đại lý, API này sẽ tự động tính toán lại Điều kiện để "cắn" phần chênh lệch lợi nhuận cho công ty.
- **Request Payload:**
  ```json
  {
    "supplier_promotion_id": 123
  }
  ```
- **Logic Thuật Toán (Auto-Margin):**
  1. Đọc rules của `supplier_promotion_id`. Giả sử rule là Mua Đạt Số Lượng (VD: Mua 10 tặng 1).
  2. Map `vendor_product_name` ra `internal_product_id` (Dùng bảng `vendor_product_mappings`).
  3. Lấy thông tin Lãi biên từ bảng `products`: Lấy `wholesale_margin_value` và `conversion_factor`.
  4. Tính toán Điều kiện B2B Mới (B2B_Min_Quantity) theo công thức:
     `B2B_Min_Quantity = Supplier_Min_Quantity + (wholesale_margin_value / conversion_factor)`
     *(Làm tròn lên Integer).*
  5. Đóng gói lại thành cấu trúc JSON `advanced_rules` chuẩn của Khuyến mãi Bán ra (Bảng `promotions`).

- **Response:** Trả về nguyên 1 cục JSON cấu trúc Khuyến Mãi B2B để Frontend có thể bê thẳng vào Form điền tự động.
