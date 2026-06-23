# Kế Hoạch Chuyển Đổi Kiến Trúc: Từ Supabase RPC/Trigger sang Golang API

## 1. Mục Tiêu (Goal)
Chuyển đổi toàn bộ logic nghiệp vụ (business logic) hiện đang nằm trong cơ sở dữ liệu (PL/pgSQL RPCs & Triggers) lên tầng Application (Golang API).
Mục đích: Dễ bảo trì, dễ viết Unit Test, tăng hiệu năng mở rộng (scale), và tránh phụ thuộc hoàn toàn vào DB.

> [!IMPORTANT]
> **YÊU CẦU TIÊN QUYẾT BẮT BUỘC (DÀNH CHO TEAM BACKEND & FRONTEND):**
> Tuyệt đối KHÔNG ĐƯỢC XÓA BỎ hoặc sửa đổi làm hỏng các hàm RPC (`functions_sql`) và Trigger (`triggers_sql`) hiện tại. Hệ thống cũ vẫn đang hoạt động tốt. Chúng ta sẽ phát triển API Golang chạy song song (Parallel Run). Frontend sẽ được chuyển đổi dần dần sang gọi API mới thay vì gọi trực tiếp RPC qua Supabase Client.

## 2. Trình Bày & Đánh Giá Logic Hiện Tại (Kèm Điểm "Mù")

Dựa trên việc đọc các hàm cốt lõi như `_deduct_stock_fefo`, `create_sales_order`, `create_finance_transaction`, hệ thống hiện tại có các đặc điểm và "điểm mù" rủi ro sau:

### 2.1. Quản lý Tồn kho (Inventory)
- **Logic hiện tại:** Hàm `_deduct_stock_fefo` lặp qua các lô hàng (`inventory_batches`) theo Hạn sử dụng (ASC) và trừ dần số lượng (FEFO).
- **🚨 Điểm mù (Blind Spot) - Race Conditions:** Hàm này đang thực hiện vòng lặp `FOR ... SELECT` nhưng **không có cơ chế khóa dòng (Row-level Locking - `FOR UPDATE`)**. Nếu 2 đơn hàng cùng mua 1 sản phẩm tại cùng 1 mili-giây, rất dễ xảy ra lỗi ghi đè dữ liệu (Lost Update) dẫn đến sai lệch tồn kho (âm kho).

### 2.2. Xử lý Đơn hàng (Sales Orders)
- **Logic hiện tại:** Hàm `create_sales_order` làm quá nhiều việc trong 1 transaction: Tính tiền, trừ tồn kho, kiểm tra Voucher, sinh mã, tạo giao dịch tài chính (nếu trả tiền mặt).
- **🚨 Điểm mù (Blind Spot) - God Function:** Việc nhồi nhét tất cả vào 1 RPC khiến việc nâng cấp rất khó. Nếu hàm bị lỗi ở khâu trừ tồn kho, toàn bộ đơn hàng bị rollback, làm mất vết lỗi. Ngoài ra, việc gửi thông báo (Trigger) sau khi đơn hàng thành công đang làm chậm transaction của database.

### 2.3. Tài chính Kế toán (Finance Transactions)
- **Logic hiện tại:** `create_finance_transaction` có chứa logic "chẻ phiếu" thanh toán nếu Hóa đơn VAT > 5.000.000 VNĐ.
- **🚨 Điểm mù (Blind Spot) - Hardcode Business Rule:** Con số `5000000` đang bị hardcode thẳng vào DB. Nếu luật thuế thay đổi, phải sửa trực tiếp Database. Việc này hoàn toàn nên đặt ở tầng Code Golang (lấy từ Config).

## 3. Danh Mục API Golang Thay Thế Dự Kiến (Phased Approach)

Do số lượng RPC lên tới ~527 hàm, chúng ta sẽ chia API thành các Domain (Module) theo cấu trúc thư mục Clean Architecture của Golang (`internal/handler`). Dưới đây là danh mục thay thế cho các nghiệp vụ lõi:

