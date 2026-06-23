# 🚀 Mô tả tính năng NAM VIỆT Admin

## QUY TẮC CHO AI:

1. TRƯỚC KHI CODE: Bắt buộc dùng File System đọc file này để nắm "Bức tranh toàn cảnh" tránh thiết kế DATABASE đụng độ.
2. SAU KHI CODE: Bắt buộc đánh dấu `[x]` vào tính năng đã làm xong và ghi chú kỹ thuật vào dòng "Cập nhật".

---

## 📦 MODULE 1: QUẢN LÝ SẢN PHẨM & KHO

- [x] 1.1. CRUD Danh sách sản phẩm cơ bản (Đã xong một phần)
- [ ] 1.2. Cấu hình Đơn vị tính đa tầng (Hộp/Vỉ/Viên)
  - _Mô tả:_ Chú ý logic quy đổi giá bán.
  - _Cập nhật:_ (Core/Aura sẽ tự điền vào đây khi xong)
- [ ] 1.3. Tính năng AI phân loại thuốc theo Quy định của Bộ Y Tế (Dùng Gemini)

## 💰 MODULE 2: HÓA ĐƠN & TÀI CHÍNH

- [ ] 2.1. Extension đồng bộ HĐ VAT từ Tổng cục Thuế
  - _Mô tả:_ Nhận mẻ 50 hóa đơn/lần. Yêu cầu có Redis Queue và Idempotency chống đúp.
  - _Cập nhật:_ (Đã triển khai extension và polling gdt-status)
- [ ] 2.2. ...

## CÁC NHIỆM VỤ CẦN XÂY DỰNG:

- website và Mobile App web admin quản trị (bao gồm quản lý toàn bộ hệ thống, với các module như: Nhân sự; bán hàng; tài chính; Khám bệnh; ...)
- website và Mobile App web Bán Lẻ (đối tượng khách lẻ, theo dõi sức khỏe cho 1 cá nhân hoặc 1 gia đình, xây dựng tập khách hàng trung thành)
- website và Mobile App web Bán Sỉ (Đối tượng khách sỉ, tập trung vào cung cấp các giá trị như: Sự tiện lợi về mua hàng; công nợ và chính sách bán hàng rõ ràng; giao hàng nhanh chóng; ... )

## CHI TIẾT CÁC TÍNH NĂNG

### A. Các giao diện khởi tạo thông tin Lõi ban đầu

- [ ] 1. Giao diện CRUD thông tin Công Ty (hoặc nhiều công ty)
- [ ] 2. Giao diện CRUD thông tin các Chi Nhánh, Kho hàng, Kho quà tặng
- [ ] 3. Giao diện CRUD Phân Quyền (Chi tiết đến từng trường/nút, phân quyền Gửi thông báo)
- [ ] 4. Giao diện CRUD tài khoản đăng nhập cho User.
- [ ] 5. Giao diện CRUD profile Nhân viên (thông tin cơ bản, hồ sơ, lịch sử làm việc, lương, khóa học)
- [ ] 6. Giao diện CRUD TẠO MẪU IN (Bán lẻ, Bán sỉ, Hợp đồng lao động, sử dụng biến template)

### B. Các giao diện CRUD liên quan đến NHÂN SỰ

- [ ] 7. Giao diện CRUD LOẠI HỢP ĐỒNG (Thử việc, 6 tháng, 1 năm...)
- [ ] 8. Giao diện CRUD CHÍNH SÁCH LƯƠNG
- [ ] 9. Giao diện KPIs
- [ ] 10. Giao diện CRUD KHÓA HỌC + ĐÀO TẠO + KIỂM TRA SAU HỌC
- [ ] 11. Giao diện CRUD "Tạo Ca Làm Việc"
- [ ] 12. Giao diện CRUD "Giao việc"

### C. Các giao diện CRUD ban đầu liên quan đến TÀI CHÍNH

- [ ] 13. Giao diện CRUD "DANH SÁCH NGÂN HÀNG" (Dùng API VietQR)
- [ ] 14. Giao diện CRUD "HỆ THỐNG TÀI KHOẢN KẾ TOÁN theo THÔNG TƯ 200"
- [ ] 15. Giao diện CRUD "Loại Phiếu Thu / Chi"
- [ ] 16. Giao diện CRUD "QUẢN LÝ TÀI KHOẢN & QUỸ TIỀN"
- [ ] 17. Giao diện CRUD "GIAO DỊCH LẶP LẠI"
- [ ] 18. Giao diện CRUD "QUẢN LÝ TÀI SẢN"

### D. Các giao diện CRUD ban đầu liên quan đến KẾT NỐI

- [ ] 19. Giao diện CRUD "Bản Đồ Hành Chính Việt Nam"
- [ ] 20. Giao diện CRUD "Đơn Vị Vận Chuyển"
- [ ] 21. Kết Nối Facebook
- [ ] 22. Kết Nối Zalo OA
- [ ] 23. Kết nối Thương Mại Điện Tử (Shopee)
- [ ] 24. Kết nối Tiktok

### E. Các giao diện CRUD ban đầu liên quan đến 'KẾT NỐI: AI & Công nghệ'

- [ ] 25. Cấu Hình Chatbot
- [ ] 26. Cấu Hình Theme Website
- [ ] 27. Cấu hình Theme Mobile App
- [ ] 28. Quản lý Pop Up trên Website và Mobile App
- [ ] 29. Cấu Hình Chung khác

