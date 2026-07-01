// src/features/sales-b2b/create/components/ProductGrid/SalesOrderTable.tsx
import { DeleteOutlined, PictureOutlined, PlusOutlined, MinusOutlined } from "@ant-design/icons";
import {
  Table,
  InputNumber,
  Button,
  Avatar,
  Typography,
  Space,
  Tag,
  Grid,
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

              {/* Kịch bản 3: Upsell Hint - Chưa đủ số lượng */}
              {!r.is_gift && r.upsell_remaining && r.upsell_remaining > 0 && (
                <div style={{
                  marginTop: 4,
                  padding: "4px 8px",
                  background: "linear-gradient(90deg, #fff7e6, #fffbe6)",
                  borderRadius: 4,
                  border: "1px dashed #faad14",
                  color: "#d48806",
                  fontWeight: 600,
                  fontSize: 12,
                }}>
                  🔥 Thêm <span style={{ color: "#f5222d", fontSize: 14 }}>{r.upsell_remaining}</span> {r.wholesale_unit} nữa để được tặng{" "}
                  <span style={{ color: "#52c41a", fontSize: 14 }}>{r.upsell_reward_qty}</span> {r.wholesale_unit}!
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

  const screens = Grid.useBreakpoint();
  const isMobile = screens.xs || (screens.sm && !screens.md);

  // Tính tổng
  let totalQty = 0;
  let totalAmount = 0;
  items.forEach(({ quantity, total }) => {
    totalQty += quantity;
    totalAmount += total;
  });

  return (
    <div
      style={{
        background: "#fff",
        padding: isMobile ? "12px 8px" : 16,
        borderRadius: 8,
        border: "1px solid #f0f0f0",
      }}
    >
      {/* Search Bar tích hợp ngay trên bảng */}
      <ProductSearchBar onSelect={onAddItem} />

      {isMobile ? (
        <div style={{ marginTop: 16 }}>
          {items.length === 0 ? (
            <div style={{ textAlign: "center", padding: 20, color: "#999" }}>
              Chưa có sản phẩm nào. Hãy tìm kiếm để thêm.
            </div>
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              {items.map((r, index) => {
                const relatedGift = items.find((i) => i.is_gift && i.gift_rule_id === r.gift_rule_id);
                const isMuaATangA = relatedGift && relatedGift.id === r.id;
                const isMuaATangB = relatedGift && relatedGift.id !== r.id;

                let displayPrice = r.price_wholesale;
                if (isMuaATangA) {
                  displayPrice = (r.price_wholesale * r.quantity - r.discount) / (r.quantity + relatedGift.quantity);
                } else if (r.discount > 0) {
                  displayPrice = (r.price_wholesale * r.quantity - r.discount) / r.quantity;
                }

                return (
                  <div
                    key={r.key}
                    style={{
                      border: "1px solid #eee",
                      borderRadius: 8,
                      padding: 12,
                      background: "#fff",
                      position: "relative",
                      boxShadow: "0 2px 8px rgba(0,0,0,0.06)",
                    }}
                  >
                    <Space align="start" style={{ width: "100%", marginBottom: 8 }}>
                      <Avatar
                        shape="square"
                        size={60}
                        src={r.image_url}
                        icon={<PictureOutlined />}
                        style={{ backgroundColor: r.image_url ? "transparent" : "#f0f0f0" }}
                      />
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                          <Text strong style={{ color: r.is_gift ? "#52c41a" : "#0050b3", fontSize: 14 }}>
                            {index + 1}. {r.name} {r.is_gift && " 🎁"}
                          </Text>
                          <Button
                            type="text"
                            danger
                            disabled={r.is_gift}
                            icon={<DeleteOutlined />}
                            onClick={() => onRemoveItem(r.key)}
                            style={{ padding: 0, height: "auto", marginLeft: 8 }}
                          />
                        </div>
                        <div style={{ fontSize: 12, color: "#666" }}>{r.sku}</div>
                        <div style={{ fontSize: 11, color: "#888", marginBottom: 4 }}>
                          Lô: <b>{r.lot_number || "FIFO"}</b> | HD: {r.expiry_date || "--"}
                        </div>

                        {/* Kịch bản quà tặng */}
                        {isMuaATangA && (
                          <div style={{ fontSize: 12, color: "#f5222d", fontWeight: "bold" }}>
                            🎁 Mua {r.quantity} tặng {relatedGift.quantity}
                          </div>
                        )}
                        {(isMuaATangB || (r.gift_value && r.gift_rule_id && !r.is_gift && !relatedGift)) && (
                          <div style={{ fontSize: 12, color: "#fa8c16", fontWeight: "bold" }}>
                            🎁 Tặng Quà trị giá {r.gift_value?.toLocaleString()} ₫
                          </div>
                        )}
                        {!r.is_gift && r.upsell_remaining && r.upsell_remaining > 0 && (
                          <div style={{
                            marginTop: 4, padding: "4px 8px", background: "#fffbe6",
                            borderRadius: 4, border: "1px dashed #faad14", color: "#d48806", fontSize: 11,
                          }}>
                            🔥 Thêm <span style={{ color: "#f5222d" }}>{r.upsell_remaining}</span> để được tặng{" "}
                            <span style={{ color: "#52c41a" }}>{r.upsell_reward_qty}</span> {r.wholesale_unit}
                          </div>
                        )}
                      </div>
                    </Space>

                    <div style={{ borderTop: "1px dashed #ddd", paddingTop: 8, marginTop: 8 }}>
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
                        <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                           <Tag color="geekblue" style={{ margin: 0 }}>{r.wholesale_unit}</Tag>
                           <StockStatusCell stock={r.stock_quantity} ordered={r.quantity} unit={r.wholesale_unit} />
                        </div>
                        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                          <Button
                            shape="circle"
                            icon={<MinusOutlined />}
                            disabled={r.is_gift || r.quantity <= 1}
                            onClick={() => onUpdateItem(r.key, "quantity", r.quantity - 1)}
                            style={{ boxShadow: "0 2px 4px rgba(0,0,0,0.1)", border: "1px solid #d9d9d9" }}
                          />
                          <InputNumber
                            min={1}
                            value={r.quantity}
                            disabled={r.is_gift}
                            controls={false}
                            onChange={(v) => onUpdateItem(r.key, "quantity", v || 1)}
                            style={{ width: 50, textAlign: "center" }}
                          />
                          <Button
                            shape="circle"
                            icon={<PlusOutlined />}
                            disabled={r.is_gift}
                            onClick={() => onUpdateItem(r.key, "quantity", r.quantity + 1)}
                            style={{ boxShadow: "0 2px 4px rgba(0,0,0,0.1)", border: "1px solid #d9d9d9" }}
                          />
                        </div>
                      </div>
                      
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end" }}>
                        <div>
                          {r.is_gift ? (
                            <Text strong style={{ color: "#52c41a" }}>0 ₫ / {r.wholesale_unit}</Text>
                          ) : (
                            <>
                              {displayPrice !== r.price_wholesale && (
                                <div style={{ fontSize: 11 }}>
                                  <Text delete type="secondary">{r.price_wholesale.toLocaleString()} ₫</Text>
                                </div>
                              )}
                              <Text strong style={{ color: "#f5222d", fontSize: 14 }}>
                                {Math.round(displayPrice).toLocaleString()} ₫
                              </Text>
                              <Text type="secondary" style={{ fontSize: 12 }}> / {r.wholesale_unit}</Text>
                            </>
                          )}
                        </div>
                        <div style={{ textAlign: "right" }}>
                           <div style={{ fontSize: 11, color: "#888" }}>Thành tiền</div>
                           {r.is_gift ? (
                             <Text strong style={{ color: "#52c41a", fontSize: 16 }}>Quà tặng</Text>
                           ) : (
                             <Text strong style={{ fontSize: 16, color: "#0050b3" }}>{r.total.toLocaleString()} ₫</Text>
                           )}
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}

              <div style={{ padding: "12px 16px", background: "#f0f5ff", borderRadius: 8, border: "1px solid #d6e4ff", marginTop: 8 }}>
                <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                   <Text strong>Tổng số lượng:</Text>
                   <Text strong>{totalQty}</Text>
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                   <Text strong>TỔNG CỘNG:</Text>
                   <Text strong style={{ fontSize: 18, color: "#0050b3" }}>{totalAmount.toLocaleString()} ₫</Text>
                </div>
              </div>
            </div>
          )}
        </div>
      ) : (
        <Table
          style={{ marginTop: 16 }}
          dataSource={items}
          columns={columns}
          rowKey="key"
          pagination={false}
          size="small"
          locale={{ emptyText: "Chưa có sản phẩm nào. Hãy tìm kiếm để thêm." }}
          summary={() => (
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
          )}
        />
      )}
    </div>
  );
};
