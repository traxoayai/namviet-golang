# Bàn Giao Logic 08: Module Vận Chuyển & Giao Hàng (Logistics)

Tài liệu này thay thế logic cập nhật vận đơn và đối soát nhà vận chuyển (Giao Hàng Nhanh, Viettel Post, v.v.).

## 1. Yêu Cầu Kiến Trúc (Backend)
- Gói: `logistics_handler.go`, `logistics_service.go`, `logistics_webhook.go`.
- Các API của hãng vận chuyển thường có Rate Limit và có thể gọi Webhook về hệ thống. Cần đảm bảo Webhook có cơ chế Idempotent (Chống xử lý trùng lặp).

## 2. API & Logic Cốt Lõi

### API 1: Tạo Vận Đơn (Tích hợp API hãng Vận chuyển)
- **Endpoint:** `POST /api/v1/logistics/orders/{order_id}/shipping`
- **Nghiệp vụ:** 
  1. Lấy thông tin đơn hàng và địa chỉ nhận hàng.
  2. Map dữ liệu NamViet ERP với cấu trúc chuẩn của API Giao Hàng Nhanh (hoặc hãng tương tự).
  3. Gửi HTTP Request sang Hãng vận chuyển.
  4. Nếu thành công, lưu lại `tracking_code` và cập nhật `delivery_status = 'shipping'` vào bảng `orders`.

### API 2: Xử Lý Webhook Từ Hãng Vận Chuyển
- **Endpoint:** `POST /api/v1/webhooks/logistics/status-update`
- **Nghiệp vụ:**
  1. Khi Đơn hàng giao thành công, hãng vận chuyển gọi Webhook báo status `DELIVERED`.
  2. Golang API bắt Webhook. Verify chữ ký (Signature) của Webhook để chống request giả mạo.
  3. Mở Transaction:
     - Đổi trạng thái đơn hàng (`delivery_status = 'delivered'`).
     - **Tích điểm (Loyalty Points):** Cấp điểm thưởng cho Khách hàng (nếu có rule).
     - Ghi nhận phí ship thực tế (nếu có chênh lệch so với dự kiến).
  4. Trả về HTTP 200 sớm cho hãng vận chuyển. Mọi tác vụ như tính điểm nên đưa vào Goroutine chạy ngầm (Background Job) để tránh Timeout Webhook.
