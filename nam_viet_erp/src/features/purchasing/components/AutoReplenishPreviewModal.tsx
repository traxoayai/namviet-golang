import React from "react";
import { Modal, Table, Typography, Tag, Space, Button } from "antd";

const { Text } = Typography;

interface ReplenishItem {
  product_id: number;
  product_name?: string;
  quantity_ordered: number;
  unit: string;
  unit_price: number;
  current_stock_wholesale: number;
  avg_monthly_sales_wholesale: number;
  [key: string]: any;
}

interface GeneratedPO {
  id: number;
  order_code: string;
  supplier_id: number;
  supplier_name?: string;
  total_amount: number;
  items: ReplenishItem[];
}

interface AutoReplenishPreviewModalProps {
  visible: boolean;
  onCancel: () => void;
  data: GeneratedPO[];
}

export const AutoReplenishPreviewModal: React.FC<AutoReplenishPreviewModalProps> = ({
  visible,
  onCancel,
  data,
}) => {
  // Flatten the items to display in a single table, grouped by PO
  const dataSource = data.flatMap((po) =>
    po.items.map((item) => ({
      ...item,
      key: `${po.id}-${item.product_id}`,
      po_code: po.order_code,
      supplier_name: po.supplier_name || `NCC #${po.supplier_id}`,
    }))
  );

  const columns = [
    {
      title: "Mã Đơn / NCC",
      dataIndex: "po_code",
      key: "po_code",
      render: (text: string, record: any) => (
        <Space direction="vertical" size={0}>
          <Text strong>{text}</Text>
          <Text type="secondary" style={{ fontSize: 12 }}>
            {record.supplier_name}
          </Text>
        </Space>
      ),
      onCell: (record: any, index: number = 0) => {
        // Find how many items have the same po_code starting from this index
        const firstIndex = dataSource.findIndex((i) => i.po_code === record.po_code);
        if (index === firstIndex) {
          const rowSpan = dataSource.filter((i) => i.po_code === record.po_code).length;
          return { rowSpan };
        }
        return { rowSpan: 0 };
      },
    },
    {
      title: "Sản phẩm",
      dataIndex: "product_id",
      key: "product_id",
      render: (val: number, record: any) => (
        <Text>{record.product_name || `Sản phẩm #${val}`}</Text>
      ),
    },
    {
      title: "Tồn kho (Sỉ)",
      dataIndex: "current_stock_wholesale",
      key: "current_stock_wholesale",
      render: (val: number, record: any) => (
        <Tag color={val <= 0 ? "error" : "warning"}>
          {val} {record.unit}
        </Tag>
      ),
    },
    {
      title: "Sức bán/tháng",
      dataIndex: "avg_monthly_sales_wholesale",
      key: "avg_monthly_sales_wholesale",
      render: (val: number, record: any) => (
        <Text strong>
          {val} {record.unit}
        </Text>
      ),
    },
    {
      title: "Cần đặt thêm",
      dataIndex: "quantity_ordered",
      key: "quantity_ordered",
      render: (val: number, record: any) => (
        <Text type="success" strong>
          + {val} {record.unit}
        </Text>
      ),
    },
    {
      title: "Đơn giá",
      dataIndex: "unit_price",
      key: "unit_price",
      render: (val: number) =>
        new Intl.NumberFormat("vi-VN", {
          style: "currency",
          currency: "VND",
        }).format(val),
    },
  ];

  return (
    <Modal
      title="Chi tiết Đơn dự trù Min/Max vừa tạo"
      open={visible}
      onCancel={onCancel}
      footer={
        <Button type="primary" onClick={onCancel}>
          Đã hiểu và Đóng
        </Button>
      }
      width={1000}
    >
      <div style={{ marginBottom: 16 }}>
        <Text type="secondary">
          Hệ thống đã tự động tính toán dựa trên định mức tồn kho và sức bán trung bình, đồng thời gom đơn theo từng Nhà cung cấp. Các đơn hàng này hiện đang ở trạng thái <b>Nháp</b>.
        </Text>
      </div>
      <Table
        dataSource={dataSource}
        columns={columns}
        pagination={{ pageSize: 50 }}
        bordered
        size="small"
        scroll={{ y: 400 }}
      />
    </Modal>
  );
};
