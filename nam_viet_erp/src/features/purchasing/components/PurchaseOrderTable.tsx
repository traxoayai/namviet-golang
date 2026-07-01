import {
  EyeOutlined,
  DeleteOutlined,
  CopyOutlined,
  DollarOutlined,
  CarOutlined,
  SearchOutlined,
} from "@ant-design/icons";
import { Tag, Space, Button, Tooltip, Popconfirm, Input } from "antd";
import dayjs from "dayjs";
import React from "react";
import { Link } from "react-router-dom";
import { ResponsiveTable } from "@/shared/ui/common/ResponsiveTable";

import { PurchaseOrderMaster } from "../types/purchase";

import { formatCurrency } from "@/shared/utils/format";
import { PO_STATUS_CONFIG } from "@/shared/utils/purchaseConstants";

interface PurchaseOrderTableProps {
  orders: PurchaseOrderMaster[];
  loading: boolean;
  pagination: any;
  setPagination: (val: any) => void;
  onDelete?: (id: number) => void;
  onOpenPaymentModal: (order: PurchaseOrderMaster) => void;
  onOpenShippingPaymentModal: (order: PurchaseOrderMaster) => void;
  onClone?: (order: PurchaseOrderMaster) => void;
  selectedRowKeys?: React.Key[];
  onRowSelectionChange?: (
    selectedRowKeys: React.Key[],
    selectedRows: PurchaseOrderMaster[]
  ) => void;
  onFilterChange?: (filters: any) => void;
}

const getLogisticsInfo = (r: PurchaseOrderMaster) => {
  const anyR = r as any;
  let name = anyR.shipping_partner_name || anyR.carrier_name;

  if (!name) {
    if (r.delivery_method === "internal") name = "Xe nội bộ";
    else if (r.delivery_method === "supplier") name = "NCC tự giao";
    else if (r.delivery_method === "self_shipping")
      name = "Tự giao / Xe cá nhân";
    else name = "Chưa chọn ĐVVC";
  }

  const contact = anyR.carrier_phone || anyR.carrier_contact || "";
  return { name, contact };
};

