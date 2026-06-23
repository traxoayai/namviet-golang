# Bàn Giao Logic 01: Module Quản Lý Tồn Kho (Inventory)

Tài liệu này là chỉ thị tuyệt đối cho Team Backend (Golang) và Frontend (React) để thay thế cụm RPCs: `_deduct_stock_fefo`, `_validate_stock_availability`, `sync_product_inventory_from_batches`, `create_inventory_receipt`.

> [!WARNING]
> Tuyệt đối KHÔNG xóa các RPC/Trigger cũ trong CSDL. Code Golang chạy song song.

## 1. Yêu Cầu Kiến Trúc (Backend)
- Gói `inventory_handler.go`, `inventory_service.go`, `inventory_repository.go`.
- Thư viện Database: Sử dụng **GORM** (Cài thêm `gorm.io/datatypes` để parse JSONB của bảng product).
- Authentication: Mọi API phải qua middleware kiểm tra **Supabase JWT**.

## 2. Danh Sách API Cần Viết & Logic Cốt Lõi

### API 1: Kiểm Tra Tồn Kho
- **Endpoint:** `POST /api/v1/inventory/validate`
- **Logic:** Viết lại RPC `_validate_stock_availability`. Nhận vào danh sách `items [{product_id, quantity, uom}]` và `warehouse_id`.
- **Nghiệp vụ:** Tính tổng `quantity * conversion_rate` (từ bảng `product_units`). Sau đó kiểm tra xem tổng tồn kho trong `inventory_batches` của sản phẩm đó có lớn hơn hoặc bằng không. Báo lỗi `400` nếu thiếu.

### API 2: Trừ Tồn Kho Theo FEFO (Quan trọng nhất)
- **Endpoint:** `POST /api/v1/inventory/deduct`
- **Logic:** Viết lại RPC `_deduct_stock_fefo`. 
- **Nghiệp vụ (BẮT BUỘC TUÂN THỦ):**
  1. Bắt đầu Database Transaction (`tx := db.Begin()`).
  2. Lấy danh sách Lô hàng (`inventory_batches`) của sản phẩm, `WHERE quantity > 0`, `ORDER BY expiry_date ASC, id ASC`.
  3. **CRITICAL:** Khóa các dòng này bằng lệnh GORM: `tx.Clauses(clause.Locking{Strength: "UPDATE"}).Find(&batches)`. Điều này ngăn chặn Race Condition.
  4. Trừ dần `base_quantity` qua từng lô. Nếu lô nào bị trừ, `UPDATE` lại `quantity`.
  5. Ghi lịch sử vào bảng `inventory_transactions` với `type = 'out'`.
  6. Nếu hết lô mà vẫn thiếu hàng -> `tx.Rollback()` và trả về lỗi: `Không đủ tồn kho...`.
  7. Nếu đủ -> `tx.Commit()`.

### API 3: Nhập Kho (Inventory Receipt)
- **Endpoint:** `POST /api/v1/inventory/receipt`
- **Logic:** Viết lại RPC `create_inventory_receipt`.
- **Nghiệp vụ:** 
  1. Nhận JSON mảng các mặt hàng nhập kho.
  2. Mở Transaction.
  3. Duyệt mảng: Nếu lô (batch_code) chưa có trong bảng `batches` -> Tạo mới (Lưu ý: Thêm HSD - `expiry_date`).
  4. Tạo dòng trong `inventory_batches` (hoặc cộng thêm nếu đã có).
  5. Ghi nhận vào `inventory_transactions` (`type = 'in'`).
  6. Commit transaction.
  7. Kích hoạt WebSockets để đẩy sự kiện cập nhật số dư kho xuống Client.

## 3. Kích Hoạt WebSockets (Golang -> Frontend)
Thay vì dùng Supabase Realtime, sau khi `tx.Commit()` thành công, Backend gọi hàm push WebSocket:
```go
websocketManager.Broadcast("inventory_update", map[string]interface{}{
    "warehouse_id": req.WarehouseID,
    "product_id": req.ProductID,
    "action": "deduct",
})
```

## 4. Nhiệm Vụ Frontend
- Không gọi hàm `.rpc('_deduct_stock_fefo')` nữa.
- Viết file `inventoryApi.ts` sử dụng Axios/Fetch gọi tới `/api/v1/inventory/...`.
- Cập nhật custom hook `useInventoryWebSocket.ts` kết nối thẳng vào địa chỉ WebSocket của Golang Server để nhận thông báo realtime về số dư kho. Cập nhật Redux/Zustand state lập tức để UI hiển thị số mới.
