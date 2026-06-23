# Bàn Giao Logic 11: Từ Điển Y Tế (Medical Dictionary)

Tài liệu chỉ thị xây dựng Nhóm dữ liệu Lõi Y Tế (Mục 41 - 44).

## 1. Yêu Cầu UI/UX (Frontend Team)
Xây dựng trong `src/pages/medical/`

### 1.1. Giao diện Danh Sách Bệnh (`DiseaseDictionaryPage.tsx`)
- Form CRUD Bệnh (Tên bệnh, Mã DIC10).
- Component chọn "Triệu chứng điển hình" dạng Tags Multi-select.

### 1.2. Giao diện Đơn Thuốc Mẫu (`PrescriptionTemplatePage.tsx`)
- Chọn Bệnh (Dropdown).
- Cấu hình điều kiện: "Độ tuổi từ X đến Y".
- Bảng Grid chọn Thuốc:
  - Cột 1: Tên thuốc (Search theo Hoạt chất hoặc Tên thương mại).
  - Cột 2: Số lượng, Liều lượng (Sáng/Trưa/Chiều/Tối).
  - Cột 3: Lời dặn.

### 1.3. Giao diện Phác Đồ Tiêm Chủng (`VaccineProtocolPage.tsx`)
- Tạo Phác đồ (Ví dụ: "Phác đồ Vắc-xin 6 in 1").
- Khai báo các Mũi tiêm: "Mũi 1", "Mũi 2 (Cách mũi 1 tối thiểu 28 ngày)", "Mũi 3 (Cách mũi 2 tối thiểu 6 tháng)".

## 2. Yêu Cầu Logic & API (Backend Team)
- **Logic Cốt lõi (Phác đồ vắc-xin):** Backend khi tính toán ngày tiêm tiếp theo phải chạy hàm `AddDate(last_injection_date, minimum_days)`.
- Khi Lễ tân hoặc Bác sĩ chọn Bệnh trong đơn thuốc, API `GET /api/v1/medical/templates?disease_id=X&age=Y` phải tự động match (khớp) độ tuổi của bệnh nhân để trả về đúng Đơn Thuốc Mẫu cho trẻ em hoặc người lớn.
