# Handover: Fix "Khách lẻ" on B2B Receipts & Missing Promotion Name

## 1. Vấn đề 1: Lỗi hiển thị "Khách lẻ" khi tạo phiếu thu từ danh sách đơn hàng B2B
**Mô tả:**
Khi người dùng bấm "Thanh toán (Tiền mặt / CK)" từ giao diện `B2BOrderListPage`, phiếu thu tiền luôn hiển thị tên khách hàng là "Khách lẻ" thay vì tên thật của khách hàng (ví dụ: "Quầy Thuốc Mai Hương").

**Nguyên nhân:**
Lỗi này là sự kết hợp của cả Frontend và Backend:
- **Backend:** RPC `get_sales_orders_view` hiện tại **không trả về** `customer_id` (đối với B2B) và `customer_b2c_id` (đối với POS). Nó chỉ trả về `customer_name`. Do đó, Frontend không có ID của khách hàng.
- **Frontend:** Do thiếu `customer_id`, Frontend truyền `partner_id = undefined` và `partner_type = "customer"` vào `FinanceFormModal`. Trong form này, khi trường `partner_name` được render dưới dạng *read-only*, nó vô tình **ẩn luôn (không render)** dropdown `partner_type`. Kết quả là khi submit form, `partner_type` bị mất (undefined), khiến code logic fallback về `partner_type = 'other'` và **quên gán** `p_partner_name`. Backend nhận được `p_partner_name = NULL` nên lưu `partner_name_cache = NULL`, dẫn đến phiếu in fallback về "Khách lẻ".

**Khắc phục (Đã sửa Frontend):**
- Frontend đã sửa lỗi form ẩn để luôn submit đủ `partner_type` và `partner_name`, giúp hiển thị đúng tên trên phiếu thu.

**Yêu cầu cho Backend (Quan trọng):**
- **Vấn đề tồn đọng:** Mặc dù phiếu in đã hiện đúng tên, nhưng vì thiếu `customer_id`, giao dịch này đang bị lưu với `partner_id = NULL`. Điều này khiến giao dịch **không được tính vào công nợ** của đối tác một cách chính xác qua wallet.
- **Action:** Cập nhật lại view/RPC `get_sales_orders_view` để **chắc chắn trả về `customer_id`** (id của khách hàng B2B) và **`customer_b2c_id`** (id của khách hàng lẻ POS) trong danh sách orders. 

---

## 2. Vấn đề 2: Lỗi Auto-suggest Promotion không trả về `name`
**Mô tả:**
Khi áp dụng mã giảm giá, API `auto-suggest` trả về thông tin promotion nhưng lại thiếu trường `name` (tên của chương trình khuyến mại). Điều này khiến màn hình `PaymentSummary` không thể hiển thị tên của voucher.

**Action cho Backend:**
- Kiểm tra lại hàm RPC hoặc API xử lý `/promotions/auto-suggest` (có thể là một hàm RPC liên quan đến suggest promotions cho đơn hàng).
- Đảm bảo trong câu `SELECT` có lấy trường `name` từ bảng `promotions` và trả về Frontend. Dữ liệu thực tế cho thấy nó chỉ trả về `id, code, discount_type, ...` mà bỏ sót `name`.
- Sau khi Backend trả về trường `name`, Frontend sẽ tự động hiển thị được do Frontend đã bind sẵn dữ liệu `promotion.name`.
