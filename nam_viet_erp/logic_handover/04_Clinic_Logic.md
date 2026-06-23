# Bàn Giao Logic 04: Module Y Tế & Phòng Khám (Clinic)

Tài liệu này hướng dẫn Team Backend thay thế các RPC: `create_appointment_booking`, `check_in_patient`, và setup hệ thống WebSocket Realtime cho Hàng Đợi (Queue).

> [!WARNING]
> Tuyệt đối KHÔNG xóa các RPC/Trigger cũ trong CSDL. Code Golang chạy song song.

## 1. Yêu Cầu Kiến Trúc (Backend)
- Gói: `clinic_handler.go`, `clinic_service.go`, `ws_handler.go`.
- **WebSockets Strategy (Zero-cost Realtime):** 
  Sử dụng mô hình Listen/Notify của PostgreSQL kết hợp Gorilla WebSockets của Golang. Chấm dứt việc Client (Trình duyệt) nghe trực tiếp từ Supabase Realtime để tiết kiệm Quota.

## 2. Danh Sách API & Logic Cốt Lõi

### API 1: Lễ Tân Đặt Lịch Hẹn
- **Endpoint:** `POST /api/v1/clinic/appointments`
- **Nghiệp vụ:** 
  1. Nhận request chọn Bác sĩ, Dịch vụ, Khung giờ.
  2. **Check Trùng Lịch:** Query DB đảm bảo Khung giờ đó Bác sĩ chưa bị "Kín lịch".
  3. Tạo bản ghi trong `appointments` (status: `pending`).

### API 2: Bệnh Nhân Check-in (Đẩy vào Hàng Đợi)
- **Endpoint:** `POST /api/v1/clinic/appointments/{id}/check-in`
- **Nghiệp vụ:**
  1. Lễ tân ấn Check-in. Update bảng `appointments` -> `status = 'waiting'`, `check_in_time = NOW()`.
  2. Tạo luồng ghi nhận: Bệnh nhân đã tới phòng khám.

### API 3: Golang WebSocket Server (Hàng Đợi Trực Tiếp)
- **Endpoint:** `GET /ws/v1/clinic/queue`
- **Kiến trúc luồng:**
  1. Khi App khởi động, Golang mở 1 goroutine gọi lệnh `LISTEN clinic_queue_updates` tới Supabase Postgres.
  2. Khi API `check-in` chạy xong (hoặc Bác sĩ ấn hoàn tất khám), Backend trigger lệnh `NOTIFY clinic_queue_updates, '{"doctor_id": "...", "action": "new_patient"}'`.
  3. Goroutine của Golang bắt được thông điệp này từ DB, lập tức Broadcast qua Websocket xuống các màn hình Client đang mở (Dashboard Bác sĩ, Màn hình LED gọi số).
  4. **Frontend:** Bác sĩ thấy tên Bệnh nhân "nảy" lên màn hình trong tích tắc (Độ trễ < 100ms).

## 3. Nhiệm Vụ Frontend
- Gỡ bỏ SDK `@supabase/supabase-js` trong các component hiển thị Hàng Đợi Bệnh Nhân.
- Viết hook mới `useClinicWebSocket(doctorId)` dùng thư viện chuẩn `WebSocket` của trình duyệt, kết nối tới `ws://[domain]/ws/v1/clinic/queue?doctor_id=...`.
- Khi nhận được message type `new_patient`, gọi Redux/Zustand để add bệnh nhân vào mảng hiển thị mà không cần tải lại toàn bộ danh sách.