export const PurchaseOrderTable: React.FC<PurchaseOrderTableProps> = ({
  orders,
  loading,
  pagination,
  setPagination,
  onDelete,
  onOpenPaymentModal,
  onOpenShippingPaymentModal,
  onClone,
  selectedRowKeys,
  onRowSelectionChange,
  onFilterChange,
}) => {
  const columns = [
    {
      title: "Mã Đơn",
      dataIndex: "code",
      key: "code",
      fixed: "left" as const,
      width: 160,
      render: (text: string, record: PurchaseOrderMaster) => (
        <Link to={`/purchase-orders/${record.id}`} style={{ fontWeight: 600 }}>
          {text}
        </Link>
      ),
    },
    {
      title: "Ngày Tạo/Mua",
      dataIndex: "created_at",
      key: "created_at",
      width: 90,
      render: (date: string) => (
        <div style={{ fontSize: 13 }}>
          <div style={{ fontWeight: 500 }}>
            {dayjs(date).format("DD/MM/YYYY")}
          </div>
          <div style={{ color: "#888" }}>{dayjs(date).format("HH:mm")}</div>
        </div>
      ),
    },
    {
      title: "Nhà Cung Cấp",
      dataIndex: "supplier_name",
      key: "supplier_name",
      width: 240,
      filterDropdown: ({
        setSelectedKeys,
        selectedKeys,
        confirm,
        clearFilters,
      }: any) => (
        <div style={{ padding: 8 }}>
          <Input
            placeholder="Tìm nhà cung cấp"
            value={selectedKeys[0]}
            onChange={(e) =>
              setSelectedKeys(e.target.value ? [e.target.value] : [])
            }
            onPressEnter={() => confirm()}
            style={{ width: 188, marginBottom: 8, display: "block" }}
          />
          <Space>
            <Button
              type="primary"
              onClick={() => confirm()}
              icon={<SearchOutlined />}
              size="small"
              style={{ width: 90 }}
            >
              Lọc
            </Button>
            <Button
              onClick={() => {
                clearFilters && clearFilters();
                confirm();
              }}
              size="small"
              style={{ width: 90 }}
            >
              Xóa
            </Button>
          </Space>
        </div>
      ),
      filterIcon: (filtered: boolean) => (
        <SearchOutlined style={{ color: filtered ? "#1890ff" : "#bfbfbf" }} />
      ),
      render: (text: string) => (
        <div
          style={{
            whiteSpace: "normal",
            wordWrap: "break-word",
            fontSize: 14,
            fontWeight: "bold",
          }}
        >
          {text}
        </div>
      ),
    },
    // [UPDATED] Cột Vận chuyển
    {
      title: "Vận chuyển",
      key: "logistics",
      width: 250,
      render: (_: unknown, r: PurchaseOrderMaster) => {
        const { name, contact } = getLogisticsInfo(r);
        const shippingFee = Number(r.shipping_fee) || 0;
        const shippingPaid = Number(r.shipping_paid) || 0;
        const isShippingPaid = shippingPaid >= shippingFee && shippingFee > 0;
        const hasShippingPartner = !!r.shipping_partner_id;

        return (
          <Space direction="vertical" size={0} style={{ width: "100%" }}>
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
              }}
            >
              <div style={{ fontWeight: "normal" }}>{name}</div>
              {hasShippingPartner && shippingFee > 0 ? (
                <Tooltip
                  title={
                    isShippingPaid
                      ? "Đã thanh toán đủ phí vận chuyển"
                      : "Thanh toán phí vận chuyển"
                  }
                >
                  <Button
                    type="text"
                    icon={<CarOutlined />}
                    size="small"
                    style={{ color: isShippingPaid ? "#bfbfbf" : "#faad14" }}
                    disabled={isShippingPaid}
                    onClick={() => onOpenShippingPaymentModal(r)}
                  />
                </Tooltip>
              ) : null}
            </div>
            <div
              style={{
                fontSize: 12,
                color: "#666",
                display: "flex",
                justifyContent: "space-between",
                marginTop: 4,
              }}
            >
              <span>
                {contact ? <>{contact} • </> : null}
                📦 {(r as any).total_packages || 1} kiện
              </span>
              <span
                style={{
                  fontSize: 11,
                  color: r.expected_delivery_date ? "#1890ff" : "#999",
                }}
              >
                🕒{" "}
                {r.expected_delivery_date
                  ? dayjs(r.expected_delivery_date).format("DD/MM HH:mm")
                  : "Chưa có lịch"}
              </span>
            </div>
          </Space>
        );
      },
    },
    // [NEW] Cột Trạng thái Nhập kho (Tách riêng)
    {
      title: "Nhập kho",
      dataIndex: "delivery_status",
      width: 130,
      filters: [
        { text: "Chờ nhập", value: "pending" },
        { text: "Nhập 1 phần", value: "partial" },
        { text: "Đã nhập kho", value: "delivered" },
        { text: "Hủy", value: "cancelled" },
      ],
      filterMultiple: false,
      render: (status: string) => {
        const map: any = {
          draft: { color: "default", text: "Chờ" },
          pending: { color: "orange", text: "Chờ nhập" },
          partial: { color: "blue", text: "Nhập 1 phần" },
          delivered: { color: "green", text: "Đã nhập kho" },
          cancelled: { color: "red", text: "Hủy" },
        };
        // Xử lý case-insensitive
        const s = map[status?.toLowerCase()] || {
          color: "default",
          text: status,
        };
        return <Tag color={s.color}>{s.text}</Tag>;
      },
    },
    // [UPDATED] Trạng thái Đơn hàng (Dùng Config mới)
    {
      title: "Trạng thái",
      dataIndex: "status",
      key: "status",
      width: 160,
      filters: [
        { text: "Nháp", value: "DRAFT" },
        { text: "Chờ duyệt", value: "PENDING" },
        { text: "Đã duyệt", value: "APPROVED" },
        { text: "Đang mua", value: "ORDERING" },
        { text: "Hoàn tất", value: "COMPLETED" },
        { text: "Hủy", value: "CANCELLED" },
      ],
      filterMultiple: false,
      render: (status: string, record: PurchaseOrderMaster) => {
        const config = PO_STATUS_CONFIG[status] ||
          PO_STATUS_CONFIG[status?.toLowerCase()] || {
            color: "default",
            label: status,
          };
        return (
          <Space direction="vertical" size={2}>
            <Tag color={config.color}>{config.label}</Tag>
            {(record.invoice_count ?? 0) > 0 && (
              <Tag color="green" style={{ fontSize: 11 }}>
                HĐ VAT ({record.invoice_count})
              </Tag>
            )}
          </Space>
        );
      },
    },
    {
      title: "Tổng Tiền",
      dataIndex: "final_amount",
      key: "final_amount",
      align: "right" as const,
      width: 140,
      render: (val: number) => (
        <span style={{ fontWeight: 600 }}>{formatCurrency(val)}</span>
      ),
    },
    // [UPDATED] Cột Thanh toán (Fix NaN)
    {
      title: "Thanh toán",
      key: "payment",
      width: 150,
      filters: [
        { text: "Chưa thanh toán", value: "unpaid" },
        { text: "Thanh toán 1 phần", value: "partial" },
        { text: "Đã thanh toán", value: "paid" },
        { text: "Trả dư", value: "overpaid" },
      ],
      filterMultiple: false,
      render: (_: unknown, r: PurchaseOrderMaster) => {
        const total = Number(r.final_amount) || 0; // Ép kiểu an toàn
        const paid = Number(r.total_paid) || 0;
        const percent = total > 0 ? Math.round((paid / total) * 100) : 0;
        const isPaid =
          percent >= 100 || r.payment_status?.toLowerCase() === "paid";

        return (
          <div style={{ width: "100%" }}>
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                marginBottom: 2,
              }}
            >
              <Tag
                color={isPaid ? "success" : "warning"}
                style={{ marginRight: 0 }}
              >
                {isPaid ? "Đã thanh toán" : "Chưa thanh toán đủ"}
              </Tag>
            </div>
            <div
              style={{
                fontSize: 11,
                color: "#666",
                marginTop: 4,
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
              }}
            >
              <span>
                Đã trả: {new Intl.NumberFormat("vi-VN").format(paid)}đ
              </span>
              {!isPaid && (
                <Tooltip title="Thanh toán cho Nhà cung cấp">
                  <Button
                    type="text"
                    icon={<DollarOutlined />}
                    size="small"
                    style={{ color: "#1890ff" }}
                    onClick={() => onOpenPaymentModal(r)}
                  />
                </Tooltip>
              )}
            </div>
          </div>
        );
      },
    },
    {
      title: "Hành động",
      key: "action",
      fixed: "right" as const,
      width: 120, // Tăng width để chứa nút Copy
      render: (_: unknown, record: PurchaseOrderMaster) => (
        <Space size="small">
          <Tooltip title="Xem chi tiết">
            <Link to={`/purchase-orders/${record.id}`}>
              <Button size="small" icon={<EyeOutlined />} />
            </Link>
          </Tooltip>

          {/* [NEW] Nút Sao chép */}
          {onClone ? (
            <Tooltip title="Sao chép đơn này">
              <Button
                size="small"
                icon={<CopyOutlined />}
                style={{ color: "#1890ff", borderColor: "#1890ff" }}
                onClick={() => onClone(record)}
              />
            </Tooltip>
          ) : null}

          {onDelete ? (
            <Popconfirm
              title="Bạn có chắc muốn xóa đơn này không?"
              onConfirm={() => onDelete(record.id)}
              okText="Có"
              cancelText="Không"
            >
              <Button size="small" danger icon={<DeleteOutlined />} />
            </Popconfirm>
          ) : null}
        </Space>
      ),
    },
  ];

  const handleTableChange = (
    newPagination: any,
    tableFilters: any,
    _sorter: any,
    extra: any
  ) => {
    setPagination({
      page: newPagination.current,
      pageSize: newPagination.pageSize,
      total: pagination.total,
    });
    // Chỉ gọi onFilterChange (và reset page về 1) nếu thao tác là lọc dữ liệu
    if (onFilterChange && extra.action === "filter") {
      onFilterChange(tableFilters);
    }
  };

  return (
    <ResponsiveTable
      columns={columns}
      dataSource={orders}
      rowKey="id"
      loading={loading}
      rowSelection={{
        selectedRowKeys,
        onChange: (keys, rows) => {
          if (onRowSelectionChange) onRowSelectionChange(keys, rows);
        },
      }}
      pagination={{
        current: pagination.page,
        pageSize: pagination.pageSize,
        total: pagination.total,
        showSizeChanger: true,
        showTotal: (total: number) => `Tổng ${total} đơn`,
      }}
      onChange={handleTableChange}
      scroll={{ x: 1200 }}
      size="middle"
    />
  );
};
