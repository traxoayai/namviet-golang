# Bàn Giao Logic 18: Phân Bổ Thanh Toán & Quản Trị Tiền Mặt Giao Vận (Backend)

Tài liệu Đặc tả Nghiệp vụ này hướng dẫn Team Backend xây dựng cơ sở hạ tầng Dữ liệu và API phục vụ luồng Thanh toán Đa Đơn (Multi-Order Allocation) và Luồng Đối soát COD (Cash on Delivery).

## 1. Mở Rộng Database Schema
Để đáp ứng việc 1 Phiếu thu (Kế toán) chi trả cho N Đơn hàng, cần tạo bảng phân bổ:

```sql
CREATE TABLE finance_transaction_allocations (
    id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT REFERENCES finance_transactions(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE RESTRICT,
    allocated_amount NUMERIC NOT NULL CHECK (allocated_amount > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 2. API Giao Vận (Logistics App)
**Endpoint:** `POST /api/v1/logistics/mark-cod-paid`
- **Mục đích:** Dành cho NV Giao Vận (Shipper) ấn nút "Đã nhận tiền mặt" trên App/Web di động khi giao hàng thành công.
- **Payload:**
  ```json
  { "order_id": "uuid-cua-don-hang" }
  ```
- **Logic ACID Transaction:**
  1. Cập nhật bảng `orders`: `payment_status` = 'paid'.
  2. Tạo bản ghi bảng `finance_transactions` (Phiếu Thu):
     - `amount` = `final_amount` của đơn hàng.
     - `flow` = 'inbound'.
     - `created_by` = `auth.uid()` (ID của Shipper).
     - `status` = **'pending'** (Điểm chốt yếu: Tiền đang trên đường, chưa nộp quỹ).
     - `ref_type` = 'order'.
  3. Tạo 1 bản ghi `finance_transaction_allocations` map giữa phiếu thu vừa sinh ra và `order_id` này với số tiền 100%.
  4. Trừ `current_debt` của `customers_b2b` (Nếu là KH B2B) để giảm nợ ngay lập tức.

**Endpoint Rollback:** `POST /api/v1/logistics/rollback-cod`
- Ngược lại với API trên, Cập nhật `finance_transactions` -> `status = 'cancelled'`. Đảo ngược công nợ và `payment_status`.

## 3. API Kế Toán (Finance / Cashier)
**A. Lấy Danh sách Đối soát COD theo NVGV**
**Endpoint:** `GET /api/v1/finance/pending-cod-reports`
- **Mục đích:** Kế toán xem NVGV nào đang cầm bao nhiêu tiền chưa nộp.
- **Logic Query:** Group By `finance_transactions` theo `created_by` (Lấy User/Employee Profile) với điều kiện `status = 'pending'` và `flow = 'inbound'`.
- **Trả về:** Danh sách Nhóm Shipper kèm Tổng tiền đang giữ, và mảng danh sách Phiếu thu con.

**B. Xác Nhận Đã Nhận Tiền từ NVGV**
**Endpoint:** `POST /api/v1/finance/confirm-cod-deposit`
- **Mục đích:** Khi NVGV mang cọc tiền mặt về phòng Kế toán nộp. Thủ quỹ đếm đủ, bấm "Xác nhận".
- **Payload:**
  ```json
  { "shipper_user_id": "uuid", "transaction_ids": [101, 102, 103] }
  ```
- **Logic:**
  1. Update `status` = **'completed'** cho mảng `transaction_ids`.
  2. Dòng tiền chính thức được khóa cứng vào sổ Kế Toán của Doanh nghiệp.
