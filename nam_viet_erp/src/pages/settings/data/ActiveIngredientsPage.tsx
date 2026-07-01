import {
  SearchOutlined,
  PlusOutlined,
  EditOutlined,
  DeleteOutlined,
  SyncOutlined,
} from "@ant-design/icons";
import {
  Input,
  Table,
  Button,
  Card,
  Typography,
  ConfigProvider,
  Select,
  Row,
  Col,
  Space,
  Tag,
  Form,
  App as AntApp,
  Tooltip,
  Popconfirm,
  Drawer,
  Menu,
} from "antd";
import viVN from "antd/locale/vi_VN";
import { useState, useEffect, useRef } from "react";
import type { TableProps } from "antd";
import JoditEditor from "jodit-react";

import { useActiveIngredientStore } from "@/features/inventory/stores/useActiveIngredientStore";
import { ActiveIngredient } from "@/features/inventory/types/activeIngredient";

const { Title, Text } = Typography;
const { Option } = Select;

// --- DEFINITIONS ---
const statusMap = {
  active: { text: "Đang sử dụng", color: "success" },
  inactive: { text: "Ngừng sử dụng", color: "default" },
};

const SECTIONS = [
  { key: "mo_ta", label: "Mô tả" },
  { key: "chi_dinh", label: "Chỉ định" },
  { key: "duoc_luc_hoc", label: "Dược lực học" },
  { key: "dong_luc_hoc", label: "Động lực học" },
  { key: "trao_doi_chat", label: "Trao đổi chất" },
  { key: "tuong_tac_thuoc", label: "Tương tác thuốc" },
  { key: "chong_chi_dinh", label: "Chống chỉ định" },
  { key: "lieu_luong_cach_dung", label: "Liều lượng & cách dùng" },
  { key: "tac_dung_phu", label: "Tác dụng phụ" },
  { key: "luu_y", label: "Lưu ý" },
  { key: "qua_lieu", label: "Quá liều" },
];

