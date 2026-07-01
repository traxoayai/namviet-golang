// Map trạng thái đơn hàng sang màu (Ant Design presets)
// src: shared/utils/b2bConstants.ts
export const B2B_STATUS_COLOR: Record<string, string> = {
  DRAFT: "default", // Xám
  QUOTE: "purple", // Tím
  CONFIRMED: "blue", // Xanh dương
  PENDING: "orange", // Cam
  PACKED: "geekblue", // Xanh đậm
  SHIPPING: "cyan", // Xanh lơ
  DELIVERED: "green", // Xanh lá
  CANCELLED: "red", // Đỏ
};

// Map trạng thái thanh toán sang màu (Theo chỉ đạo của CORE)
export const PAYMENT_STATUS_COLOR = {
  unpaid: "red",
  partial: "orange",
  paid: "green",
};

// Label tiếng Việt (Optional)
export const B2B_STATUS_LABEL: Record<string, string> = {
  DRAFT: "Nháp",
  QUOTE: "Báo giá",
  CONFIRMED: "Đã chốt",
  PENDING: "Chờ xử lý",
  PACKED: "Đã đóng gói",
  SHIPPING: "Đang giao",
  DELIVERED: "Hoàn tất",
  CANCELLED: "Đã hủy",
};
