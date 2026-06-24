# Bàn Giao Logic 17: Giao Diện Auto-Suggest Mua Hàng & Bridge Khuyến Mãi B2B (Frontend)

Tài liệu này hướng dẫn Team Frontend xây dựng luồng UI liên kết ngang giữa Phân hệ Mua Hàng (Procurement) và Phân hệ Khuyến Mãi (Marketing). Giám đốc dự án yêu cầu xây dựng **một Modal hoàn toàn mới**, không được dùng chung với màn hình `DiscountCodeManagement.tsx`.

## 1. Tích hợp Auto-Suggest vào Màn Hình Lên Đơn Mua Hàng
Tại màn hình tạo Purchase Order (`PurchaseOrderPage.tsx` hoặc tương đương):
- **Trigger:** Mỗi khi người dùng thêm/sửa/xóa sản phẩm vào giỏ Mua Hàng, Frontend thực hiện **Debounce 500ms** và gọi API: 
  `POST /api/v1/supplier-promotions/auto-suggest-for-purchase`
- **Giao diện (UI Alert):** 
  - Nếu API trả về gợi ý, hiển thị một `Alert` (Ant Design) màu Xanh (Info) hoặc Cam (Warning) ngay bên dưới lưới sản phẩm.
  - *Text mẫu:* "Nhà cung cấp đang có chương trình Mua 10 tặng 1. Đơn mua của bạn đang là 8, thêm 2 sản phẩm nữa để nhận quà!"
  - Thêm một nút nhỏ bên cạnh: **[+] Tự động thêm 2 sản phẩm vào đơn**.

## 2. Modal Cầu Nối Khuyến Mãi (SupplierToB2BPromoModal.tsx)
**Bối cảnh:** Sau khi Đơn Mua Hàng được lưu thành công VÀ có chứa Sản phẩm Quà Tặng từ NCC, hiển thị ngay một Dialog/Modal hỏi người dùng có muốn chuyển món quà này thành Khuyến Mãi Bán ra cho Khách hàng không.

**Thiết kế Component `SupplierToB2BPromoModal.tsx`:**
Đây là một Modal chuyên dụng, giao diện chia làm 2 khối so sánh:

- **Khối Trái (Gốc từ Nhà Cung Cấp - Read Only):** 
  Hiển thị thông tin chương trình gốc. (VD: Mua 10 Thùng tặng 1 Thùng).
  
- **Khối Phải (Khuyến Mãi B2B Sẽ Tung Ra - Editable):**
  - Khi Modal bật lên, Frontend tự động gọi API `POST /api/v1/supplier-promotions/bridge-b2b` truyền lên ID của khuyến mãi NCC.
  - Backend sẽ trả về cấu hình Khuyến mãi B2B **đã được tính toán cộng dồn Biên lợi nhuận (Auto-Margin)**.
  - Frontend lấy dữ liệu đó điền sẵn (Auto-fill) vào các trường Form ở Khối Phải (VD: Hệ thống điền sẵn Mua 12 Thùng tặng 1 Thùng).
  - Cho phép người dùng sửa lại tên Voucher, Mã Code và số lượng (nếu họ muốn tự chỉnh tay).

**Hành động Submit:**
- Khi bấm **"Lưu & Kích Hoạt Khuyến Mãi B2B"**, Frontend thu thập dữ liệu từ Form Khối Phải, đóng gói thành Payload chuẩn và đẩy thẳng xuống database Supabase (bảng `promotions`) thông qua Supabase JS Client (Tương tự như luồng của trang Marketing).
- Hiển thị Toast thông báo thành công: *"Chương trình Khuyến Mãi B2B đã được kích hoạt thành công!"*.
