# Bàn Giao Logic 21: Giao Diện Quản Trị KPI và Bảng Lương (Frontend)

Tài liệu này hướng dẫn Team Frontend xây dựng Giao diện (UI) để tương tác với Động cơ KPI Mới.

## 1. Màn Hình Giao KPI (Dành cho Ban Giám Đốc / Trưởng Phòng)
**Routing:** `/hr/kpi-assignments`

**Phân quyền Hiển thị (RBAC):**
- Frontend phải check Role của User hiện tại đang đăng nhập. Màn hình này **CHỈ HIỂN THỊ** nếu Role = `Admin` | `Director`, HOẶC cột Permissions có cờ `can_assign_kpi = true`.
- Nếu là Trưởng phòng (Manager), lưới nhân sự chỉ được load (fetch) những nhân viên thuộc Phòng ban của họ.

**Thiết kế Giao diện (Data Grid):**
- Giao diện dạng Lưới nhập liệu (Editable Table tương tự Excel).
- Chọn **Tháng / Năm** ở góc trên.
- Chọn **Phòng Ban** (Nếu là Admin thì xem được hết, nếu là Trưởng phòng thì bị khóa (Disable) ở phòng của họ).
- Lưới hiển thị: `[Tên Nhân Viên] | [Chọn Chỉ Số (Dropdown lấy từ hr_kpi_metrics)] | [Ô điền Target Value (Dạng số)]`
- Khi bấm "Lưu Tất Cả", Frontend đóng gói thành mảng Payload và bắn POST API `api/v1/hr/kpi-targets`.

## 2. Màn Hình Báo Cáo Tiến Độ (Dành cho Cá Nhân)
**Routing:** Hiển thị dưới dạng Widget ngay tại Trang chủ nội bộ (Dashboard) của nhân viên.
- **UI Component:** Sử dụng `Progress Bar` (Thanh tiến độ của Ant Design).
- Fetch API lấy Actual Value và Target Value của tháng hiện tại.
- **Logic màu sắc:**
  - < 50%: Màu Đỏ (Danger).
  - 50% - 80%: Màu Cam (Warning).
  - \> 80%: Màu Xanh Lá (Success).
- **Text Động lực:** Bổ sung text sinh động: *"Doanh thu của bạn đang là 800tr/1 Tỷ. Cố lên 200tr nữa để đạt KPI nhé!"*

## 3. Cập Nhật Màn Hình Bảng Lương (`hr_payrolls`)
- Tại màn hình Chi tiết Bảng lương cá nhân (Payslip), phần Thu Nhập (Earnings) phải hiển thị chi tiết:
  - Lương cơ bản: 10.000.000đ
  - **Thưởng KPI (`kpi_bonus`):** Giá trị lấy từ DB. Có dấu `[?]` nhỏ bên cạnh. Hover vào sẽ Tooltip ra nguyên nhân (VD: Thưởng giao vượt 120 đơn).
  - **Hoa hồng (`commission`):** Giá trị lấy từ DB. Hover vào xem chi tiết (VD: 2% của 1 Tỷ doanh thu).
