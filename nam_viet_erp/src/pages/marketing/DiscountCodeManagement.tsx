// src/pages/marketing/DiscountCodeManagement.tsx
import {
  SearchOutlined,
  PlusOutlined,
  DeleteOutlined,
  QrcodeOutlined,
  TagOutlined,
  UserOutlined,
  GlobalOutlined,
  ReloadOutlined,
  EyeOutlined,
} from "@ant-design/icons";
import {
  Layout,
  Input,
  Table,
  Button,
  Card,
  Typography,
  Select,
  Row,
  Col,
  ConfigProvider,
  Space,
  Tag,
  Modal,
  Form,
  InputNumber,
  Divider,
  Tooltip,
  Popconfirm,
  DatePicker,
  Radio,
  QRCode,
  Switch,
  Descriptions,
} from "antd";
import viVN from "antd/locale/vi_VN";
import dayjs from "dayjs";
import { useState, useEffect, useCallback } from "react";
import { supabase } from "@/shared/lib/supabaseClient";

// Import Store & Components
import { promotionService } from "@/features/marketing/api/promotionService";
import {
  usePromotionStore,
  Promotion,
} from "@/features/marketing/stores/usePromotionStore";
import { useProductStore } from "@/features/product/stores/productStore";
import UniversalCustomerSelect from "@/shared/ui/common/UniversalCustomerSelect";
import DebounceProductSelect from "@/shared/ui/common/DebounceProductSelect";

const { Content } = Layout;
const { Title, Text } = Typography;
const { Option } = Select;
const { RangePicker } = DatePicker;

const styles = {
  layout: { minHeight: "100vh", backgroundColor: "#f6f8fa" },
  card: { margin: "12px", border: "1.5px solid #d0d7de", borderRadius: "8px" },
  table: {
    border: "1.5px solid #d0d7de",
    borderRadius: "6px",
    overflow: "hidden",
  },
};

