# Bàn Giao Logic 19: Giao Diện Phân Bổ Thanh Toán & Bảng Điều Khiển COD (Frontend)

Tài liệu này cung cấp hướng dẫn xây dựng Giao diện người dùng cho Nhân Viên Giao Vận (Shipper) và Nhân Viên Kế Toán để khép kín luồng thu Tiền Mặt (COD).

## 1. Màn Hình Của Nhân Viên Giao Vận (Mobile/Web Logistics)
Bổ sung tính năng Thu Hộ tại Màn hình Chi tiết Đơn đi giao:
- **UI Component:** Thêm một Nút/Thanh trượt lớn (Swipe to Action hoặc Big Button): **[Đã Nhận Đủ Tiền Mặt]**.
- **UX Flow:** 
  - NVGV giao hàng xong, nhận tiền từ khách, bấm nút. 
  - Frontend gọi API `POST /api/v1/logistics/mark-cod-paid`.
  - Hiển thị hiệu ứng pháo hoa nhẹ / checkmark màu xanh lá: *"Xác nhận thành công! Nợ của khách hàng đã giảm."*
  - Nút biến thành: **[Hủy Nhận Tiền Mặt (Rollback)]** (Phòng hờ NVGV bấm nhầm, cho phép Undo). Gọi API `rollback-cod`.

## 2. Màn Hình Của Kế Toán (Finance Module)

### A. Nested Table: Chi Tiết Phân Bổ Phiếu Thu
Tại trang Quản lý Phiếu Thu/Chi (`FinanceTransactions`):
- Khi 1 Phiếu thu liên kết với nhiều Đơn hàng, hiển thị icon hình cái cây / mũi tên xổ xuống ở đầu hàng (Table Expandable Row của Ant Design).
- Bấm vào sẽ trượt ra một bảng con (Nested Table) gọi từ bảng `finance_transaction_allocations`, hiển thị:
  | Mã Đơn Hàng | Số Tiền Đã Gạch Nợ (Allocated) | Ngày Thực Hiện |

### B. Dashboard Mới: Đối Soát Tiền Mặt Giao Vận
Tạo một trang/Tab hoàn toàn mới: `/finance/logistics-cod-clearance`
- **Giao diện dạng Danh Sách Theo Nhóm (Grouped List / Kanban):**
  Gọi API `GET /api/v1/finance/pending-cod-reports`. Hiển thị dưới dạng các Thẻ (Card) hoặc Bảng, trong đó mỗi Dòng/Thẻ đại diện cho 1 Nhân Viên Giao Vận (NVGV).
  > **Ví dụ Card:** 
  > 👤 **Giao Vận: Nguyễn Văn A**
  > 💰 Tổng tiền đang giữ: **15.000.000 VNĐ** (Chưa nộp)
  > 📦 Từ 5 đơn hàng giao trong ngày hôm nay.
- **Tính năng Duyệt (Approval):**
  - Kế toán chọn một NVGV, chọn tất cả 5 phiếu thu của họ, bấm nút **[Xác Nhận Đã Thu Tiền]**.
  - Frontend gọi API `POST /api/v1/finance/confirm-cod-deposit`.
  - Tiền rơi vào "két sắt", thẻ của NVGV A trở về 0 VNĐ.

## 3. Quản Trị KPIs Nhân Viên Giao Vận (Mở rộng Tương lai)
Dựa trên màn hình Đối Soát trên, Frontend có thể vẽ thêm 1 Biểu đồ Doanh thu thu hồi (Cash Collected Bar Chart) để Kế toán trưởng xem nhanh: *"Tháng này NVGV nào thu hồi tiền mặt xuất sắc nhất?"*
