# Bàn Giao Logic 12: Marketing Automation & CSKH

Tài liệu thiết kế "Vũ khí bí mật" của Nam Việt: Campaign Orchestrator (Mục 51, 52).

## 1. Yêu Cầu UI/UX (Frontend Team)
Xây dựng trong `src/pages/marketing/`

### 1.1. Quản lý Chiến Dịch (`CampaignPage.tsx`)
- Đây là giao diện Khó nhất. Sử dụng thư viện **React Flow** để xây dựng Canvas Kéo-Thả (Drag & Drop Node).
- **Node Cấu Hình Chung:** Ngân sách, Tệp khách hàng (Lấy từ Module CRM).
- **Node Kích Hoạt (Trigger):** "Gửi 1 lần vào ngày X", hoặc "Tự động khi khách hàng sinh nhật".
- **Node Hành Động (Action):** "Gửi tin nhắn Zalo", "Gửi SMS", "Tặng Voucher".
  - **[QUAN TRỌNG - ZALO ACTION]:** Tại Action "Gửi tin nhắn Zalo", Frontend phải cung cấp Dropdown cho User chọn 1 trong 2 loại: **1. Zalo ZNS** (Tốn phí, gửi được cho số ĐT chưa quan tâm OA, bắt buộc chọn Template mẫu đã duyệt), hoặc **2. Zalo OA thông thường** (Miễn phí, chỉ gửi cho người đã quan tâm OA, gửi nội dung tự do). Backend xử lý gọi API Zalo tương ứng.
- **Node Điều Kiện (Condition / Delay):** "Đợi 3 ngày", "Nếu đã xem thì...".
- **Dashboard Report:** Biểu đồ hình Phễu (Funnel Chart) dùng thư viện ECharts/Ant Design Charts hiển thị: Sent -> Open -> Clicked -> Redeemed.

### 1.2. Quản lý Khảo Sát (`SurveyPage.tsx`)
- Giao diện Form Builder: Kéo thả các trường (Text, Radio, Checkbox, Rating) để tạo bộ câu hỏi. Lưu cấu trúc này dưới dạng JSON.

## 2. Yêu Cầu Logic & API (Backend Team)
- **Background Worker:** Các kịch bản chiến dịch marketing (Delay 3 ngày, Lên lịch gửi) BẮT BUỘC KHÔNG được chạy trên RAM của API request (để tránh sập server).
  - Phải sử dụng hệ thống Hàng Đợi (Message Queue) như **RabbitMQ** hoặc **Redis Asynq** ở phía Golang để schedule các Job này.
- **Logic Khống chế Ngân sách:** Khi thực hiện action "Tặng Voucher", Worker phải check real-time tổng tiền voucher đã tiêu của chiến dịch. Nếu vượt mức ngân sách (Budget) -> Auto dừng toàn bộ chiến dịch.
