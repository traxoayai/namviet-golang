# Bàn Giao Logic 10: Phân Hệ Nhân Sự (HR Management)

Tài liệu này là chỉ thị thiết kế Giao diện (UI) và API cho Team Frontend & Backend để hoàn thiện Phân hệ Nhân sự (Thiếu từ Mục 5 đến Mục 11 trong System Features).

## 1. Yêu Cầu UI/UX (Frontend Team)
Giao diện phải được xây dựng trong thư mục `src/pages/hr/`.

### 1.1. Giao diện Hồ Sơ Nhân Viên (`EmployeeProfilePage.tsx`)
- **List View:** Bảng hiển thị nhân viên (Mã NV, Tên, Chi nhánh, Trạng thái, Loại HĐ). Có nút "Bộ lọc" theo phòng ban, chi nhánh.
- **Detail View (Tabs):**
  - Tab 1: Thông tin cơ bản (Avatar, SĐT, Email, CCCD).
  - Tab 2: Hồ sơ giấy tờ (Upload PDF CV, Bằng cấp y khoa/dược).
  - Tab 3: Quá trình thăng tiến & Hợp đồng (Lịch sử các lần ký HĐ).
  - Tab 4: Lịch sử nhận lương.
  - Tab 5: Chứng chỉ đào tạo nội bộ.

### 1.2. Giao diện Hợp Đồng & Lương (`ContractTypePage.tsx`)
- Form cấu hình tự động: Khai báo "Hợp đồng thử việc". Cấu hình: "Lương cơ bản = 3.000.000đ", "Chuyển chính thức sau khi đạt KPI X và pass Khóa học Y".

### 1.3. Giao diện Ca Làm Việc (`WorkShiftPage.tsx`)
- Lịch (Calendar View) hiển thị các ngày trong tuần.
- Cho phép Nhân viên kéo-thả (Drag & Drop) để đăng ký ca làm (Sáng, Chiều, Tối).
- Quản lý duyệt: Nút "Duyệt ca" dành cho Quản lý chi nhánh.

## 2. Yêu Cầu Logic & API (Backend Team)
- `GET /api/v1/hr/employees`: Lọc danh sách nhân sự có phân trang.
- `POST /api/v1/hr/shifts/register`: Đăng ký ca làm. 
  - **Logic chặn:** Không cho phép 1 nhân sự đăng ký 2 ca trùng giờ.
- `POST /api/v1/hr/payroll/calculate`: Cronjob tự động tính lương cuối tháng = Lương cơ bản (từ Hợp đồng) + Thưởng KPI + Thưởng Hoa hồng đơn hàng (Mapping với bảng Orders).
