# TÀI LIỆU ĐẶC TẢ TÍNH NĂNG VÀ LOGIC HỆ THỐNG (NAM VIỆT ERP) - PHIÊN BẢN ĐẦY ĐỦ

Dựa trên toàn bộ cấu trúc Schema, RPCs, Triggers và hệ thống Code Backend hiện tại, dưới đây là danh sách chi tiết TẤT CẢ các module và tính năng đang hoạt động trong hệ thống Nam Việt ERP, kèm theo Logic thực thi cụ thể.

---

## 1. MODULE QUẢN LÝ SẢN PHẨM & TỪ ĐIỂN (PRODUCT MANAGEMENT)

### 1.1 Quản lý Danh mục và Thông tin Hàng Hóa
- **Thực hiện:** Thêm, sửa, xóa sản phẩm, danh mục (`categories`), nhà sản xuất (`manufacturers`).
- **Logic:** Thông tin sản phẩm được lưu tại `products`. Hỗ trợ quy đổi nhiều đơn vị tính (Unit Conversion) thông qua bảng `product_units`. Khi tạo đơn vị quy đổi, hệ số quy đổi (`conversion_rate`) sẽ được dùng để nhân/chia khi trừ tồn kho.

### 1.2 Gán Mã Vạch (Barcode) & Quét Mã
- **Thực hiện:** Quét hoặc gán mã vạch từ giao diện cho từng đơn vị quy đổi.
- **Logic (`bulk_update_product_barcodes`, `quick_assign_barcode`):** 
  - Lưu vào bảng `product_barcodes` hoặc cột barcode trong `product_units`.
  - Check Unique để đảm bảo không trùng mã. Nếu trùng sẽ báo lỗi.
  - Tìm kiếm mờ (Fuzzy Search) thông qua `search_products_for_barcode_assign` dùng extension `unaccent` và `pg_trgm`.

### 1.3 Quản Lý Từ Đồng Nghĩa Sản Phẩm (Synonyms) & AI Mapping
- **Thực hiện:** Khai báo các tên gọi khác nhau (viết tắt, không dấu) cho cùng một sản phẩm gốc.
- **Logic (`ai_mapping_rpc`, `map_scanned_invoice_products`):**
  - Lưu trữ ở bảng `product_synonyms`. 
  - Phục vụ cho hàm AI tự động chấm điểm (`similarity score`) map tên thuốc trên hóa đơn VAT của nhà cung cấp vào mã hàng nội bộ.

---

## 2. MODULE KHO & CHUỖI CUNG ỨNG (INVENTORY & BATCH MANAGEMENT)

### 2.1 Quản lý Tồn Kho theo Lô / Hạn Sử Dụng (FEFO)
- **Thực hiện:** Hệ thống tự động theo dõi tồn kho trên từng lô (`inventory_batches`).
- **Logic (`_deduct_stock_fefo`, `validate_stock_availability_error`):**
  - Khi xuất hàng, hệ thống tìm lô hàng có Hạn sử dụng (`expiry_date`) gần nhất còn tồn (`quantity > 0`).
  - Lấy `Số lượng xuất * Hệ số quy đổi (conversion_rate)`.
  - Trừ tuần tự vào các lô (FEFO - First Expire First Out). Nếu thiếu tồn so với yêu cầu sẽ Throw Exception.

### 2.2 Các Nghiệp Vụ Kho (Nhập, Xuất, Chuyển, Kiểm kê)
- **Thực hiện:** Các giao dịch nhập (`inventory_receipts`), kiểm kê (`inventory_checks`), và chuyển kho (`inventory_transfers`).
- **Logic:** 
  - Mọi sự thay đổi về số lượng đều sinh ra bản ghi lưu vết tại `inventory_transactions`.
  - Đảm bảo tính nhất quán qua hàm `sync_product_inventory_from_batches()` và `freeze_stock_quantity_update()` để đóng băng/chốt tồn kho cuối kỳ.

---

## 3. MODULE MUA HÀNG & NHÀ CUNG CẤP (PURCHASE & SUPPLIERS)

### 3.1 Đơn Đặt Hàng (Purchase Orders)
- **Thực hiện:** Tạo Đơn Mua Hàng từ Nhà Cung Cấp (`suppliers`).
- **Logic (`update_po_master`, `get_purchase_orders_master`):**
  - Tạo PO (`purchase_orders`), chi tiết PO (`purchase_order_items`).
  - Khi PO chuyển trạng thái `Received` (Đã nhập hàng), trigger tự động cộng tồn kho vào Lô mới tại `inventory_batches` và sinh phiếu `inventory_receipts`.