export default function ActiveIngredientsPage() {
  const { message } = AntApp.useApp();
  const {
    ingredients,
    loading,
    fetchIngredients,
    createIngredient,
    updateIngredient,
    deleteIngredient,
  } = useActiveIngredientStore();

  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<"active" | "inactive" | undefined>(undefined);
  
  // Drawer state
  const [isDrawerVisible, setIsDrawerVisible] = useState(false);
  const [editingItem, setEditingItem] = useState<ActiveIngredient | null>(null);
  const [form] = Form.useForm();
  const [submitting, setSubmitting] = useState(false);

  // Editor states
  const [activeSection, setActiveSection] = useState<string>("mo_ta");
  const [sectionContents, setSectionContents] = useState<Record<string, string>>({});
  const editorRef = useRef(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = () => {
    fetchIngredients({ search, status: statusFilter });
  };

  const handleSearch = () => {
    loadData();
  };

  const handleOpenDrawer = (record?: ActiveIngredient) => {
    if (record) {
      setEditingItem(record);
      form.setFieldsValue({
        name: record.name,
        name_intl: record.name_intl,
        atc_code: record.atc_code,
        status: record.status,
      });

      // Parse existing description JSON
      let parsedContents: Record<string, string> = {};
      if (record.description) {
        try {
          parsedContents = JSON.parse(record.description);
        } catch (e) {
          // Fallback if it's not JSON
          parsedContents = { mo_ta: record.description };
        }
      }
      setSectionContents(parsedContents);
    } else {
      setEditingItem(null);
      form.resetFields();
      form.setFieldsValue({ status: "active" });
      setSectionContents({});
    }
    setActiveSection("mo_ta");
    setIsDrawerVisible(true);
  };

  const handleEditorChange = (newContent: string) => {
    setSectionContents(prev => ({
      ...prev,
      [activeSection]: newContent
    }));
  };

  const handleSubmit = async () => {
    try {
      const values = await form.validateFields();
      setSubmitting(true);

      // Serialize rich text sections into JSON string
      const descriptionJson = JSON.stringify(sectionContents);

      const payload = {
        ...values,
        description: descriptionJson,
      };

      if (editingItem) {
        await updateIngredient(editingItem.id, payload);
        message.success("Cập nhật hoạt chất thành công!");
      } else {
        await createIngredient(payload);
        message.success("Thêm mới hoạt chất thành công!");
      }

      setIsDrawerVisible(false);
      loadData();
    } catch (error: any) {
      if (error.errorFields) return;
      message.error(error.message || "Có lỗi xảy ra");
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await deleteIngredient(id);
      message.success("Xóa hoạt chất thành công!");
      loadData();
    } catch (error: any) {
      message.error(error.message || "Lỗi khi xóa hoạt chất");
    }
  };

  const columns: TableProps<ActiveIngredient>["columns"] = [
    {
      title: "Mã (ID)",
      dataIndex: "id",
      key: "id",
      width: 80,
    },
    {
      title: "Tên hoạt chất",
      dataIndex: "name",
      key: "name",
      sorter: (a, b) => a.name.localeCompare(b.name),
    },
    {
      title: "Tên quốc tế (INTL)",
      dataIndex: "name_intl",
      key: "name_intl",
    },
    {
      title: "Mã ATC",
      dataIndex: "atc_code",
      key: "atc_code",
    },
    {
      title: "Trạng thái",
      dataIndex: "status",
      key: "status",
      render: (status: "active" | "inactive") => {
        const conf = statusMap[status] || statusMap.inactive;
        return <Tag color={conf.color}>{conf.text}</Tag>;
      },
    },
    {
      title: "Thao tác",
      key: "action",
      width: 120,
      render: (_, record) => (
        <Space size="middle">
          <Tooltip title="Chỉnh sửa">
            <Button
              type="text"
              icon={<EditOutlined style={{ color: "#1890ff" }} />}
              onClick={() => handleOpenDrawer(record)}
            />
          </Tooltip>
          <Tooltip title="Xóa">
            <Popconfirm
              title="Bạn có chắc chắn muốn xóa hoạt chất này?"
              onConfirm={() => handleDelete(record.id)}
              okText="Xóa"
              cancelText="Hủy"
            >
              <Button
                type="text"
                danger
                icon={<DeleteOutlined />}
              />
            </Popconfirm>
          </Tooltip>
        </Space>
      ),
    },
  ];

  return (
    <ConfigProvider locale={viVN}>
      <div style={{ padding: 24, background: "#f2f7fc", minHeight: "100vh" }}>
        <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
          <Col>
            <Title level={4} style={{ margin: 0 }}>
              Danh Mục Hoạt Chất Dược Phẩm
            </Title>
            <Text type="secondary">
              Quản lý danh sách hoạt chất và thông tin hướng dẫn sử dụng chi tiết
            </Text>
          </Col>
          <Col>
            <Space>
              <Button icon={<SyncOutlined />} onClick={loadData}>
                Làm mới
              </Button>
              <Button
                type="primary"
                icon={<PlusOutlined />}
                onClick={() => handleOpenDrawer()}
              >
                Thêm Mới Hoạt Chất
              </Button>
            </Space>
          </Col>
        </Row>

        <Card bordered={false} className="shadow-sm">
          <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
            <Col xs={24} sm={12} md={8}>
              <Input
                placeholder="Tìm kiếm theo tên hoạt chất..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                onPressEnter={handleSearch}
                prefix={<SearchOutlined />}
                allowClear
              />
            </Col>
            <Col xs={24} sm={12} md={6}>
              <Select
                style={{ width: "100%" }}
                placeholder="Trạng thái"
                value={statusFilter}
                onChange={setStatusFilter}
                allowClear
              >
                <Option value="active">Đang sử dụng</Option>
                <Option value="inactive">Ngừng sử dụng</Option>
              </Select>
            </Col>
            <Col xs={24} sm={24} md={4}>
              <Button type="primary" onClick={handleSearch} block>
                Tìm kiếm
              </Button>
            </Col>
          </Row>

          <Table
            columns={columns}
            dataSource={ingredients}
            rowKey="id"
            loading={loading}
            pagination={{ defaultPageSize: 20 }}
            bordered
            size="middle"
          />
        </Card>

        <Drawer
          title={editingItem ? "Chỉnh Sửa Hoạt Chất" : "Thêm Mới Hoạt Chất"}
          width={1000}
          onClose={() => setIsDrawerVisible(false)}
          open={isDrawerVisible}
          extra={
            <Space>
              <Button onClick={() => setIsDrawerVisible(false)}>Hủy</Button>
              <Button type="primary" onClick={handleSubmit} loading={submitting}>
                Lưu Thay Đổi
              </Button>
            </Space>
          }
        >
          <Form form={form} layout="vertical">
            <Row gutter={16}>
              <Col span={8}>
                <Form.Item
                  name="name"
                  label="Tên hoạt chất"
                  rules={[{ required: true, message: "Vui lòng nhập tên hoạt chất" }]}
                >
                  <Input placeholder="VD: Paracetamol" />
                </Form.Item>
              </Col>
              <Col span={8}>
                <Form.Item name="name_intl" label="Tên quốc tế (Quốc tế)">
                  <Input placeholder="VD: Acetaminophen" />
                </Form.Item>
              </Col>
              <Col span={4}>
                <Form.Item name="atc_code" label="Mã ATC">
                  <Input placeholder="VD: N02BE01" />
                </Form.Item>
              </Col>
              <Col span={4}>
                <Form.Item name="status" label="Trạng thái">
                  <Select>
                    <Option value="active">Đang sử dụng</Option>
                    <Option value="inactive">Ngừng sử dụng</Option>
                  </Select>
                </Form.Item>
              </Col>
            </Row>

            <Title level={5} style={{ marginTop: 16 }}>Nội dung chi tiết (Hướng dẫn sử dụng)</Title>
            <Row gutter={16} style={{ height: "500px" }}>
              <Col span={6} style={{ borderRight: "1px solid #f0f0f0" }}>
                <Menu
                  mode="inline"
                  selectedKeys={[activeSection]}
                  onClick={(e) => setActiveSection(e.key)}
                  items={SECTIONS.map((sec) => ({
                    key: sec.key,
                    label: (
                      <span style={{ fontWeight: sectionContents[sec.key] ? "bold" : "normal" }}>
                        {sec.label}
                      </span>
                    ),
                  }))}
                  style={{ height: "100%", borderRight: "none" }}
                />
              </Col>
              <Col span={18}>
                <JoditEditor
                  ref={editorRef}
                  value={sectionContents[activeSection] || ""}
                  config={{
                    readonly: false,
                    height: 480,
                    placeholder: `Nhập nội dung cho phần "${SECTIONS.find(s => s.key === activeSection)?.label}"...`,
                  }}
                  onBlur={newContent => handleEditorChange(newContent)}
                />
              </Col>
            </Row>
          </Form>
        </Drawer>
      </div>
    </ConfigProvider>
  );
}
