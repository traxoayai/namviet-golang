# Bàn Giao Logic 05: Module Khách Hàng, CRM & Công Nợ

Tài liệu này thay thế logic của RPC `get_customer_debt_info` và Trigger `fn_trigger_update_customer_debt`.

> [!WARNING]
> Không xóa trigger cũ. Backend Golang sẽ dần take-over logic tính toán này.

## 1. Yêu Cầu Kiến Trúc (Backend)
- Gói: `customer_handler.go`, `customer_service.go`, `customer_repository.go`.
- Mọi logic cộng trừ công nợ phải đặt trong cùng một DB Transaction khi Phiếu Thu/Chi được tạo.

## 2. API & Logic Cốt Lõi

### API 1: Lấy thông tin Công Nợ Khách Hàng
- **Endpoint:** `GET /api/v1/customers/{id}/debt`
- **Nghiệp vụ:** Trả về `current_debt` hiện tại của khách hàng. Lưu ý, công nợ được tính bằng: `(Tổng giá trị đơn hàng nợ) - (Tổng phiếu thu đã thanh toán) + (Tổng phiếu chi hoàn tiền)`.

### API 2: Cập Nhật Công Nợ Khách Hàng B2B (Internal Service)
- **Hàm Golang nội bộ:** `UpdateCustomerDebt(tx *gorm.DB, customerID, amount, flow, action)`
- **Vấn đề cũ:** Trigger Postgres tự động trừ nợ khi có `finance_transactions` chuyển `status = 'completed'`. Nhưng trigger dễ sinh dead-lock khi update đồng thời.
- **Nghiệp vụ mới:**
  1. Khi Service `Finance` duyệt 1 phiếu thu (`in`) hoặc phiếu chi (`out`) cho đối tác `customer_b2b`.
  2. Bắt buộc gọi `UpdateCustomerDebt` kèm theo con trỏ Transaction `tx`.
  3. Lock dòng khách hàng: `tx.Clauses(clause.Locking{Strength: "UPDATE"}).Where("id = ?", customerID).First(&customer)`.
  4. Nếu `flow = in` (Thu tiền): `current_debt = current_debt - amount`.
  5. Nếu `flow = out` (Chi tiền): `current_debt = current_debt + amount`.
  6. Update lại bảng `customers_b2b`.