### 3.2 Quản Lý Chương Trình & Deal Từ NCC (Supplier Programs)
- **Thực hiện:** Thiết lập các Deal hoặc Chương trình trả thưởng từ Nhà Cung Cấp.
- **Logic:** 
  - Khai báo tại `supplier_programs`, `product_deals`, `deal_items`.
  - Khi đạt doanh số mua, tiền hoặc điểm sẽ được cộng vào `supplier_wallets` thông qua `supplier_wallet_transactions`.

---

## 4. MODULE BÁN HÀNG & XUẤT KHO (SALES & OUTBOUND)

### 4.1 Bán Hàng Kênh Sỉ (B2B) & Portal Cart
- **Thực hiện:** Khách hàng (Nhà thuốc, phòng khám) tự đặt hàng qua B2B Portal.
- **Logic:** Lưu vào `portal_cart_items` -> Chuyển thành Đơn hàng (`sales_orders` / `order_items`). Trừ tồn kho tạm thời (`reserve`) hoặc báo lỗi nếu hết hàng.

### 4.2 Chốt Đóng Gói (Outbound Packing)
- **Thực hiện:** Nhân viên kho quét mã vạch đóng gói xong.
- **Logic (`confirm_outbound_packing`, `save_outbound_progress`):**
  - Ghi nhận trạng thái hoàn thành đóng gói vào bảng `order_status_history`.
  - Chuyển đơn hàng sang `Packed` hoặc `Ready to Ship`.

### 4.3 Xử lý Hàng Trả Lại (Sales Returns)
- **Thực hiện:** Khách hoàn trả hàng do lỗi hoặc hết date.
- **Logic:** 
  - Tạo `sales_returns` và `sales_return_items`.
  - Cộng lại tồn kho (nếu hàng còn dùng được) hoặc đưa vào kho phế liệu. Khấu trừ lại Công Nợ khách hàng.

---

## 5. MODULE KHÁCH HÀNG & CRM (CUSTOMER & CRM)

### 5.1 Quản Lý Khách Hàng, Hạng Thẻ, Phân Khúc (Segments)
- **Thực hiện:** Phân loại khách hàng B2C, B2B.
- **Logic (`create_customer_b2b`, `update_customer_b2b`):**
  - Bảng `customers`, gán `customer_segments`.
  - Với B2B, lưu trữ phân quyền nhân viên phụ trách tại cột JSONB `sales_permissions` để tính hoa hồng và quyền xem data.

### 5.2 Quản Lý Công Nợ & Ví Điểm (Debt & Wallets)
- **Thực hiện:** Ghi nhận nợ và tích điểm mua hàng.
- **Logic (`get_customer_debt_info`):**
  - Điểm tích lũy lưu tại `customer_service_wallets`.
  - Công Nợ tính bằng: (Tổng tiền mua) - (Tổng tiền đã thanh toán từ bảng Fund Accounts / Transactions). Dữ liệu được tính tự động thông qua view `customer_debt_view`.

---

## 6. MODULE KẾ TOÁN & HÓA ĐƠN VAT (ACCOUNTING & FINANCE)

### 6.1 Bóc tách và Đồng bộ Hóa Đơn Điện Tử
- **Thực hiện:** Lấy hóa đơn từ Tổng Cục Thuế hoặc File XML/PDF.
- **Logic (`sync_gdt_invoices`, `process_vat_invoice_entry` - Edge Function AI):**
  - Gọi Gemini AI để OCR/Bóc tách PDF hóa đơn -> Map tên hàng hóa (`vendor_product_mappings`).
  - Ghi vào bảng `finance_invoices` và `finance_invoice_items`.
  - Lên sổ kho Thuế (`vat_inventory_ledger`).

### 6.2 Phân Bổ Hóa Đơn VAT Bán Ra (VAT Allocation)
- **Thực hiện:** Gộp đơn lẻ xuất một Hóa Đơn Đỏ (VAT) cho khách.
- **Logic (`calculate_vat_invoice_allocation`, `reverse_vat_invoice_entry_outbound`):**
  - Dùng thuật toán tối ưu (Knapsack) để nhặt các `order_items` chưa xuất VAT sao cho tổng tiền khớp nhất với số tiền mong muốn xuất.
  - Phải check tồn kho hợp lệ (`vat_inventory_ledger`) để đảm bảo không xuất VAT âm kho Thuế.

