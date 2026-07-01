import {
  GiftOutlined,
  CheckCircleOutlined,
  ShoppingCartOutlined,
} from "@ant-design/icons";
import { Modal, Button, Typography, Empty, Tag, Divider } from "antd";
import dayjs from "dayjs";
import React from "react";

import { PosVoucher } from "../../types/pos.types";

const { Text } = Typography;

interface Props {
  visible: boolean;
  onCancel: () => void;
  vouchers: PosVoucher[];
  selectedVoucherId?: string;
  onApply: (voucher: PosVoucher) => void;
}

export const VoucherSelectorModal: React.FC<Props> = ({
  visible,
  onCancel,
  vouchers,
  selectedVoucherId,
  onApply,
}) => {
  // Core đã sort sẵn (Eligible -> Missing -> Discount). Ta chỉ việc filter ra hiển thị.
  const eligibleList = vouchers.filter((v) => v.is_eligible);
  const ineligibleList = vouchers.filter((v) => !v.is_eligible);

  // Component con để render từng thẻ Voucher

  const VoucherCard = ({
    item,
    disabled,
  }: {
    item: PosVoucher;
    disabled: boolean;
  }) => {
    const isSelected = selectedVoucherId === item.id;

    return (
      <div
        style={{
          display: "flex",
          border: isSelected ? "1px solid #1890ff" : "1px solid #e8e8e8",
          backgroundColor: isSelected
            ? "#e6f7ff"
            : disabled
              ? "#f2f7fc"
              : "#fff",
          borderRadius: 8,
          marginBottom: 12,
          position: "relative",
          transition: "all 0.2s",
          opacity: disabled ? 0.75 : 1, // Mờ nhẹ nếu không dùng được
        }}
      >
        {/* 1. Phần bên trái (Ticket Stub) */}
        <div
          style={{
            width: 110,
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
            alignItems: "center",
            borderRight: "1px dashed #d9d9d9",
            backgroundColor: disabled
              ? "#d9d9d9"
              : item.voucher_source === "personal"
                ? "#f9f0ff"
                : "#fff0f6",
            color: item.voucher_source === "personal" ? "#722ed1" : "#eb2f96",
            padding: 8,
            textAlign: "center",
          }}
        >
          <GiftOutlined style={{ fontSize: 24, marginBottom: 4 }} />
          <div
            style={{ fontWeight: 800, fontSize: 13, wordBreak: "break-all" }}
          >
            {item.code}
          </div>
          <div style={{ fontSize: 10 }}>
            {item.voucher_source === "personal" ? "Tặng riêng" : "Công khai"}
          </div>
        </div>

        {/* 2. Phần nội dung chính */}
        <div
          style={{
            flex: 1,
            padding: "10px 12px",
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
          }}
        >
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "start",
            }}
          >
            <div>
              <Text
                strong
                style={{ fontSize: 15, color: disabled ? "#666" : "#333" }}
              >
                {item.discount_type === "percent"
                  ? `Giảm ${item.discount_value}%`
                  : `Giảm ${item.discount_value.toLocaleString()}đ`}
              </Text>
              <div style={{ fontSize: 12, color: "#666" }}>
                Đơn tối thiểu {item.min_order_value.toLocaleString()}đ
              </div>
            </div>
            {isSelected ? (
              <CheckCircleOutlined style={{ fontSize: 20, color: "#1890ff" }} />
            ) : null}
          </div>

          {/* Hạn sử dụng */}
          <div
            style={{
              fontSize: 11,
              color: item.days_remaining <= 3 ? "#cf1322" : "#888",
              marginTop: 4,
            }}
          >
            HSD: {dayjs(item.valid_to).format("DD/MM/YYYY")}
            {item.days_remaining <= 3 && (
              <b> (Hết hạn sau {item.days_remaining} ngày)</b>
            )}
          </div>

          {/* UPSELL MESSAGE (SHOPPEE STYLE) - Chỉ hiện khi chưa đủ điều kiện */}
          {disabled && item.missing_amount > 0 ? (
            <div
              style={{
                marginTop: 8,
                padding: "4px 8px",
                background: "#fff7e6",
                border: "1px solid #ffd591",
                borderRadius: 4,
                fontSize: 12,
                color: "#d46b08",
                display: "flex",
                alignItems: "center",
                gap: 6,
              }}
            >
              <ShoppingCartOutlined />
              <span>
                Mua thêm{" "}
                <b style={{ fontSize: 13 }}>
                  {item.missing_amount.toLocaleString()}đ
                </b>{" "}
                để dùng
              </span>
            </div>
          ) : null}
        </div>

        {/* 3. Nút hành động */}
        {!disabled && (
          <div
            style={{ display: "flex", alignItems: "center", paddingRight: 12 }}
          >
            <Button
              type={isSelected ? "default" : "primary"}
              size="small"
              onClick={() => {
                onApply(item);
                onCancel();
              }}
            >
              {isSelected ? "Bỏ chọn" : "Dùng"}
            </Button>
          </div>
        )}
      </div>
    );
  };

  return (
    <Modal
      title={
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <Tag color="#f50">HOT</Tag>
          <span>Kho Voucher & Khuyến mãi</span>
        </div>
      }
      open={visible}
      onCancel={onCancel}
      footer={null}
      width={600}
      style={{ top: 20 }}
      bodyStyle={{ padding: "16px 24px", backgroundColor: "#fdfdfd" }}
    >
      <div style={{ maxHeight: "65vh", overflowY: "auto", paddingRight: 4 }}>
        {vouchers.length === 0 && (
          <Empty description="Tiếc quá! Khách chưa có voucher nào." />
        )}

        {/* Phần 1: Voucher khả dụng */}
        {eligibleList.length > 0 && (
          <>
            <div
              style={{
                fontWeight: 600,
                marginBottom: 12,
                color: "#389e0d",
                display: "flex",
                justifyContent: "space-between",
              }}
            >
              <span>🎉 Có thể sử dụng ngay ({eligibleList.length})</span>
            </div>
            {eligibleList.map((v) => (
              <VoucherCard key={v.id} item={v} disabled={false} />
            ))}
          </>
        )}

        {/* Divider nếu có cả 2 loại */}
        {eligibleList.length > 0 && ineligibleList.length > 0 && (
          <Divider style={{ margin: "12px 0" }} />
        )}

        {/* Phần 2: Voucher chưa đủ điều kiện (Upsell) */}
        {ineligibleList.length > 0 && (
          <>
            <div
              style={{ fontWeight: 600, marginBottom: 12, color: "#fa8c16" }}
            >
              🔥 Mua thêm để nhận ưu đãi ({ineligibleList.length})
            </div>
            {ineligibleList.map((v) => (
              <VoucherCard key={v.id} item={v} disabled={true} />
            ))}
          </>
        )}
      </div>
    </Modal>
  );
};
