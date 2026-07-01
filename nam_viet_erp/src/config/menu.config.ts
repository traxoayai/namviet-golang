// src/config/menu.config.ts

export interface MenuConfigItem {
  id: string; // unique key
  name: string; // label
  href?: string; // route path
  icon?: string; // lucide icon name
  children?: MenuConfigItem[];
  requiredPermissions?: string[];
}

export const MENU_DATA: MenuConfigItem[] = [
  {
    id: "home",
    name: "Trang chủ",
    href: "/",
    icon: "Home",
  },
  {
    id: "connect",
    name: "Thông báo & Ý kiến",
    href: "/connect",
    icon: "Megaphone",
  },
  {
    id: "store",
    name: "Kênh Cửa Hàng",
    icon: "Store",
    children: [
      { id: "store-dashboard", name: "Dashboard Cửa hàng", href: "/store/dashboard", icon: "LayoutDashboard" },
      { id: "medical-reception", name: "Dịch vụ & Lịch Hẹn", href: "/medical/reception", icon: "Calendar" },
      { id: "store-pos", name: "Tạo đơn tại Cửa Hàng [POS]", href: "/blank/pos", icon: "Wallet" },
      { id: "store-shipping", name: "Tạo đơn Gửi Đi", href: "/store/shipping-order", icon: "Send" },
      { id: "store-b2c", name: "DS đơn hàng B2C", href: "/store/b2c-orders", icon: "List" },
      { id: "store-ecommerce", name: "Kết nối Sàn TMĐT", href: "/store/ecommerce", icon: "Globe" },
      {
        id: "website-retail",
        name: "Quản lý Website Bán Lẻ",
        icon: "Globe",
        children: [
          { id: "store-web-general", name: "Thông tin chung", href: "/store/website/general" },
          { id: "store-web-config", name: "Cấu hình Đơn hàng & SP", href: "/store/website/config" },
          { id: "store-web-content", name: "Quản lý Nội dung & CS", href: "/store/website/content" },
        ],
      },
    ],
  },
  {
    id: "medical",
    name: "Nghiệp vụ Y Tế",
    icon: "Stethoscope",
    children: [
      { id: "medical-dashboard", name: "Dashboard Y Tế", href: "/medical/dashboard", icon: "LayoutDashboard" },
      { id: "medical-examination", name: "Khám & Tiêm", href: "/medical/examination", icon: "Stethoscope" },
      { id: "medical-nurse", name: "Trạm Điều Dưỡng", href: "/medical/nurse", icon: "Pill" },
    ],
  },
  {
    id: "paraclinical",
    name: "Cận Lâm Sàng",
    href: "/medical/paraclinical",
    icon: "FlaskConical",
  },
  {
    id: "b2b",
    name: "Bán buôn (B2B)",
    icon: "Briefcase",
    children: [
      { id: "b2b-dashboard", name: "Thông tin chung B2B", href: "/b2b/dashboard", icon: "LayoutDashboard" },
      { id: "b2b-create", name: "Tạo Đơn Hàng B2B", href: "/b2b/create-order", icon: "PlusCircle" },
      { id: "b2b-orders", name: "Danh sách đơn hàng", href: "/b2b/orders", icon: "List" },
      {
        id: "website-b2b",
        name: "Website B2B",
        icon: "Globe",
        children: [
          { id: "b2b-web-general", name: "Thông tin chung", href: "/b2b/website/general" },
          { id: "b2b-web-config", name: "Cấu hình Đơn hàng & SP", href: "/b2b/website/config" },
          { id: "b2b-web-content", name: "Quản lý Nội dung & CS", href: "/b2b/website/content" },
        ],
      },
    ],
  },
  {
    id: "services",
    name: "Combo và Dịch Vụ",
    href: "/services",
    icon: "Gift",
  },
  {
    id: "inventory",
    name: "Kho – Hàng Hóa",
    icon: "Package",
    children: [
      { id: "inv-products", name: "Sản Phẩm & Tồn Kho", href: "/inventory/products", icon: "Box", requiredPermissions: ["inv-product-view"] },
      { id: "inv-purchase", name: "Mua hàng", href: "/inventory/purchase", icon: "ShoppingCart", requiredPermissions: ["inv-po-create"] },
      { id: "inv-inbound", name: "Nhập Kho", href: "/inventory/inbound", icon: "Download" },
      { id: "inv-outbound", name: "Xuất Kho", href: "/inventory/outbound", icon: "LogOut" },
      { id: "inv-transfer", name: "Chuyển kho", href: "/inventory/transfer", icon: "ArrowRightLeft" },
      { id: "inv-stocktake", name: "Kiểm hàng", href: "/inventory/stocktake", icon: "ClipboardCheck", requiredPermissions: ["inv-count-create"] },
      { id: "inv-cost", name: "Điều chỉnh Giá Vốn", href: "/inventory/cost-adjustment", icon: "CircleDollarSign" },
    ],
  },
  {
    id: "quick-actions",
    name: "Thao tác Nhanh",
    icon: "Rocket",
    children: [
      { id: "quick-unit", name: "Cài nhanh Quy Cách (Smart Match)", href: "/quick/unit-setup", icon: "Zap" },
      { id: "quick-price", name: "Sửa giá Sản Phẩm nhanh", href: "/quick/price-edit", icon: "CircleDollarSign" },
      { id: "quick-minmax", name: "Cài Min/Max & Tồn kho (Voice)", href: "/quick/min-max", icon: "Mic" },
      { id: "quick-location", name: "Cài nhanh Vị trí Sản phẩm", href: "/quick/product-location", icon: "MapPin" },
      { id: "quick-barcode", name: "Cập nhật Mã Vạch Nhanh", href: "/quick/barcode-edit", icon: "Barcode" },
      { id: "quick-promo", name: "Tạo nhanh Mã Giảm Giá", href: "/quick/promo-code", icon: "Gift" },
      { id: "quick-prescription", name: "Đơn thuốc Mẫu", href: "/quick/prescription-template", icon: "Pill" },
      { id: "quick-vaccination", name: "Phác đồ Tiêm Chủng Mẫu", href: "/quick/vaccination-template", icon: "Syringe" },
    ],
  },
  {
    id: "partners",
    name: "Đối tác",
    icon: "Handshake",
    children: [
      { id: "part-suppliers", name: "Nhà Cung Cấp", href: "/partners/suppliers", icon: "UserPlus" },
      { id: "part-policies", name: "Chính sách & Hợp đồng", href: "/partners/policies", icon: "FileText" },
      { id: "part-shipping", name: "Đối tác Vận Chuyển", href: "/partners/shipping", icon: "Truck" },
    ],
  },
  {
    id: "crm",
    name: "Quản lý Khách hàng",
    icon: "Users",
    children: [
      { id: "crm-retail", name: "Khách kênh Cửa Hàng", href: "/crm/retail", icon: "Store" },
      { id: "crm-b2b", name: "Khách B2B", href: "/crm/b2b", icon: "Users" },
    ],
  },
  {
    id: "portal",
    name: "Cổng Portal",
    icon: "Globe",
    children: [
      { id: "portal-dashboard", name: "Tổng quan", href: "/portal/dashboard", icon: "LayoutDashboard", requiredPermissions: ["portal.view"] },
      { id: "portal-registrations", name: "Đăng ký Portal", href: "/portal/registrations", icon: "UserPlus", requiredPermissions: ["portal.view"] },
      { id: "portal-users", name: "Portal Users", href: "/portal/users", icon: "User", requiredPermissions: ["portal.manage"] },
      { id: "portal-orders", name: "Đơn hàng Portal", href: "/portal/orders", icon: "ShoppingCart", requiredPermissions: ["portal.view"] },
      { id: "portal-notifications", name: "Gửi thông báo", href: "/portal/notifications", icon: "Send", requiredPermissions: ["portal.manage"] },
    ],
  },
  {
    id: "marketing",
    name: "Quản lý Marketing",
    icon: "Megaphone",
    children: [
      { id: "mkt-dashboard", name: "Dashboard Marketing", href: "/marketing/dashboard", icon: "LayoutDashboard" },
      { id: "mkt-campaigns", name: "Quản lý Chiến dịch", href: "/marketing/campaigns", icon: "Send" },
      {
        id: "marketing-tools",
        name: "Công cụ Marketing",
        icon: "Wrench",
        children: [
          { id: "mkt-segmentation", name: "Tạo Phân khúc KH", href: "/marketing/tools/segmentation" },
          { id: "mkt-promo", name: "Tạo Voucher & QR Code", href: "/marketing/tools/promo" },
          { id: "mkt-distribution", name: "Phân Phối Voucher", href: "/marketing/tools/distribution" },
          { id: "mkt-library", name: "Thư viện Nội dung", href: "/marketing/tools/library" },
        ],
      },
      {
        id: "marketing-chatbot",
        name: "Quản lý Chatbot AI",
        icon: "Bot",
        children: [
          { id: "bot-inbox", name: "Inbox Sales", href: "/marketing/chatbot/inbox", requiredPermissions: ["crm.chatbot.handle"] },
          { id: "bot-analytics", name: "Báo cáo", href: "/marketing/chatbot/analytics", requiredPermissions: ["crm.chatbot.view_analytics"] },
          { id: "bot-compliance", name: "Compliance Chatbot", href: "/chat-compliance", requiredPermissions: ["crm.chatbot.audit"] },
          { id: "bot-synonyms", name: "Từ đồng nghĩa", href: "/marketing/chatbot/synonyms", requiredPermissions: ["crm.chatbot.admin"] },
        ],
      },
    ],
  },
  {
    id: "hr",
    name: "Quản lý Nhân sự",
    icon: "ClipboardList",
    children: [
      { id: "hr-dashboard", name: "Dashboard Nhân sự", href: "/hr/dashboard", icon: "LayoutDashboard" },
      { id: "hr-employees", name: "Quản lý Hồ sơ Nhân viên", href: "/hr/employees", icon: "User" },
      { id: "hr-contracts", name: "Quản lý Hợp đồng & Giấy tờ", href: "/hr/contracts", icon: "FileText" },
      { id: "hr-attendance", name: "Chấm công & Ca làm", href: "/hr/attendance", icon: "MapPin" },
      { id: "hr-training", name: "Quản lý Đào tạo", href: "/hr/training", icon: "GraduationCap" },
      { id: "hr-kpi", name: "Giao việc & KPI", href: "/hr/kpi", icon: "LineChart" },
      { id: "hr-kpi-assignments", name: "🎯 Giao Chỉ Tiêu KPI", href: "/hr/kpi-assignments", icon: "Target" },
      { id: "hr-payroll", name: "Quản lý Lương & Chế Độ", href: "/hr/payroll", icon: "CircleDollarSign" },
    ],
  },
  {
    id: "finance",
    name: "Tài Chính & Kế Toán",
    icon: "CircleDollarSign",
    children: [
      { id: "fin-dashboard", name: "Dashboard Tài chính", href: "/finance/dashboard", icon: "LayoutDashboard", requiredPermissions: ["finance.view"] },
      { id: "fin-invoices", name: "Quản lý Hóa Đơn VAT", href: "/finance/invoices", icon: "FileText" },
      { id: "fin-transactions", name: "Quản lý Thu – Chi", href: "/finance/transactions", icon: "Wallet", requiredPermissions: ["finance.view"] },
      { id: "fin-debts", name: "Quản lý Công Nợ", href: "/finance/debts", icon: "CircleDollarSign", requiredPermissions: ["finance.view"] },
      { id: "fin-assets", name: "Quản Lý Tài Sản", href: "/finance/assets", icon: "Box" },
      { id: "fin-reconciliation", name: "Đối Soát Giao Dịch", href: "/finance/reconciliation", icon: "RefreshCw" },
      {
        id: "accounting",
        name: "Nghiệp Vụ Kế Toán",
        icon: "Building2",
        children: [
          { id: "acc-chart", name: "Hệ thống Tài Khoản", href: "/finance/accounting/chart-of-accounts" },
          { id: "acc-ledger", name: "Sổ Cái Kế Toán", href: "/finance/ledger" },
          { id: "acc-journal", name: "Sổ Nhật ký Chung", href: "/finance/accounting/journal" },
          { id: "acc-misa", name: "Tích hợp MISA", href: "/finance/accounting/misa-integration" },
        ],
      },
    ],
  },
  {
    id: "reports",
    name: "Báo Cáo",
    icon: "PieChart",
    children: [
      {
        id: "report-sales",
        name: "Báo cáo Kinh doanh",
        icon: "LineChart",
        children: [
          { id: "rep-sales-overview", name: "Báo cáo Bán hàng", href: "/reports/sales/overview" },
          { id: "rep-sales-profit", name: "Báo cáo Lãi - Lỗ", href: "/reports/sales/profit-loss" },
          { id: "rep-sales-marketing", name: "Báo cáo Marketing", href: "/reports/sales/marketing" },
        ],
      },
      {
        id: "report-ops",
        name: "Báo cáo Vận hành",
        icon: "Database",
        children: [
          { id: "rep-ops-inventory", name: "Báo cáo Kho", href: "/reports/ops/inventory" },
          { id: "rep-ops-purchase", name: "Báo cáo Nhập hàng", href: "/reports/ops/purchase" },
          { id: "rep-ops-crm", name: "Báo cáo Chăm sóc KH", href: "/reports/ops/crm" },
        ],
      },
      {
        id: "report-admin",
        name: "Báo cáo Quản trị",
        icon: "ClipboardList",
        children: [
          { id: "rep-admin-hr", name: "Báo cáo Nhân viên & KPI", href: "/reports/admin/hr" },
          { id: "rep-admin-tasks", name: "Báo cáo Tiến độ Công việc", href: "/reports/admin/tasks" },
          { id: "rep-admin-audit", name: "Nhật ký Hệ thống", href: "/reports/admin/audit-logs" },
        ],
      },
      {
        id: "report-finance",
        name: "Báo cáo Tài chính",
        icon: "Landmark",
        children: [
          { id: "rep-fin-cashflow", name: "Sổ quỹ", href: "/reports/finance/cashflow" },
          { id: "rep-fin-trial", name: "Bảng Cân Đối Số Phát Sinh", href: "/reports/finance/trial-balance", requiredPermissions: ["finance.view"] },
          { id: "rep-fin-profit", name: "Báo cáo Kết quả KD", href: "/reports/finance/profit-loss", requiredPermissions: ["finance.view"] },
        ],
      },
    ],
  },
  {
    id: "settings-group",
    name: "Cấu hình hệ thống",
    icon: "Settings",
    requiredPermissions: ["settings"],
    children: [
      { id: "set-overview", name: "Tổng quan Cấu hình", href: "/settings", icon: "LayoutDashboard" },
      { id: "set-opening", name: "Nhập Tồn Đầu Kỳ", href: "/settings/opening-stock", icon: "Import" },
      { id: "set-master", name: "Import/Export Sản Phẩm", href: "/settings/data/master", icon: "Database" },
    ],
  },
];
