# Bàn Giao Logic 09: Module Hệ Thống, RBAC & AI Chat

Tài liệu này bao gồm phân quyền người dùng (Role-Based Access Control) và Tích hợp AI (Chatbot).

## 1. Yêu Cầu Kiến Trúc (Backend)
- Middleware: Bắt buộc viết Custom Middleware `CheckPermission(required_role)` trong Golang Gin để check JWT Roles.
- Rate Limit: Bắt buộc cài đặt Rate Limiter (dựa trên Redis hoặc Memory cache) cho các API gọi ra AI để chống spam gây tốn tiền.

## 2. API & Logic Cốt Lõi

### API 1: Chat với Bác Sĩ / Dược Sĩ AI (Gemini / OpenAI)
- **Endpoint:** `POST /api/v1/ai/chat`
- **Nghiệp vụ:**
  1. Nhận câu hỏi từ User.
  2. **Rate Limit:** Kiểm tra 1 User ID không được hỏi quá 20 câu / 1 giờ. Nếu vượt, chặn lại và trả `HTTP 429 Too Many Requests`.
  3. Xây dựng System Prompt chèn thêm "Ngữ cảnh Bệnh án" (nếu là bác sĩ hỏi) hoặc "Lịch sử mua hàng" (nếu là dược sĩ hỏi).
  4. Gọi HTTP sang LLM API (Gemini/OpenAI) qua luồng Stream (Server-Sent Events - SSE).
  5. Trả kết quả chữ chạy (streaming) về Frontend giống giao diện ChatGPT.

### API 2: Middleware Phân Quyền (RBAC)
- **Hàm Golang nội bộ:** `AuthMiddleware(roles ...string)`
- **Nghiệp vụ:** 
  1. Parse Bearer Token. Giải mã JWT từ Supabase Auth.
  2. Đọc field `app_metadata.roles`.
  3. Nếu API yêu cầu `admin` nhưng User chỉ có `pharmacist` -> Block và trả `HTTP 403 Forbidden`.
