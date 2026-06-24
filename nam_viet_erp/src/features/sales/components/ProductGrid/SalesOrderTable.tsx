// src/features/sales-b2b/create/components/ProductGrid/SalesOrderTable.tsx
import { DeleteOutlined, PictureOutlined } from "@ant-design/icons";
import {
  Table,
  InputNumber,
  Button,
  Avatar,
  Typography,
  Space,
  Tag,
} from "antd";

import { ProductSearchBar } from "./ProductSearchBar";
import { StockStatusCell } from "./StockStatusCell";

import { CartItem, ProductB2B } from "@/features/sales/types/b2b_sales";

const { Text } = Typography;

interface Props {
  items: CartItem[];
  onAddItem: (product: ProductB2B) => void;
  onUpdateItem: (key: string, field: keyof CartItem, value: any) => void;
  onRemoveItem: (key: string) => void;
}

export const SalesOrderTable = ({
  items,
  onAddItem,
  onUpdateItem,
  onRemoveItem,
}: Props) => {
  const columns = [
    {
      title: "STT",
      width: 50,
      align: "center" as const,
      render: (_: any, __: any, index: number) => index + 1,
    },
    {
      title: "Sản phẩm",
      width: 350,
      render: (_: any, r: CartItem) => {
        // Tìm xem sản phẩm này có sinh ra gift item nào trong giỏ không
        const relatedGift = items.find((i) => i.is_gift && i.gift_rule_id === r.gift_rule_id);
        const isMuaATangA = relatedGift && relatedGift.id === r.id;
        const isMuaATangB = relatedGift && relatedGift.id !== r.id;

        return (
          <Space align="start">
            <Avatar
              shape="square"
              size={48}
              src={r.image_url}
              icon={<PictureOutlined />}
              style={{ backgroundColor: r.image_url ? "transparent" : "#f0f0f0" }}
            />
            <div>
              <Text strong style={{ color: r.is_gift ? "#52c41a" : "#0050b3" }}>
                {r.name} {r.is_gift && " 🎁"}
              </Text>
              <div style={{ fontSize: 12, color: "#666" }}>{r.sku}</div>
              <div style={{ fontSize: 11, color: "#888" }}>
                Lô: <b>{r.lot_number || "FIFO"}</b> | HD: {r.expiry_date || "--"}
              </div>
              
              {/* Kịch bản 1: Mua A Tặng A */}
              {isMuaATangA && (
                <div style={{ marginTop: 4, color: "#f5222d", fontWeight: "bold" }}>
                  🎁 Mua {r.quantity} tặng {relatedGift.quantity}
                </div>
              )}

              {/* Kịch bản 2: Mua A Tặng B */}
              {(isMuaATangB || (r.gift_value && r.gift_rule_id && !r.is_gift && !relatedGift)) && (
                <div style={{ marginTop: 4, color: "#fa8c16", fontWeight: "bold" }}>
                  🎁 Tặng Quà trị giá {r.gift_value?.toLocaleString()} ₫ (Khi mua đủ số lượng)
                </div>
              )}
            </div>
          </Space>
        );
      },
    },
    {
      title: "Đơn vị",
      dataIndex: "wholesale_unit",
      align: "center" as const,
      width: 80,
      render: (u: string) => <Tag color="geekblue">{u}</Tag>,
    },
    {
      title: "Tồn kho",
      width: 140,
      render: (_: any, r: CartItem) => (
        <StockStatusCell
          stock={r.stock_quantity}
          ordered={r.quantity}
          unit={r.wholesale_unit}
        />
      ),
    },
    {
      title: "Số lượng",
      width: 100,
      render: (_: any, r: CartItem) => (
        <InputNumber
          min={1}
          value={r.quantity}
          disabled={r.is_gift}
          onChange={(v) => onUpdateItem(r.key, "quantity", v || 1)}
          style={{ width: "100%" }}
        />
      ),
    },
    {
      title: "Đơn giá",
      dataIndex: "price_wholesale",
      align: "right" as const,
      width: 120,
      render: (val: number, r: CartItem) => {
        if (r.is_gift) return <Text strong style={{ color: "#52c41a" }}>0 ₫</Text>;
        
        const relatedGift = items.find((i) => i.is_gift && i.gift_rule_id === r.gift_rule_id);
        const isMuaATangA = relatedGift && relatedGift.id === r.id;

        // Kịch bản 1: Mua A Tặng A -> Tính giá trung bình
        if (isMuaATangA) {
          const avgPrice = (val * r.quantity - r.discount) / (r.quantity + relatedGift.quantity);
          return (
            <div>
              <Text delete style={{ color: "#999", fontSize: 12 }}>{val.toLocaleString()} ₫</Text>
              <br />
              <Text strong style={{ color: "#f5222d", fontSize: 16 }}>{Math.round(avgPrice).toLocaleString()} ₫</Text>
            </div>
          );
        }

        // Nếu có discount thủ công nhưng không phải Mua A tặng A
        if (r.discount > 0) {
           const avgPrice = (val * r.quantity - r.discount) / r.quantity;
           return (
            <div>
              <Text delete style={{ color: "#999", fontSize: 12 }}>{val.toLocaleString()} ₫</Text>
              <br />
              <Text strong style={{ color: "#f5222d", fontSize: 16 }}>{Math.round(avgPrice).toLocaleString()} ₫</Text>
            </div>
          );
        }
        return <Text>{val.toLocaleString()} ₫</Text>;
      },
    },
    {
      title: "Thành tiền",
      align: "right" as const,
      width: 140,
      render: (_: any, r: CartItem) => {
        if (r.is_gift) return <Text strong style={{ color: "#52c41a" }}>Quà tặng</Text>;
        return <Text strong>{r.total.toLocaleString()} ₫</Text>;
      },
    },
    {
      width: 50,
      align: "center" as const,
      render: (_: any, r: CartItem) => (
        <Button
          type="text"
          danger
          disabled={r.is_gift}
          icon={<DeleteOutlined />}
          onClick={() => onRemoveItem(r.key)}
        />
      ),
    },
  ];

  return (
    <div
      style={{
        background: "#fff",
        padding: 16,
        borderRadius: 8,
        border: "1px solid #f0f0f0",
      }}
    >
      {/* Search Bar tích hợp ngay trên bảng */}
      <ProductSearchBar onSelect={onAddItem} />

      <Table
        dataSource={items}
        columns={columns}
        rowKey="key"
        pagination={false}
        size="small"
        locale={{ emptyText: "Chưa có sản phẩm nào. Hãy tìm kiếm để thêm." }}
        summary={(pageData) => {
          let totalQty = 0;
          let totalAmount = 0;
          pageData.forEach(({ quantity, total }) => {
            totalQty += quantity;
            totalAmount += total;
          });
          return (
            <Table.Summary.Row style={{ background: "#fafafa" }}>
              <Table.Summary.Cell index={0} colSpan={4}>
                <strong>TỔNG CỘNG</strong>
              </Table.Summary.Cell>
              <Table.Summary.Cell index={1}>
                <strong>{totalQty}</strong>
              </Table.Summary.Cell>
              <Table.Summary.Cell index={2} colSpan={4} align="right">
                <strong style={{ fontSize: 16, color: "#0050b3" }}>
                  {totalAmount.toLocaleString()} ₫
                </strong>
              </Table.Summary.Cell>
            </Table.Summary.Row>
          );
        }}
      />
    </div>
  );
};
