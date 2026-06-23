# Bàn Giao Logic 02: Module Bán Hàng (Orders)

Tài liệu này là chỉ thị tuyệt đối cho Team Backend thay thế RPC: `create_sales_order`.

## 1. Yêu Cầu Kiến Trúc (Backend)
- Gói: `order_handler.go`, `order_service.go`, `order_repository.go`.
- **Cấm viết God-Function:** Hàm `CreateSalesOrder` trong `order_service.go` KHÔNG ĐƯỢC chứa code trừ tồn kho hay sinh phiếu chi trực tiếp. Phải gọi chéo (Inject) `InventoryService` và `FinanceService`.

## 2. API: Tạo Đơn Hàng Bán
- **Endpoint:** `POST /api/v1/orders`
- **Nghiệp vụ (Flow):**
  1. Parse Body Request (items, type, payment_method, voucher...).
  2. Bắt đầu Global Database Transaction `tx := db.Begin()`.
  3. **Check Voucher:** Nếu có `voucher_code`, truy vấn bảng `promotions`. Tính `discount_amount`.
  4. Tính `total_amount` và `final_amount`.
  5. Gọi `inventoryService.ValidateStockAvailability(tx, items)` -> Nếu lỗi -> `tx.Rollback()`.
  6. Insert bảng `orders` (trạng thái pending/confirmed).
  7. Insert bảng `order_items`. Chú ý tính đúng `conversion_factor`.
  8. Nếu trạng thái là `CONFIRMED/COMPLETED` -> Gọi `inventoryService.DeductStockFEFO(tx, items)`. 
     *(Lưu ý phải truyền biến `tx` vào service này để dùng chung 1 Transaction)*.
  9. Nếu `payment_method = "cash"` -> Gọi `financeService.CreateTransaction(tx, amount, "in")`. Update trạng thái thanh toán đơn hàng thành `paid`.
  10. Cuối cùng: `tx.Commit()`.

## 3. Lệnh Kích Hoạt (Event Driven)
- Sau khi `tx.Commit()` thành công, KHÔNG gọi Push Notification bằng code đồng bộ làm chậm API.
- Bắn sự kiện ra một Golang Channel hoặc Redis Pub/Sub: `eventBus.Publish("order_created", orderData)`.
- Sẽ có một Worker độc lập (Goroutine) hứng sự kiện này để bắn Firebase Cloud Messaging (FCM) đến điện thoại của Dược sĩ/Khách hàng.

## 4. Nhiệm Vụ Frontend
- Xóa bỏ lời gọi `.rpc('create_sales_order')`.
- Cập nhật Form giỏ hàng (POS và B2B) gọi API `POST /api/v1/orders`.
- Xử lý mượt mà việc bắt lỗi HTTP 400 (đặc biệt là thông báo hết hàng) và hiển thị Toast/Alert màu đỏ cho người dùng bằng thư viện `Ant Design`.
