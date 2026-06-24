# Bàn Giao Logic 13: Gợi ý Khuyến mãi (Upsell) & Tự động thêm Quà tặng

Tài liệu này là chỉ thị thiết kế luồng Gợi ý Upsell tự động trên trang Bán sỉ (B2B). Các quyết định dưới đây đã được Giám đốc dự án phê duyệt.

## 1. Yêu cầu Backend (API & DB)

### 1.1. Cập nhật cấu trúc JSONB `advanced_rules`
Để giải quyết bài toán hiển thị giá trị phần quà (Ví dụ: "Tặng máy sấy tóc trị giá 500k"), cấu trúc JSONB của bảng `promotions` cần được Backend bổ sung thêm trường `gift_value` (Giá trị quy đổi của quà tặng).

**Ví dụ:**
```json
{
  "condition": { "type": "buy_quantity", "target_product_id": 1001, "min_quantity": 10 },
  "reward": { 
    "type": "give_product", 
    "gift_product_id": 1002, 
    "gift_quantity": 1, 
    "discount_percent": 100,
    "gift_name": "Máy sấy tóc Panasonic", 
    "gift_value": 500000 // Thêm trường này
  },
  "is_multiply": true
}
```

### 1.2. API lấy danh sách Khuyến mãi tự động
- Viết thêm API `GET /api/v1/promotions/auto-suggest`.
- API này trả về danh sách các `advanced_rules` đang Active. Frontend sẽ fetch 1 lần khi load trang `CreateB2BOrderPage` và lưu vào Global State để tự map với các sản phẩm được thêm vào Giỏ.

---

## 2. Yêu cầu Frontend (UI/UX & Logic)

### 2.1. Cập nhật Logic Auto-Add (Tự động chèn Quà tặng)
Trong Hook quản lý Giỏ hàng (`useCreateOrderB2B.ts` hoặc store tương tự):
- Lắng nghe sự kiện khi nhân viên thay đổi Số lượng (Quantity) của `CartItem`.
- So sánh với bộ luật (Rules) đã fetch từ API `auto-suggest`.
- **NẾU** `quantity >= min_quantity`: TỰ ĐỘNG chèn món quà (Gift Item) vào mảng `items`. Set `is_gift = true`, `price = 0`, và khóa (Lock) input số lượng/nút Xóa của món quà.
- **Lưu ý:** Xử lý cẩn thận tham số `is_multiply = true`. Nếu Mua 10 tặng 1, mà khách tăng số lượng lên 20, thì Gift Item phải tự động tăng `quantity` lên 2. Nếu khách giảm xuống 9, tự động xóa Gift Item.

### 2.2. Nâng cấp Giao diện `SalesOrderTable.tsx`
Frontend áp dụng 2 kịch bản hiển thị giao diện Gợi ý Upsell ở ngay cột **Sản phẩm** hoặc **Đơn giá**:

**Kịch bản 1: MUA A TẶNG A (Tính Giá Cuối)**
- Nếu `target_product_id == gift_product_id`:
- Hiển thị Text Highlight: `🎁 Mua 10 tặng 1`
- Tại cột Đơn giá: 
  - Giá gốc: Hiện chữ xám, gạch ngang `~100.000 ₫~`
  - Giá cuối: Bôi đậm, màu đỏ/cam, size to. Công thức tính: `(SL Mua * Đơn giá) / (SL Mua + SL Tặng)`. Ví dụ: `90.909 ₫`.

**Kịch bản 2: MUA A TẶNG B (Hiển thị Giá trị Quà tặng)**
- Nếu `target_product_id != gift_product_id`:
- KHÔNG gạch ngang giá gốc, giữ nguyên giá bán.
- Hiện Text Highlight nổi bật: `🎁 Tặng [gift_name] trị giá [gift_value]đ (Khi mua đủ [min_quantity] sản phẩm)`
- Ví dụ: `🎁 Tặng Máy sấy tóc Panasonic trị giá 500.000 ₫ (Khi mua đủ 5 sản phẩm)`.
