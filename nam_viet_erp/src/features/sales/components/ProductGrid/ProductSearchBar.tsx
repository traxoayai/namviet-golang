// src/features/sales-b2b/create/components/ProductGrid/ProductSearchBar.tsx
import {
  SearchOutlined,
  BarcodeOutlined,
  EnvironmentOutlined,
  GiftOutlined,
} from "@ant-design/icons";
import { Select, Avatar, Tag, Empty, Spin, Row, Col, Button, Badge } from "antd";
import { useState, useEffect, useRef } from "react";

import { salesService } from "@/features/sales/api/salesService";
import { ProductB2B } from "@/features/sales/types/b2b_sales";
import { useDebounce } from "@/shared/hooks/useDebounce";
import { ApplicableVouchersModal } from "./ApplicableVouchersModal";
import { useSalesStore } from "@/features/sales/stores/useSalesStore";

interface Props {
  onSelect: (product: ProductB2B) => void;
}

export const ProductSearchBar = ({ onSelect }: Props) => {
  const [options, setOptions] = useState<
    { label: React.ReactNode; value: number; product: ProductB2B }[]
  >([]);
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState("");
  const debouncedSearch = useDebounce(search, 300);
  const latestReqIdRef = useRef(0);
  const [modalOpen, setModalOpen] = useState(false);
  const store = useSalesStore();

  // Logic gọi API tìm sản phẩm — chuyển useMemo (anti-pattern cho side-effect)
  // sang useEffect và chống race với latestReqIdRef
  useEffect(() => {
    if (!debouncedSearch) return;

    const reqId = ++latestReqIdRef.current;

    const loadData = async () => {
      setLoading(true);
      try {
        const data = await salesService.searchProducts(debouncedSearch);

        // Bỏ qua response stale
        if (reqId !== latestReqIdRef.current) return;

        // Render kết quả Rich Text theo yêu cầu Stratos
        const newOptions = data.map((item) => ({
          label: (
            <div
              style={{ padding: "8px 0", borderBottom: "1px solid #f0f0f0" }}
            >
              <Row align="middle" gutter={12} wrap={false}>
                <Col flex="40px">
                  <Avatar
                    shape="square"
                    size={40}
                    src={item.image_url}
                    icon={<BarcodeOutlined />}
                  />
                </Col>
                <Col flex="auto">
                  <div
                    style={{
                      fontWeight: 600,
                      color: "#0050b3",
                      lineHeight: 1.2,
                    }}
                  >
                    {item.name}
                  </div>
                  <div style={{ fontSize: 12, color: "#666", marginTop: 4 }}>
                    <Tag>{item.sku}</Tag>
                    {item.shelf_location ? (
                      <Tag color="blue">
                        <EnvironmentOutlined /> {item.shelf_location}
                      </Tag>
                    ) : null}
                  </div>
                </Col>
                <Col flex="100px" style={{ textAlign: "right" }}>
                  <div style={{ fontSize: 13, fontWeight: "bold" }}>
                    {item.price_wholesale?.toLocaleString()} ₫
                  </div>
                  <div
                    style={{
                      marginTop: 4,
                      fontSize: 11,
                      color: item.stock_quantity > 0 ? "green" : "red",
                    }}
                  >
                    Tồn: {item.stock_quantity?.toLocaleString() ?? "0"}{" "}
                    {item.wholesale_unit}
                  </div>
                </Col>
              </Row>
            </div>
          ),
          value: item.id,
          product: item,
        }));
        setOptions(newOptions);
      } catch (e) {
        if (reqId !== latestReqIdRef.current) return;
        console.error(e);
      } finally {
        if (reqId !== latestReqIdRef.current) return;
        setLoading(false);
      }
    };

    loadData();
  }, [debouncedSearch]);

  return (
    <div style={{ display: 'flex', width: "100%", marginBottom: 16, gap: 8, alignItems: 'flex-start' }}>
    <Select
      showSearch
      placeholder="🔍 Gõ tên, SKU hoặc quét mã vạch để thêm hàng..."
      filterOption={false}
      onSearch={setSearch}
      onSelect={(_, option) => {
        const opt = option as unknown as { product?: ProductB2B };
        if (opt?.product) {
          // Vô hiệu hoá in-flight requests sau khi chọn
          latestReqIdRef.current += 1;
          onSelect(opt.product);
          setSearch(""); // Reset sau khi chọn
        }
      }}
      loading={loading}
      options={options}
      style={{ flex: 1, minWidth: 300 }}
      size="large"
      suffixIcon={<SearchOutlined />}
      listHeight={400}
      notFoundContent={
        loading ? (
          <Spin size="small" />
        ) : (
          <Empty description="Không tìm thấy sản phẩm" />
        )
      }
      value={null}
    />
    <Badge dot={store.selectedVoucher ? true : false} color="green">
      <Button 
        type="primary" 
        style={{ height: '40px', background: '#fa8c16', borderColor: '#fa8c16' }}
        icon={<GiftOutlined />} 
        onClick={() => setModalOpen(true)}
      />
    </Badge>
    <ApplicableVouchersModal open={modalOpen} onClose={() => setModalOpen(false)} />
    </div>
  );
};