const DiscountCodeManagement = () => {
  const {
    promotions,
    loading,
    fetchPromotions,
    createPromotion,
    deletePromotion,
  } = usePromotionStore();
  // Lấy dữ liệu Nhóm hàng/Hãng từ ProductStore
  const { uniqueCategories, uniqueManufacturers, fetchClassifications } =
    useProductStore();

  // State Modal & Form
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [isQrModalVisible, setIsQrModalVisible] = useState(false);
  const [qrCodeValue, setQrCodeValue] = useState("");
  // [NEW] States for detail view
  const [isDetailVisible, setIsDetailVisible] = useState(false);
  const [selectedPromotion, setSelectedPromotion] = useState<Promotion | null>(null);
  const [applyToNames, setApplyToNames] = useState<string[]>([]); // [NEW] Lưu tên sản phẩm

  // State điều khiển UI Form
  const [discountType, setDiscountType] = useState("percent");
  const [promoType, setPromoType] = useState("public");
  const [scopeType, setScopeType] = useState("all");

  // --- STATE TÌM KIẾM & LỌC (MỚI THÊM) ---
  const [searchText, setSearchText] = useState("");
  const [statusFilter, setStatusFilter] = useState<string | undefined>(
    undefined
  );
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs] | null>(null);

  const [form] = Form.useForm();

  // Effect 1: Tải dữ liệu ban đầu & danh mục
  useEffect(() => {
    fetchClassifications();
  }, []);

  // Effect 2: Gọi API tìm kiếm khi search/filter thay đổi (MỚI)
  useEffect(() => {
    const formattedDateRange: [string, string] | undefined = dateRange
      ? [dateRange[0].toISOString(), dateRange[1].toISOString()]
      : undefined;
    fetchPromotions(searchText, statusFilter, formattedDateRange);
  }, [searchText, statusFilter, dateRange]);

  // [NEW] Fetch tên sản phẩm theo ID khi mở modal chi tiết
  const fetchProductNames = useCallback(async (ids: (string | number)[]) => {
    if (!ids || ids.length === 0) { setApplyToNames([]); return; }
    try {
      const { data } = await supabase
        .from('products')
        .select('id, name')
        .in('id', ids.map(Number));
      setApplyToNames((data || []).map((p: any) => p.name));
    } catch {
      setApplyToNames(ids.map(String)); // fallback: hiển ID nếu không tìm được
    }
  }, []);

  const showAddModal = () => {
    setDiscountType("percent");
    setPromoType("public");
    setScopeType("all");
    form.resetFields();
    form.setFieldsValue({
      type: "public",
      discount_type: "percent",
      status: "active",
      apply_to_scope: "all",
      validDates: [dayjs(), dayjs().add(30, "day")],
      maxUsage: 100,
      is_stackable: true,
      promo_group: "percent",
      combinable_groups: [],
    });
    setIsModalVisible(true);
  };

  const handleModalSave = async () => {
    try {
      const values = await form.validateFields();

      // Build advanced_rules if discount_type is 'advanced'
      let advanced_rules = null;
      if (values.discount_type === "advanced") {
        advanced_rules = {
          condition:
            values.condition_type === "buy_amount"
              ? { type: "buy_amount", min_amount: values.min_amount || 0 }
              : {
                  type: "buy_quantity",
                  target_product_id: values.target_product_id,
                  min_quantity: values.min_quantity || 1,
                },
          reward: {
            type: "give_product",
            gift_product_id: values.gift_product_id,
            gift_quantity: values.gift_quantity || 1,
            gift_value: values.gift_value || 0,
            discount_percent: 100, // Miễn phí 100%
          },
          is_multiply: values.is_multiply ?? true,
        };
      }

      const buildPayload = (c?: any, index?: number) => ({
        code: index !== undefined && values.selected_customers?.length > 1
          ? `${values.code}-${index + 1}`
          : values.code,
        name: values.campaignName,
        description: values.description,
        promotion_type: values.type, // [FIX] DB dùng 'promotion_type', không phải 'type'
        discount_type: values.discount_type,
        discount_value: values.value || 0,
        max_discount_value:
          values.discount_type === "percent" ? values.max_discount_value : null,
        min_order_value: values.minPurchase || 0,
        total_usage_limit: values.maxUsage,
        apply_to_scope: values.apply_to_scope,
        apply_to_ids: values.apply_to_scope === "product" 
          ? [values.apply_to_ids]
          : (values.apply_to_ids ? [values.apply_to_ids] : []),
        valid_from: values.validDates[0].toISOString(),
        valid_to: values.validDates[1].toISOString(),
        status: values.status,
        customer_id: c?.value || null,
        customer_type: c?.item?.type || values.customer_type || "B2C",
        advanced_rules: advanced_rules,
        is_stackable: values.is_stackable ?? true,
        promo_group: values.promo_group,
        combinable_groups: values.is_stackable ? values.combinable_groups || [] : [],
      });

      // 1. Xử lý logic Voucher Tặng Riêng (Personal)
      if (values.type === "personal" && values.selected_customers) {
        const batchData = values.selected_customers.map((c: any, index: number) => buildPayload(c, index));

        await promotionService.createBatchPromotions(batchData);
        setIsModalVisible(false);
        fetchPromotions();
      } else {
        // 2. Xử lý logic Voucher Công Khai (Public)
        const payload = buildPayload();
        const success = await createPromotion(payload);
        if (success) setIsModalVisible(false);
      }
    } catch (info) {
      console.log("Validate Failed:", info);
    }
  };

  const generateRandomCode = () => {
    const randomCode = Math.random()
      .toString(36)
      .substring(2, 10)
      .toUpperCase();
    form.setFieldsValue({ code: randomCode });
  };

  const columns = [
    {
      title: "Mã Code",
      dataIndex: "code",
      render: (text: string) => (
        <Text strong copyable>
          {text}
        </Text>
      ),
    },
    {
      title: "Chiến dịch",
      dataIndex: "name",
    },
    {
      title: "Loại",
      dataIndex: "type",
      align: "center" as const,
      render: (type: string) =>
        type === "public" ? (
          <Tag icon={<GlobalOutlined />} color="blue">
            Công khai
          </Tag>
        ) : (
          <Tag icon={<UserOutlined />} color="purple">
            Cá nhân
          </Tag>
        ),
    },
    {
      title: "Phạm vi",
      dataIndex: "apply_to_scope",
      render: (scope: string) => {
        switch (scope) {
          case "all":
            return <Tag>Toàn sàn</Tag>;
          case "product":
            return <Tag color="geekblue">Theo Sản phẩm</Tag>;
          case "category":
            return <Tag color="cyan">Theo Nhóm</Tag>;
          case "brand":
            return <Tag color="orange">Theo Hãng</Tag>;
          default:
            return scope;
        }
      },
    },
    {
      title: "Giá trị",
      render: (_: any, record: Promotion) => (
        <Tag color={record.discount_type === "percent" ? "orange" : "green"}>
          {record.discount_type === "percent"
            ? `Giảm ${record.discount_value}%`
            : `Giảm ${record.discount_value.toLocaleString()}đ`}
        </Tag>
      ),
    },
    {
      title: "Đã dùng",
      render: (_: any, record: Promotion) => (
        <Text>
          {record.usage_count} / {record.total_usage_limit || "∞"}
        </Text>
      ),
    },
    {
      title: "Trạng thái",
      dataIndex: "status",
      align: "center" as const,
      render: (status: string, record: Promotion) => {
        const isExpired = record.valid_to && dayjs().isAfter(dayjs(record.valid_to));
        if (status === "inactive") return <Tag color="default">Đã Ẩn</Tag>;
        if (isExpired) return <Tag color="error">Hết hiệu lực</Tag>;
        return <Tag color="success">Hiệu lực</Tag>;
      },
    },
    {
      title: "Thời gian hiệu lực",
      render: (_: any, record: Promotion) => (
        <Text style={{ fontSize: 13 }}>
          {record.valid_from ? dayjs(record.valid_from).format("DD/MM/YYYY") : ""}
          {" - "}
          {record.valid_to ? dayjs(record.valid_to).format("DD/MM/YYYY") : ""}
        </Text>
      ),
    },
    {
      title: "Hành động",
      key: "action",
      align: "center" as const,
      render: (_: any, record: Promotion) => (
        <Space>
          <Tooltip title="Xem chi tiết">
            <Button
              icon={<EyeOutlined />}
              size="small"
              onClick={async () => {
                setSelectedPromotion(record);
                setApplyToNames([]);
                const scope = (record as any).apply_to_scope;
                const ids = (record as any).apply_to_ids;
                if (scope === 'product' && ids && ids.length > 0) {
                  await fetchProductNames(ids);
                }
                setIsDetailVisible(true);
              }}
            />
          </Tooltip>
          <Tooltip title="QR Code">
            <Button
              icon={<QrcodeOutlined />}
              size="small"
              onClick={() => {
                setQrCodeValue(record.code);
                setIsQrModalVisible(true);
              }}
            />
          </Tooltip>
          <Popconfirm title="Xóa?" onConfirm={() => deletePromotion(record.id)}>
            <Button icon={<DeleteOutlined />} size="small" danger />
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <ConfigProvider locale={viVN}>
      <Layout style={styles.layout}>
        <Content>
          <Card bordered={false} style={styles.card} bodyStyle={{ padding: 0 }}>
            {/* Header */}
            <div
              style={{
                padding: "16px 24px",
                borderBottom: "1px solid #f0f0f0",
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
              }}
            >
              <Title level={4} style={{ margin: 0 }}>
                <TagOutlined /> Quản lý Mã Giảm giá & QR Code
              </Title>
              <Button
                type="primary"
                icon={<PlusOutlined />}
                onClick={showAddModal}
              >
                Thêm Mã Mới
              </Button>
            </div>

            {/* --- THANH TÌM KIẾM & BỘ LỌC (MỚI THÊM) --- */}
            <div
              style={{
                padding: "16px 24px",
                borderBottom: "1px solid #f0f0f0",
              }}
            >
              <Row gutter={16}>
                <Col flex="auto">
                  <Input
                    prefix={<SearchOutlined />}
                    placeholder="Tìm theo Mã Code, Tên chiến dịch..."
                    allowClear
                    onChange={(e) => setSearchText(e.target.value)}
                  />
                </Col>
                <Col flex="200px">
                  <Select
                    placeholder="Trạng thái"
                    allowClear
                    style={{ width: "100%" }}
                    onChange={(val) => setStatusFilter(val)}
                  >
                    <Select.Option value="active">Hiệu lực</Select.Option>
                    <Select.Option value="inactive">Hết hạn/Ẩn</Select.Option>
                  </Select>
                </Col>
                <Col flex="300px">
                  <RangePicker
                    style={{ width: "100%" }}
                    allowClear
                    onChange={(dates) => setDateRange(dates as any)}
                  />
                </Col>
              </Row>
            </div>

            <Table
              columns={columns}
              dataSource={promotions}
              loading={loading}
              rowKey="id"
              pagination={{ pageSize: 10, size: "small" }}
            />
          </Card>
        </Content>
      </Layout>

      {/* Modal Thêm Mã */}
      <Modal
        title="Tạo Mã Giảm Giá Mới"
        open={isModalVisible}
        onOk={handleModalSave}
        onCancel={() => setIsModalVisible(false)}
        width={1200}
        destroyOnClose
        okText="Lưu & Kích hoạt"
      >
        <Form
          form={form}
          layout="vertical"
          onValuesChange={(v) => {
            if (v.discount_type) setDiscountType(v.discount_type);
            if (v.type) setPromoType(v.type);
            if (v.apply_to_scope) setScopeType(v.apply_to_scope);
          }}
        >
                  <Row gutter={24}>
                    <Col span={6}>
                      <Form.Item
                        name="campaignName"
                        label="Tên Chiến dịch"
                        rules={[{ required: true }]}
                      >
                        <Input placeholder="Vd: Khuyến mãi Hè 2025" />
                      </Form.Item>
                      <Form.Item
                        name="code"
                        label="Mã Code (Voucher)"
                        rules={[{ required: true }]}
                        help="Mã khách hàng sẽ nhập."
                      >
                        <Input
                          placeholder="Vd: HE2025"
                          addonAfter={
                            <ReloadOutlined
                              onClick={generateRandomCode}
                              style={{ cursor: "pointer" }}
                            />
                          }
                        />
                      </Form.Item>
                      <Form.Item
                        name="validDates"
                        label="Thời gian hiệu lực"
                        rules={[{ required: true }]}
                      >
                        <RangePicker
                          showTime
                          format="DD/MM/YYYY HH:mm"
                          style={{ width: "100%" }}
                        />
                      </Form.Item>
                      <Divider dashed style={{ margin: "12px 0" }} />
                      <Text strong style={{ color: '#fa8c16' }}>Cấu hình Cộng dồn (Stackable)</Text>
                      <Form.Item name="is_stackable" label="Cho phép cộng dồn" valuePropName="checked" style={{ marginTop: 12 }}>
                        <Switch />
                      </Form.Item>
                      <Form.Item name="promo_group" label="Phân nhóm Mã" rules={[{ required: true }]}>
                        <Select>
                          <Option value="gift">Quà tặng (Mua X tặng Y)</Option>
                          <Option value="cash">Trừ Tiền mặt</Option>
                          <Option value="percent">Giảm Phần trăm (%)</Option>
                          <Option value="freeship">Miễn phí Vận chuyển</Option>
                        </Select>
                      </Form.Item>
                      <Form.Item
                        noStyle
                        shouldUpdate={(prev, curr) => prev.is_stackable !== curr.is_stackable}
                      >
                        {({ getFieldValue }) => {
                          const stackable = getFieldValue("is_stackable");
                          return stackable ? (
                            <Form.Item name="combinable_groups" label="Được kết hợp chung với:">
                              <Select mode="multiple" placeholder="Chọn nhóm (Để trống = Không kết hợp)">
                                <Option value="gift">Nhóm Quà tặng</Option>
                                <Option value="cash">Nhóm Tiền mặt</Option>
                                <Option value="percent">Nhóm Phần trăm</Option>
                                <Option value="freeship">Nhóm Freeship</Option>
                              </Select>
                            </Form.Item>
                          ) : null;
                        }}
                      </Form.Item>
                    </Col>
                    <Col span={10}>
                      <Card
                        size="small"
                        title="Giá trị khuyến mãi"
                        style={{ backgroundColor: "#f9f9f9" }}
                      >
                        <Form.Item label="Loại giảm giá" required>
                          <Input.Group compact>
                            <Form.Item name="discount_type" noStyle>
                              <Select style={{ width: discountType === "advanced" ? "100%" : "40%" }}>
                                <Option value="percent">Giảm %</Option>
                                <Option value="fixed">Tiền mặt</Option>
                                <Option value="advanced">Quà tặng / Bậc thang</Option>
                              </Select>
                            </Form.Item>
                            {discountType !== "advanced" && (
                              <Form.Item
                                name="value"
                                noStyle
                                rules={[{ required: true }]}
                              >
                                <InputNumber
                                  style={{ width: "60%" }}
                                  min={0}
                                  formatter={(value) =>
                                    `${value}`.replace(
                                      /\B(?=(\d{3})+(?!\d))/g,
                                      ","
                                    )
                                  }
                                />
                              </Form.Item>
                            )}
                          </Input.Group>
                        </Form.Item>

                        {discountType === "percent" && (
                          <Form.Item
                            name="max_discount_value"
                            label="Giảm tối đa (VNĐ)"
                          >
                            <InputNumber
                              style={{ width: "100%" }}
                              formatter={(value) =>
                                `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ",")
                              }
                              addonAfter="đ"
                            />
                          </Form.Item>
                        )}

                        {discountType !== "advanced" && (
                          <Form.Item
                            name="minPurchase"
                            label="Đơn hàng tối thiểu"
                            initialValue={0}
                          >
                            <InputNumber
                              style={{ width: "100%" }}
                              formatter={(value) =>
                                `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ",")
                              }
                              addonAfter="đ"
                            />
                          </Form.Item>
                        )}

                        {discountType === "advanced" && (
                          <Card size="small" style={{ marginTop: 12, borderColor: '#ffc53d' }} title="Cấu hình Bậc thang / Quà tặng">
                            <Form.Item label="Điều kiện áp dụng" name="condition_type" rules={[{ required: true }]} initialValue="buy_quantity">
                              <Radio.Group buttonStyle="solid">
                                <Radio.Button value="buy_quantity">Đạt số lượng</Radio.Button>
                                <Radio.Button value="buy_amount">Đạt tổng tiền</Radio.Button>
                              </Radio.Group>
                            </Form.Item>

                            <Form.Item
                              noStyle
                              shouldUpdate={(prev, curr) => prev.condition_type !== curr.condition_type}
                            >
                              {({ getFieldValue }) => {
                                const cType = getFieldValue("condition_type") || "buy_quantity";
                                return cType === "buy_quantity" ? (
                                  <>
                                    <Form.Item label="Sản phẩm mua" name="target_product_id" rules={[{ required: true }]}>
                                      <DebounceProductSelect placeholder="Chọn sản phẩm yêu cầu mua..." searchTypes={["product", "service", "bundle"]} />
                                    </Form.Item>
                                    <Form.Item label="Số lượng cần mua tối thiểu" name="min_quantity" rules={[{ required: true }]}>
                                      <InputNumber min={1} style={{ width: "100%" }} />
                                    </Form.Item>
                                  </>
                                ) : (
                                  <Form.Item label="Tổng tiền bill tối thiểu" name="min_amount" rules={[{ required: true }]}>
                                    <InputNumber min={0} style={{ width: "100%" }} formatter={(v) => `${v}`.replace(/\B(?=(\d{3})+(?!\d))/g, ",")} addonAfter="đ" />
                                  </Form.Item>
                                );
                              }}
                            </Form.Item>

                            <Divider dashed style={{ margin: "12px 0" }} />
                            <Text strong style={{ color: '#fa8c16' }}>Phần Thưởng (Quà tặng)</Text>
                            
                            <Form.Item label="Sản phẩm tặng" name="gift_product_id" rules={[{ required: true }]} style={{ marginTop: 12 }}>
                              <DebounceProductSelect placeholder="Chọn sản phẩm dùng làm quà tặng..." searchTypes={["product", "service", "bundle"]} />
                            </Form.Item>
                            
                            <Row gutter={8}>
                              <Col span={12}>
                                <Form.Item label="Số lượng tặng" name="gift_quantity" rules={[{ required: true }]} initialValue={1}>
                                  <InputNumber min={1} style={{ width: "100%" }} />
                                </Form.Item>
                              </Col>
                              <Col span={12}>
                                <Form.Item label="Trị giá quà" name="gift_value" rules={[{ required: true }]} initialValue={0}>
                                  <InputNumber min={0} style={{ width: "100%" }} formatter={(v) => `${v}`.replace(/\B(?=(\d{3})+(?!\d))/g, ",")} addonAfter="đ" />
                                </Form.Item>
                              </Col>
                            </Row>

                            <Form.Item label="Tặng lũy tiến (Mua nhiều tặng nhiều)" name="is_multiply" valuePropName="checked" initialValue={true}>
                              <Switch />
                            </Form.Item>
                          </Card>
                        )}

                        <Form.Item
                          name="maxUsage"
                          label="Giới hạn lượt dùng"
                          initialValue={100}
                        >
                          <InputNumber
                            min={1}
                            style={{ width: "100%" }}
                            addonAfter="lượt"
                          />
                        </Form.Item>
                      </Card>
                    </Col>
                    <Col span={8}>
                      <Card
                        size="small"
                        title="Phạm vi & Đối tượng"
                        style={{ backgroundColor: "#f9f9f9", height: "100%" }}
                      >
                    <Form.Item
                      name="customer_type"
                      label="Hệ thống áp dụng"
                      rules={[
                        {
                          required: true,
                          message: "Vui lòng chọn hệ thống áp dụng",
                        },
                      ]}
                      initialValue="B2C"
                      help="Chọn 'Khách lẻ' để hiện trên POS, 'Đại lý' để hiện trên App đặt hàng B2B."
                    >
                      <Radio.Group buttonStyle="solid">
                        <Radio.Button value="B2C">Khách lẻ (POS)</Radio.Button>
                        <Radio.Button value="B2B">
                          Đại lý / Nhà thuốc (B2B)
                        </Radio.Button>
                      </Radio.Group>
                    </Form.Item>

                    <Form.Item
                      name="type"
                      label="Đối tượng khách hàng"
                      rules={[{ required: true }]}
                    >
                      <Radio.Group buttonStyle="solid">
                        <Radio.Button value="public">
                          <GlobalOutlined /> Công khai
                        </Radio.Button>
                        <Radio.Button value="personal">
                          <UserOutlined /> Tặng Riêng (VIP)
                        </Radio.Button>
                      </Radio.Group>
                    </Form.Item>

                    {promoType === "personal" && (
                      <Form.Item
                        name="selected_customers" // Đổi tên field cho rõ nghĩa
                        label="Chọn Khách hàng (B2B & B2C)"
                        rules={[
                          {
                            required: true,
                            message: "Vui lòng chọn ít nhất 1 khách hàng",
                          },
                        ]}
                        help="Hệ thống sẽ tìm kiếm cả Khách lẻ và Đại lý. Tự động tạo mã riêng cho từng người."
                      >
                        <UniversalCustomerSelect />
                      </Form.Item>
                    )}

                    <Divider />

                    <Form.Item
                      name="apply_to_scope"
                      label="Phạm vi sản phẩm áp dụng"
                    >
                      <Radio.Group>
                        <Radio value="all">Toàn bộ đơn hàng</Radio>
                        <Radio value="product">Theo Sản phẩm</Radio>
                        <Radio value="category">Theo Nhóm hàng</Radio>
                        <Radio value="brand">Theo Nhà sản xuất</Radio>
                      </Radio.Group>
                    </Form.Item>

                    {scopeType === "product" && (
                      <Form.Item
                        name="apply_to_ids"
                        label="Chọn Sản phẩm"
                        rules={[{ required: true }]}
                      >
                        <DebounceProductSelect
                          placeholder="Tìm và chọn sản phẩm..."
                          searchTypes={["product"]}
                        />
                      </Form.Item>
                    )}

                    {scopeType === "category" && (
                      <Form.Item
                        name="apply_to_ids"
                        label="Chọn Nhóm hàng"
                        rules={[{ required: true }]}
                      >
                        <Select
                          placeholder="Chọn nhóm hàng..."
                          showSearch
                          optionFilterProp="children"
                        >
                          {uniqueCategories.map((cat) => (
                            <Option key={cat} value={cat}>
                              {cat}
                            </Option>
                          ))}
                        </Select>
                      </Form.Item>
                    )}
                    {scopeType === "brand" && (
                      <Form.Item
                        name="apply_to_ids"
                        label="Chọn Hãng sản xuất"
                        rules={[{ required: true }]}
                      >
                        <Select
                          placeholder="Chọn hãng sản xuất..."
                          showSearch
                          optionFilterProp="children"
                        >
                          {uniqueManufacturers.map((man) => (
                            <Option key={man} value={man}>
                              {man}
                            </Option>
                          ))}
                        </Select>
                      </Form.Item>
                    )}
                      </Card>
                    </Col>
                  </Row>

          <Form.Item
            name="status"
            label="Trạng thái"
            initialValue="active"
            hidden
          >
            <Input />
          </Form.Item>
        </Form>
      </Modal>

      {/* MODAL CHI TIẾT VOUCHER */}
      <Modal
        title="Chi tiết Voucher / Khuyến Mãi"
        open={isDetailVisible}
        onCancel={() => setIsDetailVisible(false)}
        footer={[
          <Button key="close" onClick={() => setIsDetailVisible(false)}>
            Đóng
          </Button>,
        ]}
        width={600}
      >
        {selectedPromotion && (
          <Descriptions column={1} bordered size="small">
            <Descriptions.Item label="Mã Code">
              <Text copyable strong>{selectedPromotion.code}</Text>
            </Descriptions.Item>
            <Descriptions.Item label="Tên chương trình">
              {selectedPromotion.name}
            </Descriptions.Item>
            <Descriptions.Item label="Loại">
              {((selectedPromotion as any).promotion_type || selectedPromotion.type) === "public" ? "Công khai (Public)" : "Dành riêng (Personal)"}
            </Descriptions.Item>
            <Descriptions.Item label="Giá trị giảm">
              {selectedPromotion.discount_type === "percent" 
                ? `${selectedPromotion.discount_value}%` 
                : `${selectedPromotion.discount_value.toLocaleString("vi-VN")} đ`}
            </Descriptions.Item>
            <Descriptions.Item label="Đã dùng">
              {selectedPromotion.usage_count} / {selectedPromotion.total_usage_limit || "Không giới hạn"}
            </Descriptions.Item>
            <Descriptions.Item label="Thời gian hiệu lực">
              {dayjs(selectedPromotion.valid_from).format("DD/MM/YYYY HH:mm")} - {dayjs(selectedPromotion.valid_to).format("DD/MM/YYYY HH:mm")}
            </Descriptions.Item>
            <Descriptions.Item label="Áp dụng cho">
              {(() => {
                const scope = (selectedPromotion as any).apply_to_scope;
                const ids = (selectedPromotion as any).apply_to_ids;
                if (!scope || scope === 'all') return <span style={{ color: '#52c41a', fontWeight: 500 }}>Tất cả sản phẩm</span>;
                if (scope === 'product') {
                  const displayNames = applyToNames.length > 0 ? applyToNames.join(', ') : (Array.isArray(ids) ? ids.join(', ') : ids);
                  return <span>Sản phẩm cụ thể: <strong>{displayNames}</strong></span>;
                }
                if (scope === 'category') return <span>Danh mục: <strong>{Array.isArray(ids) ? ids.join(', ') : ids}</strong></span>;
                if (scope === 'brand') return <span>Hãng sản xuất: <strong>{Array.isArray(ids) ? ids.join(', ') : ids}</strong></span>;
                return <span>{scope}</span>;
              })()}
            </Descriptions.Item>
            {(selectedPromotion as any).advanced_rules && (
              <Descriptions.Item label="Cấu hình nâng cao (Advanced Rules)">
                <pre style={{ background: "#f5f5f5", padding: 8, borderRadius: 4, maxHeight: 200, overflow: "auto" }}>
                  {JSON.stringify((selectedPromotion as any).advanced_rules, null, 2)}
                </pre>
              </Descriptions.Item>
            )}
          </Descriptions>
        )}
      </Modal>

      {/* Modal QR Code */}
      <Modal
        title="Quét mã để nhận ưu đãi"
        open={isQrModalVisible}
        onCancel={() => setIsQrModalVisible(false)}
        footer={null}
        width={300}
      >
        <div style={{ textAlign: "center", padding: 20 }}>
          <Space direction="vertical" align="center">
            <QRCode
              value={qrCodeValue}
              size={200}
              icon="https://gw.alipayobjects.com/zos/rmsportal/KDpgvguMpGfqaHPjicRK.svg"
            />
            <Title level={3} style={{ margin: 0 }}>
              {qrCodeValue}
            </Title>
            <Text type="secondary">Đưa mã này cho thu ngân</Text>
          </Space>
        </div>
      </Modal>
    </ConfigProvider>
  );
};

export default DiscountCodeManagement;