### 3.1. Inventory Domain (`inventory_handler.go`)
| RPC Cũ | API Mới (Golang) | Method | Mô tả |
| :--- | :--- | :--- | :--- |
| `_deduct_stock_fefo` | `/api/v1/inventory/deduct` | POST | Trừ tồn kho theo FEFO (Sử dụng DB Transaction + Lock `FOR UPDATE` trong GORM). |
| `sync_product_inventory_from_batches` | `/api/v1/inventory/sync-batches` | POST | Đồng bộ tổng tồn kho từ các Lô. |
| `create_inventory_receipt` | `/api/v1/inventory/receipt` | POST | Tạo phiếu nhập kho. |

### 3.2. Order Domain (`order_handler.go`)
| RPC Cũ | API Mới (Golang) | Method | Mô tả |
| :--- | :--- | :--- | :--- |
| `create_sales_order` | `/api/v1/orders` | POST | Tạo đơn hàng bán (B2B/POS). Chia tách logic tính tiền ra Service riêng. |
| `cancel_order` | `/api/v1/orders/{id}/cancel` | POST | Hủy đơn và hoàn tồn kho. |
| `create_purchase_order` | `/api/v1/purchase-orders` | POST | Đặt hàng NCC. |

### 3.3. Finance Domain (`finance_handler.go`)
| RPC Cũ | API Mới (Golang) | Method | Mô tả |
| :--- | :--- | :--- | :--- |
| `create_finance_transaction` | `/api/v1/finance/transactions` | POST | Tạo phiếu thu/chi, xử lý logic hóa đơn VAT 5tr bằng Golang config. |
| `calculate_vat_invoice_allocation` | `/api/v1/finance/vat-allocation` | POST | Phân bổ Hóa đơn VAT bán ra (Thuật toán Knapsack chạy trên RAM Golang thay vì DB sẽ nhanh hơn 10x). |

### 3.4. Patient & Clinic Domain (`clinic_handler.go`)
| RPC Cũ | API Mới (Golang) | Method | Mô tả |
| :--- | :--- | :--- | :--- |
| `create_appointment_booking` | `/api/v1/appointments` | POST | Lễ tân đặt lịch hẹn. |
| `check_in_patient` | `/api/v1/appointments/{id}/check-in` | POST | Đưa bệnh nhân vào hàng đợi (Kích hoạt WebSocket cho Bác sĩ). |

---

## 4. Test Cases (Kịch Bản Kiểm Thử)

Dưới đây là một số Test Cases mẫu (Backend Unit Test + Frontend E2E) cần thực hiện để đảm bảo API mới chạy đúng như RPC cũ.

### Test Case 1: Xử lý Race Condition khi trừ tồn kho (FEFO)
*   **Tiền điều kiện:** Sản phẩm A có Lô 1 (Tồn: 10), Lô 2 (Tồn: 5).
*   **Hành động (Backend):** Bắn đồng thời (Concurrent) 2 Request gọi API `/api/v1/orders` mua 8 Sản phẩm A.
*   **Kết quả mong đợi:** 
    * Request 1 thành công: Mua 8 SP (Lô 1 còn 2, Lô 2 còn 5).
    * Request 2 thất bại (hoặc trả về lỗi thiếu hàng): Vì 8 > (2 + 5). DB không bị âm kho.
*   **Cách khắc phục trong Golang:** Dùng `tx.Clauses(clause.Locking{Strength: "UPDATE"}).Where(...)` để lock dòng lô hàng.

### Test Case 2: Quy định Hóa đơn VAT > 5 Triệu
*   **Tiền điều kiện:** Hóa đơn VAT số 001 có giá trị sau thuế = 6.000.000 VNĐ.
*   **Hành động:** Gọi API `/api/v1/finance/transactions` để thanh toán hóa đơn này bằng hình thức `Tiền mặt` (quỹ cash).
*   **Kết quả mong đợi:** API bắt buộc phải trả về lỗi `HTTP 400 Bad Request` với message "Hóa đơn VAT >= 5 triệu bắt buộc phải thanh toán qua Ngân hàng".

### Test Case 3: Chuyển đổi Frontend an toàn (A/B Testing hoặc Feature Flag)
*   **Hành động (Frontend):** Tại giao diện POS, bọc hàm gọi Supabase `.rpc('create_sales_order')` cũ bằng một Feature Flag. Bật Flag sang dùng API `/api/v1/orders`.
*   **Kết quả mong đợi:** Flow bán hàng hoạt động mượt mà. Giỏ hàng bị làm trống sau khi tạo đơn thành công, hóa đơn in ra nội dung không đổi.