### 6.3 Quản Lý Thu Chi (Cash Flow)
- **Thực hiện:** Quản lý Quỹ Tiền Mặt, Ngân hàng.
- **Logic:** Bảng `fund_accounts` (Tài khoản) và `transaction_categories` (Khoản mục thu chi). Mọi phiếu Thu/Chi làm thay đổi số dư quỹ và thay đổi công nợ Khách Hàng / NCC.

---

## 7. MODULE KHUYẾN MÃI & MARKETING (PROMOTIONS & VOUCHERS)

### 7.1 Cấu Hình Khuyến Mãi (Promotions)
- **Thực hiện:** Tặng quà, Chiết khấu %, Giảm tiền mặt.
- **Logic:** 
  - Khai báo tại `promotions`. Đối tượng áp dụng (`promotion_targets`). Quà tặng đính kèm (`promotion_gifts`).
  - Lưu lịch sử sử dụng tại `promotion_usages`. Đảm bảo user không dùng quá số lần quy định.
  - `customer_vouchers` cấp phát Voucher cá nhân hóa cho từng user.

---

## 8. MODULE Y TẾ & PHÒNG KHÁM (CLINIC & MEDICAL SERVICES)

### 8.1 Quản Lý Thăm Khám, Đơn Thuốc, Cận Lâm Sàng
- **Thực hiện:** Lưu trữ hồ sơ bệnh án, Kê đơn thuốc, Xét nghiệm.
- **Logic:**
  - `medical_visits`: Lượt khám bệnh.
  - `prescription_template_items`: Kê đơn theo mẫu.
  - `paraclinical_templates`, `lab_indicators_config`: Cấu hình chỉ số xét nghiệm (Mỡ máu, Huyết áp).
  - Trừ vật tư tiêu hao (`service_consumables`) tự động khi thực hiện gói dịch vụ (`service_packages`).

### 8.2 Quản Lý Tiêm Chủng (Vaccination)
- **Thực hiện:** Theo dõi lịch sử và mẫu tiêm ngừa.
- **Logic:** `vaccination_templates`, `customer_vaccination_records` lưu trữ ngày tiêm, loại vắc xin, và mũi tiêm nhắc lại.

---

## 9. MODULE VẬN CHUYỂN & GIAO HÀNG (LOGISTICS)

### 9.1 Quản Lý Tuyến Đường & Đơn Vị Giao Hàng
- **Thực hiện:** Setup phí giao hàng và xe tải.
- **Logic:**
  - `shipping_partners` (GHTK, ViettelPost) và `transport_vehicles` (Đội xe nội bộ).
  - Khai báo tuyến đường (`delivery_routes`) và áp dụng phụ phí (`shipping_fee_config`, `shipping_rules`) dựa trên khoảng cách hoặc khối lượng đơn.

---

## 10. MODULE AI, CHATBOT & AUTO CRAWLER (AI & AUTOMATION)

### 10.1 Quản lý Chat Khách Hàng & Chấm Điểm Sales (Chat / Inbox)
- **Thực hiện:** Khách hàng chat, Sales trả lời, AI giám sát.
- **Logic (`summarize_chat_history`, `chat_compliance_audits`):**
  - Mọi tin nhắn ném vào `chat_messages`.
  - Cronjob quét định kỳ, gọi AI đọc tin nhắn để chấm điểm thái độ Sales (Tuân thủ), và tóm tắt hội thoại nội bộ (`chat_cache`, `chat_feedback`).

### 10.2 Auto Crawl Dữ Liệu Thuốc
- **Thực hiện:** Lấy thông tin SP từ các chuỗi lớn (Long Châu, An Khang).
- **Logic (`get_top_products_to_crawl`, Edge Function):**
  - Extension gọi API qua chiến lược Fallback 3 Lớp. HTML sau đó được đưa qua Edge Function dùng Google Gemini Extract thành JSON lưu vào Data.

---

## 11. MODULE HỆ THỐNG & PHÂN QUYỀN (SYSTEM & SECURITY)

### 11.1 Phân quyền RBAC (Role-Based Access Control)
- **Thực hiện:** Chia quyền truy cập cho nhân sự.
- **Logic:** Bảng `roles`, `permissions`, `role_permissions`, `user_roles`. Kết hợp với RLS (Row-Level Security) của PostgreSQL để khóa data cấp độ Row (VD: Sales A chỉ xem được đơn của Khách A).

### 11.2 Rate Limiting & Logs
- **Thực hiện:** Giới hạn chống spam API và Audit Logs.
- **Logic:** `rpc_rate_log`, `rpc_access_rules`, `system_logs`, `llm_request_log` để trace lại ai làm gì, khi nào, tốn bao nhiêu token AI.


