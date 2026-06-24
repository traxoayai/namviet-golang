# Bàn Giao Logic Bổ Sung: Khuyến Mãi Bậc Thang (Advanced Promotions)

Tài liệu này bổ sung thiết kế cho Module Khuyến mãi (Mục 50). Xử lý các kịch bản khó như: **Mua X tặng Y**, **Mua 10 tặng 1**, **Combo**.

## 1. Thiết Kế Database (Dành cho Backend)

Như Giám đốc dự án đã định hướng, do các kịch bản khuyến mãi thực tế thay đổi rất nhiều và phức tạp, nếu lưu bằng các cột Relation (bảng trung gian) sẽ dẫn đến rác Database và query rất chậm. 
**GIẢI PHÁP BẮT BUỘC:** Sử dụng kiểu dữ liệu `JSONB` của PostgreSQL để lưu linh hoạt các luật (Rules) này.

### Thêm cột vào bảng `promotions`:
- Cột `promotion_class` (varchar): `basic` (Giảm tiền/%) hoặc `advanced` (Mua X tặng Y, Combo).
- Cột `advanced_rules` (JSONB): Chứa cấu trúc rule.

**Cấu trúc JSONB Chuẩn (Ví dụ: Mua 10 Hộp Panadol tặng 1 Hộp Panadol):**
```json
{
  "condition": {
    "type": "buy_quantity",
    "target_product_id": 1001,
    "min_quantity": 10
  },
  "reward": {
    "type": "give_product",
    "gift_product_id": 1001,
    "gift_quantity": 1,
    "discount_percent": 100 
  },
  "is_multiply": true 
  // is_multiply = true nghĩa là Mua 20 tặng 2, Mua 30 tặng 3. False là chỉ tặng 1 lần.
}
```

## 2. Yêu Cầu Giao Diện (Dành cho Frontend)
Bổ sung Tab "Khuyến mãi Nâng cao" vào file `DiscountCodeManagement.tsx`:

### 2.1. Rule Form Builder
- Chọn "Loại điều kiện" (Dropdown): 
  - Mua Đạt Số Lượng (Buy Quantity).
  - Mua Đạt Số Tiền (Buy Amount).
- Chọn "Loại Quà tặng" (Dropdown):
  - Tặng Hiện Vật (Sản phẩm B, Giá 0 đồng).
  - Trợ giá Sản phẩm B (Ví dụ Mua Điện thoại, giảm 50% Phụ kiện).

### 2.2. Xử lý Logic tại POS / Cart
Khi nhân viên bấm nút "Áp dụng Mã", Frontend truyền danh sách Giỏ hàng (Cart Items) xuống API `/api/v1/promotions/verify`.
- Backend duyệt qua JSONB `advanced_rules`.
- Nếu Cart thỏa mãn `condition`, API trả về 1 Item quà tặng.
- Frontend tự động "Add to Cart" sản phẩm quà tặng đó với giá `0đ` và gắn mác `[Quà tặng]`.
