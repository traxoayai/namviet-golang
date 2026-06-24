# Bàn Giao Logic 14: Giao diện Form Tạo Khuyến Mãi Bậc Thang (Advanced Promotions)

Tài liệu này hướng dẫn Team Frontend cập nhật file `src/pages/marketing/DiscountCodeManagement.tsx` để bổ sung Form cấu hình cho các chiến dịch "Mua X tặng Y" hoặc "Tổng Bill đạt X tặng Y" (Không dùng code cứng Mock Data nữa).

## 1. Cập nhật Trường "Loại giảm giá" (`discount_type`)
Trong Modal thêm mới mã Khuyến mãi:
- Bổ sung Option `<Option value="advanced">Quà tặng / Bậc thang</Option>`.

## 2. Dynamic Form (Hiển thị khi `discount_type === 'advanced'`)
Nếu người dùng chọn Loại Khuyến mãi là "Quà tặng / Bậc thang", hãy **ẨN** các trường `value`, `max_discount_value` và hiển thị một khối Form mới gồm 2 phần sau:

### Khối A: Điều kiện mua hàng (Condition)
Sử dụng 1 trường Select để chọn "Loại Điều Kiện":
1. **Mua đạt Số lượng (`buy_quantity`):**
   - Hiện trường chọn `target_product_id` (Tìm kiếm sản phẩm bắt buộc phải mua).
   - Hiện trường `min_quantity` (Số lượng tối thiểu cần mua, VD: 10).
2. **Mua đạt Tổng tiền (`buy_amount`):**
   - Hiện trường `min_amount` (Tổng tiền tối thiểu của toàn bộ giỏ hàng, VD: 2.000.000đ).
   - *Lưu ý: Nếu chọn loại này thì ẨN trường chọn Sản phẩm mục tiêu.*

### Khối B: Cấu hình Quà tặng (Reward)
- **Sản phẩm tặng (`gift_product_id`):** Select/Tìm kiếm Sản phẩm dùng làm quà tặng.
- **Số lượng tặng (`gift_quantity`):** InputNumber (Ví dụ: 1).
- **Trị giá món quà (`gift_value`):** InputNumber định dạng tiền tệ (Ví dụ: 500,000đ - Giá trị này sẽ dùng để render Text bên ngoài POS).
- **Tặng Lũy tiến (`is_multiply`):** Switch Bật/Tắt (Mặc định: Bật).
  - Bật: Mua 20 tặng 2, 30 tặng 3. Tắt: Mua bao nhiêu cũng chỉ tặng 1 lần duy nhất.

---

## 3. Serialization (Đóng gói Payload gửi Backend)
Khi Submit Form, Frontend phải lấy dữ liệu từ Khối A và B để build thành 1 cục JSON lưu vào thuộc tính `advanced_rules` của Payload API tạo Promotion.

**Mẫu Payload khi tạo chiến dịch Mua đạt Số Lượng:**
```json
{
  "code": "MUA10T1",
  "name": "Mua 10 Panadol tặng 1",
  "discount_type": "advanced",
  "advanced_rules": {
    "condition": {
      "type": "buy_quantity",
      "target_product_id": 1001,
      "min_quantity": 10
    },
    "reward": {
      "type": "give_product",
      "gift_product_id": 1001,
      "gift_quantity": 1,
      "discount_percent": 100,
      "gift_value": 0 
    },
    "is_multiply": true
  }
}
```

**Mẫu Payload khi tạo chiến dịch Đạt Tổng Tiền Bill:**
```json
{
  "code": "BILL2TR",
  "name": "Bill 2 Triệu tặng Bình Nước",
  "discount_type": "advanced",
  "advanced_rules": {
    "condition": {
      "type": "buy_amount",
      "min_amount": 2000000
    },
    "reward": {
      "type": "give_product",
      "gift_product_id": 5055,
      "gift_quantity": 1,
      "discount_percent": 100,
      "gift_value": 150000
    },
    "is_multiply": false
  }
}
```

## 4. Xác nhận hoàn tất (Verification)
Sau khi Frontend làm xong Form này, các bạn hãy xóa dữ liệu Mock trong Database, sử dụng trực tiếp UI để tạo 1 mã "Mua đạt tổng bill 2 triệu", sau đó sang trang `CreateB2BOrderPage` add thử sản phẩm vào giỏ để xem quà có tự "nhảy" ra không.