### F. Cấu Hình Chăm Sóc Khách Hàng

- [ ] 30. Quy tắc 'Tích Điểm'
- [ ] 31. Quy Tắc 'Hạng Khách Hàng'

### G. Cấu Hình Nhà Cung Cấp

- [ ] 32. Giao diện CRUD "Nhà Cung Cấp"
- [ ] 33. Giao diện CRUD "Đơn vị Bảo Hành"
- [ ] 34. Giao diện "Ánh Xạ Sản Phẩm từ Nhà Cung Cấp"
- [ ] 35. Giao diện "Hợp Đồng & CTKM" NCC

### H. Cấu Hình Sản Phẩm

- [ ] 36. Giao diện "Danh Sách Sản phẩm Vật Lý"
- [ ] 37. Giao diện "Chi tiết sản phẩm"
- [ ] 38. Giao diện "Sửa Quy Cách Sản phẩm Nhanh"
- [ ] 39. Giao diện "Sửa Giá Sản phẩm Nhanh"
- [ ] 40. Giao diện "Cài đặt Số lượng tồn kho Min / Max và Nhà Cung Cấp"
- [ ] 41. Giao diện "Cài đặt nhanh Vị Trí Sản Phẩm tại mỗi Kho"
- [ ] 42. Giao diện "Cập nhật Mã Vạch của sản phẩm"
- [ ] 43. Giao diện CRUD "Danh Mục Sản Phẩm"
- [ ] 44. Giao diện CRUD "Hoạt Chất Sản phẩm"
- [ ] 45. Giao diện Cài đặt tích chọn kênh bán

### H (I). Cấu Hình Dịch Vụ và Bệnh Học

- [ ] 46. Giao diện CRUD "Danh sách Bệnh" (DIC10)
- [ ] 47. Giao diện CRUD "Đơn Thuốc Mẫu"
- [ ] 48. Giao diện CRUD "Danh sách Mũi Tiêm Chủng"
- [ ] 49. Giao diện CRUD "Phác Đồ Tiêm Chủng"

## SANG PHẦN LOGIC PHỤC VỤ CHO VIỆC HOẠT ĐỘNG và KINH DOANH

- [ ] 50. Giao diện CRUD Phân loại Khách Hàng và Quyền Mua/Bán
- [ ] 51. Giao diện CRUD "Khách hàng Kênh Sỉ"
- [ ] 52. Giao diện "Chi Tiết Khách Hàng Sỉ"
- [ ] 53. Giao diện CRUD "Khách hàng Kênh Lẻ"

## GIAO DIỆN MARKETING và CSKH

- [ ] 54. Giao diện "Tạo nhóm Khách Hàng" (Phân khúc tĩnh và động)
- [ ] 55. Giao diện 'Tạo Voucher Khuyến Mại' (JSON Conditions, JSON Rewards)
- [ ] 56. Giao diện "Quản lý Chiến Dịch Marketing" (Workflow, Touchpoints, Metrics)
- [ ] 57. Giao diện 'Khảo Sát Khách Hàng'
- [ ] 58. Giao diện "Quản lý Bài Viết và Nội dung Số"

## NHÓM CÁC GIAO DIỆN VẬN HÀNH

- [ ] 59. Mua Hàng & Nhập Kho
- [ ] 60. Xuất Kho & Giao Hàng
- [ ] 61. Kiểm Kê (Hàng hóa, Quà tặng, Tài sản)

## NHÓM CÁC GIAO DIỆN KINH DOANH

- [ ] 62. Tạo Đơn Khách Sỉ
- [ ] 63. Danh sách đơn hàng Sỉ
- [ ] 64. Chăm Sóc Khách Hàng Sỉ
- [ ] 65. Tạo đơn hàng Khách Lẻ
- [ ] 66. Danh sách Đơn Khách Lẻ
- [ ] 67. Chăm sóc Khách Lẻ
- [ ] 68. Tạo lịch Hẹn
- [ ] 69. Khám Bệnh (Hàng đợi, Thủ thuật, Kê đơn)
- [ ] 70. Tiêm & Thủ Thuật
- [ ] 71. Cận Lâm Sàng

## NHÓM CÁC GIAO DIỆN TÀI CHÍNH KẾ TOÁN

- [ ] 72. Quản lý Thu / Chi (Finance Transaction)
- [ ] 73. Giao diện "Đối Soát Giao Dịch"
- [ ] 74. Giao diện 'Quản lý Hóa Đơn VAT Mua Vào'
- [ ] 75. Giao diện 'Quản lý Hóa đơn VAT Bán Ra'
- [ ] 76. Giao diện 'Sổ Cái Kế Toán'

## NHÓM CÁC GIAO DIỆN BÁO CÁO

- [ ] 77. Báo cáo Khách Hàng và Chăm Sóc Khách Hàng
- [ ] 78. Báo Cáo Nhân Sự
- [ ] 79. Báo Cáo Kinh Doanh và Lợi Nhuận
- [ ] 80. Báo cáo Vận Hành
- [ ] 81. Báo cáo Marketing và Truyền thông

## NHÓM CÁC GIAO DIỆN CẤU HÌNH AI

- [ ] 82. Cấu hình AI và các quyền AI được làm
