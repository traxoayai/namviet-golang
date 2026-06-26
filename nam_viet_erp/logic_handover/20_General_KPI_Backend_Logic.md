# Bàn Giao Logic 20: Động Cơ KPI Toàn Diện & Tự Động Tính Lương (Backend)

Tài liệu này hướng dẫn Team Backend đập bỏ dữ liệu giả (Mock data) trong hàm `CalculatePayroll()` hiện tại, và thay thế bằng Động Cơ KPI Toàn Diện (General KPI Engine). 

## 1. Thiết Kế Cấu Trúc Database (Rule Engine)
Tạo 3 bảng mới để làm lõi vận hành KPI cho toàn công ty:

```sql
-- 1. Bảng Từ điển Chỉ số (Định nghĩa những gì công ty có thể đo lường)
CREATE TABLE hr_kpi_metrics (
    code TEXT PRIMARY KEY, -- VD: 'SALES_REVENUE', 'LOGISTICS_COD', 'LOGISTICS_ORDER_COUNT'
    name TEXT NOT NULL,
    description TEXT,
    query_source TEXT NOT NULL, -- Định danh hàm tính toán ở Backend (VD: 'calc_sales_revenue')
    is_active BOOLEAN DEFAULT true
);

-- 2. Bảng Giao Chỉ Tiêu (Target)
CREATE TABLE hr_kpi_targets (
    id BIGSERIAL PRIMARY KEY,
    employee_id UUID NOT NULL,
    month INT NOT NULL,
    year INT NOT NULL,
    metric_code TEXT REFERENCES hr_kpi_metrics(code),
    target_value NUMERIC NOT NULL,
    assigned_by UUID, -- Bắt buộc lưu người giao để Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Bảng Luật Trả Thưởng (Reward Rules)
CREATE TABLE hr_kpi_reward_rules (
    id BIGSERIAL PRIMARY KEY,
    metric_code TEXT REFERENCES hr_kpi_metrics(code),
    condition_type TEXT NOT NULL, -- '>=', '<=', '==' 
    reward_type TEXT NOT NULL, -- 'PERCENTAGE' (% trên kết quả), 'FIXED' (Tiền mặt/đơn)
    reward_value NUMERIC NOT NULL
);
```

## 2. Xử lý Phân Quyền (Authorization) Giao KPI
**Vấn đề cực kỳ quan trọng:** Quyền giao chỉ tiêu KPI liên quan trực tiếp đến dòng tiền trả lương của công ty.
- **Endpoint:** `POST /api/v1/hr/kpi-targets`
- **Logic Phân quyền:**
  1. Nếu User có Role là `Admin` hoặc `Board of Directors` -> **Được phép giao KPI cho toàn công ty.**
  2. Nếu User là `Department Manager` (Trưởng phòng) -> Backend phải check cột `permissions` (dạng JSONB) xem có cờ `{"can_assign_kpi": true}` không. Nếu có, Trưởng phòng CHỈ được phép gán KPI cho danh sách nhân viên thuộc phòng ban của mình (Kiểm tra đối chiếu `department_id`).

## 3. Viết lại Service Tính Lương (`hr_payrolls_service.go`)
Đập bỏ đoạn mock `commission = 0.0` và `kpiBonus = 0.0`. Viết lại Logic như sau:

**A. Thu thập Dữ liệu Thực tế (Actual Data Fetcher):**
Tạo 1 Mapper chạy Query nội bộ tùy theo `metric_code`.
- Nếu `metric_code == 'SALES_REVENUE'`: `SELECT SUM(final_amount) FROM orders WHERE creator_id = ? AND status = 'completed' AND month = ?`
- Nếu `metric_code == 'LOGISTICS_COD'`: `SELECT SUM(amount) FROM finance_transactions WHERE created_by = ? AND status = 'completed' AND flow = 'inbound'`
- Nếu `metric_code == 'LOGISTICS_ORDER_COUNT'`: `SELECT COUNT(id) FROM orders WHERE delivery_staff_id = ? AND delivery_status = 'delivered'`

**B. Thuật Toán Trả Thưởng (Matching & Rewarding):**
- Vòng lặp lấy tất cả `hr_kpi_targets` của nhân viên X trong tháng.
- Lấy kết quả Actual từ bước (A). So khớp với `target_value` dựa theo `condition_type` trong bảng Luật.
- Nếu thỏa mãn Điều kiện (VD: Doanh thu thực > Doanh thu Target) -> Lấy `reward_value` nhân với Actual (Nếu là PERCENTAGE) hoặc lấy số lượng nhân với `reward_value` (Nếu là FIXED).
- Cộng dồn thành tổng `KpiBonus` và `Commission`. Update vào bảng `hr_payrolls`.
