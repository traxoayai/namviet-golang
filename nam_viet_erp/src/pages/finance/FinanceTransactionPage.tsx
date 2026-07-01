// src/pages/finance/FinanceTransactionPage.tsx
import {
  ArrowUpOutlined,
  ArrowDownOutlined,
  WalletOutlined,
  FilterOutlined,
  CheckCircleOutlined,
  ClockCircleOutlined,
  FileExcelOutlined,
  EyeOutlined,
  AuditOutlined,
  DeleteOutlined,
  StopOutlined,
  PrinterOutlined, // [NEW]
} from "@ant-design/icons";
import {
  Layout,
  Card,
  Table,
  Button,
  Tag,
  Row,
  Col,
  Statistic,
  DatePicker,
  Select,
  Space,
  Popconfirm,
  Tooltip,
  Input,
  App,
  Modal, // [NEW]
  Form, // [NEW]
  Grid,
  List,
  Drawer,
} from "antd";
import dayjs from "dayjs";
import timezone from "dayjs/plugin/timezone";
import utc from "dayjs/plugin/utc";
import { useState, useEffect } from "react";
import { useQueryClient } from "@tanstack/react-query";

import { FinanceFormModal } from "./components/FinanceFormModal";
import { TransactionDetailModal } from "./components/TransactionDetailModal"; // Import Modal mới
import { FinanceAllocationNestedTable } from "./components/FinanceAllocationNestedTable"; // [NEW]
import { useFinanceTransactionLogic } from "./hooks/useFinanceTransactionLogic";

import { PERMISSIONS } from "@/features/auth/constants/permissions"; // [NEW]
import { useAuthStore } from "@/features/auth/stores/useAuthStore";
import { useUserStore } from "@/features/auth/stores/useUserStore"; // [NEW]
import { useFinanceStore } from "@/features/finance/stores/useFinanceStore";
import { useTransactionCategoryStore } from "@/features/finance/stores/useTransactionCategoryStore";
import { TransactionRecord } from "@/features/finance/types/finance";
import { Access } from "@/shared/components/auth/Access"; // [NEW]
import { supabase } from "@/shared/lib/supabaseClient"; // [NEW]
import { generatePaymentVoucherHTML } from "@/shared/utils/printTemplates"; // [NEW]
import { printHTML } from "@/shared/utils/printUtils"; // [RESTORED]

dayjs.extend(utc);
dayjs.extend(timezone);

const { Content } = Layout;
const { RangePicker } = DatePicker;

const FinanceTransactionPage = () => {
  const queryClient = useQueryClient();
  const logic = useFinanceTransactionLogic();
  const { confirmTransaction, exportExcel, deleteTransaction } =
    useFinanceStore();
  const { message } = App.useApp();
  const [viewRecord, setViewRecord] = useState<TransactionRecord | null>(null);
  const { users, fetchUsers } = useUserStore(); // [NEW]

  // [NEW] GL specific states
  const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);
  const { categories, fetchCategories } = useTransactionCategoryStore();
  const [editGLRecord, setEditGLRecord] = useState<TransactionRecord | null>(
    null
  );
  const [glCategory, setGlCategory] = useState<number | undefined>(undefined);
  const [glBookType, setGlBookType] = useState<string>("INTERNAL");
  const [isFilterDrawerOpen, setIsFilterDrawerOpen] = useState(false);

  // [FIX] Use useEffect to prevent infinite render loops
  useEffect(() => {
    fetchUsers();
    fetchCategories();
  }, []);

  // [NEW] Lấy danh sách quyền của user hiện tại
  const { permissions } = useAuthStore();

  // Helper check quyền nhanh
  const canApprove =
    permissions.includes("finance.approve") ||
    permissions.includes("admin-all");
  const canExecute =
    permissions.includes("finance.execute") ||
    permissions.includes("admin-all");

  // Chỉ xóa phiếu Pending và có quyền xóa
  const canDelete = (record: TransactionRecord) =>
    record.status === "pending" &&
    (permissions.includes("finance.delete") ||
      permissions.includes("admin-all"));

  // Optimistic Update cho thay đổi trạng thái
  const handleOptimisticStatus = async (
    id: number,
    targetStatus: "approved" | "completed" | "cancelled"
  ) => {
    // 1. Cập nhật UI ngay lập tức
    queryClient.setQueryData(
      ["finance_transactions", logic.page, logic.pageSize, logic.filters],
      (oldData: any) => {
        if (!oldData) return oldData;
        return {
          ...oldData,
          data: oldData.data.map((t: any) =>
            t.id === id ? { ...t, status: targetStatus } : t
          ),
        };
      }
    );

    // 2. Thực thi API
    let success = false;
    if (targetStatus === "cancelled") {
      success = await deleteTransaction(id);
    } else {
      success = await confirmTransaction(id, targetStatus);
    }

    // 3. Xử lý sau khi gọi API
    if (!success) {
      // Khôi phục lại dữ liệu nếu lỗi
      logic.fetchTransactions();
    } else {
      // Reload ngầm để đồng bộ (VD: lấy thời gian cập nhật mới nhất)
      logic.fetchTransactions();
    }
  };

  const handleDelete = async (id: number) => {
    await handleOptimisticStatus(id, "cancelled");
  };

  // [NEW] Handlers for GL
  const handleSaveGLEdits = async () => {
    if (!editGLRecord) return;
    try {
      const { error } = await supabase
        .from("finance_transactions")
        .update({
          book_type: glBookType,
          category_id: glCategory,
        })
        .eq("id", editGLRecord.id);

      if (error) throw error;
      message.success("Đã cập nhật thông tin hạch toán");
      setEditGLRecord(null);
      logic.fetchTransactions();
    } catch (e: any) {
      message.error("Lỗi cập nhật: " + e.message);
    }
  };

  const handleBulkPost = async () => {
    if (selectedRowKeys.length === 0) {
      message.warning("Vui lòng chọn ít nhất 1 phiếu để hạch toán");
      return;
    }
    const success = await logic.postTransactionsToGL(
      selectedRowKeys as number[]
    );
    if (success) {
      setSelectedRowKeys([]);
    }
  };

  // [NEW] Print Handler
  const handlePrint = (record: TransactionRecord) => {
    const html = generatePaymentVoucherHTML(record);
    printHTML(html);
  };

  const screens = Grid.useBreakpoint();
  const isMobile = screens.xs || (screens.sm && !screens.md);

  const renderStatusTag = (status: string) => {
    if (status === "completed")
      return (
        <Tag icon={<CheckCircleOutlined />} color="success">
          Hoàn tất
        </Tag>
      );
    if (status === "approved")
      return (
        <Tag icon={<AuditOutlined />} color="processing">
          Đã duyệt chi
        </Tag>
      );
    if (status === "cancelled")
      return (
        <Tag icon={<StopOutlined />} color="error">
          Đã hủy
        </Tag>
      );

    return (
      <Tag icon={<ClockCircleOutlined />} color="warning">
        Mới tạo
      </Tag>
    );
  };

  const renderActions = (record: TransactionRecord) => (
    <Space size="small" wrap>
      <Tooltip title="In Phiếu">
        <Button
          size="small"
          icon={<PrinterOutlined />}
          onClick={() => handlePrint(record)}
        />
      </Tooltip>

      {record.flow === "in" && record.status === "pending" && canExecute ? (
        <Tooltip title="Xác nhận đã nhận tiền">
          <Popconfirm
            title="Xác nhận ĐÃ THU tiền?"
            description="Số dư quỹ sẽ tăng ngay lập tức."
            onConfirm={() => handleOptimisticStatus(record.id, "completed")}
            okText="Đã Thu"
            okType="primary"
          >
            <Button
              size="small"
              type="primary"
              ghost
              icon={<CheckCircleOutlined />}
            >
              Đã Thu
            </Button>
          </Popconfirm>
        </Tooltip>
      ) : null}

      {record.flow === "out" && record.status === "pending" && canApprove ? (
        <Tooltip title="Quản lý duyệt chi">
          <Popconfirm
            title="Duyệt khoản chi này?"
            description="Chưa trừ tiền quỹ. Chỉ đánh dấu là được phép chi."
            onConfirm={() => handleOptimisticStatus(record.id, "approved")}
            okText="Duyệt"
          >
            <Button
              size="small"
              type="default"
              icon={<AuditOutlined />}
              style={{ borderColor: "#faad14", color: "#faad14" }}
            >
              Duyệt
            </Button>
          </Popconfirm>
        </Tooltip>
      ) : null}

      {record.flow === "out" && record.status === "approved" && canExecute ? (
        <Tooltip title="Thủ quỹ xác nhận xuất tiền">
          <Popconfirm
            title="Xác nhận ĐÃ CHI tiền?"
            description="Tiền sẽ bị trừ khỏi Sổ Quỹ."
            onConfirm={() => handleOptimisticStatus(record.id, "completed")}
            okText="Đã Chi"
            okType="primary"
          >
            <Button
              size="small"
              type="primary"
              danger
              ghost
              icon={<WalletOutlined />}
            >
              Xuất Tiền
            </Button>
          </Popconfirm>
        </Tooltip>
      ) : null}

      <Tooltip title="Xem chi tiết">
        <Button
          size="small"
          icon={<EyeOutlined />}
          onClick={() => setViewRecord(record)}
        />
      </Tooltip>

      <Tooltip title="Cập nhật Hạch toán">
        <Button
          size="small"
          icon={<AuditOutlined />}
          onClick={() => {
            setEditGLRecord(record);
            setGlCategory(record.category_id);
            setGlBookType(record.book_type || "INTERNAL");
          }}
        />
      </Tooltip>

      {canDelete(record) && (
        <Tooltip title="Hủy phiếu">
          <Popconfirm
            title="Hủy phiếu này?"
            onConfirm={() => handleDelete(record.id)}
          >
            <Button size="small" danger icon={<DeleteOutlined />} />
          </Popconfirm>
        </Tooltip>
      )}
    </Space>
  );

  const columns = [
    {
      title: "Mã Phiếu",
      dataIndex: "code",
      width: 160,
      render: (code: string) => <Tag color="blue">{code}</Tag>,
    },
    {
      title: "Người tạo",
      dataIndex: "creator_name", // [FIX] Map field creator_name
      width: 150,
      render: (name: string) => (
        <Tag color="cyan" style={{ margin: 0 }}>
          {name || "N/A"}
        </Tag>
      ),
    },
    {
      title: "Ngày thu/chi", // Đổi tên cho rõ nghĩa
      dataIndex: "transaction_date",
      width: 150, // Tăng độ rộng một chút
      // AURA FIX: Format hiển thị Giờ trước, Ngày sau để dễ nhìn
      render: (date: string) => {
        if (!date) return "--";
        const vnTime = dayjs(date).tz("Asia/Ho_Chi_Minh");
        return (
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              lineHeight: 1.2,
            }}
          >
            <span style={{ fontWeight: 500 }}>{vnTime.format("HH:mm")}</span>
            <span style={{ fontSize: 12, color: "#888" }}>
              {vnTime.format("DD/MM/YYYY")}
            </span>
          </div>
        );
      },
    },
    // --- SỬA LỖI 4: Thêm cột Diễn giải ---
    {
      title: "Nội dung / Diễn giải",
      dataIndex: "description",
      render: (text: string, record: TransactionRecord) => (
        <div style={{ maxWidth: 300 }}>
          <div className="font-medium text-blue-800">{record.partner_name}</div>
          <div
            className="text-xs text-gray-600"
            style={{ whiteSpace: "pre-wrap" }}
          >
            {text}
          </div>
          <Tag style={{ marginTop: 4 }}>{record.business_type}</Tag>
        </div>
      ),
    },
    {
      title: "Số tiền",
      key: "amount",
      align: "right" as const,
      width: 150,
      render: (_: any, record: TransactionRecord) => (
        <span
          style={{
            color: record.flow === "in" ? "#52c41a" : "#f5222d",
            fontWeight: "bold",
            fontSize: 15,
          }}
        >
          {record.flow === "in" ? "+" : "-"}
          {Number(record.amount).toLocaleString()}
        </span>
      ),
    },
    {
      title: "Trạng thái",
      dataIndex: "status",
      align: "center" as const,
      width: 130,
      render: renderStatusTag,
    },
    {
      title: "Hạch toán",
      dataIndex: "is_posted",
      align: "center" as const,
      width: 130,
      render: (is_posted: boolean) => {
        if (is_posted) return <Tag color="blue">Đã ghi sổ</Tag>;
        return <Tag color="default">Chưa ghi sổ</Tag>;
      },
    },
    {
      title: "Hành động",
      key: "action",
      width: 250, // Tăng độ rộng một chút
      fixed: "right" as const,
      align: "center" as const,
      render: (_: any, record: TransactionRecord) => renderActions(record),
    },
  ];

  const renderFilters = () => (
    <Space direction="vertical" style={{ width: "100%" }}>
      <Select
        placeholder="Loại phiếu (Thu / Chi)"
        allowClear
        style={{ width: "100%" }}
        value={logic.filters.flow || undefined}
        onChange={(val) => logic.setFilters({ flow: val })}
      >
        <Select.Option value="in">
          <Tag color="green" style={{ margin: 0 }}>
            Phiếu Thu (+)
          </Tag>
        </Select.Option>
        <Select.Option value="out">
          <Tag color="red" style={{ margin: 0 }}>
            Phiếu Chi (-)
          </Tag>
        </Select.Option>
      </Select>
      <Select
        placeholder="Trạng thái"
        allowClear
        style={{ width: "100%" }}
        value={logic.filters.status || undefined}
        onChange={(val) => logic.setFilters({ status: val })}
      >
        <Select.Option value="pending">Chờ duyệt</Select.Option>
        <Select.Option value="confirmed">Đã duyệt</Select.Option>
        <Select.Option value="completed">Đã hoàn tất</Select.Option>
        <Select.Option value="cancelled">Đã hủy</Select.Option>
      </Select>
      <Select
        placeholder="Người tạo"
        allowClear
        style={{ width: "100%" }}
        showSearch
        optionFilterProp="children"
        onChange={(val) => logic.setFilters({ creatorId: val })}
      >
        {users
          .filter((u) => u.status === "active" && u.work_state === "working")
          .map((u) => (
            <Select.Option key={u.key} value={u.key}>
              {u.full_name || u.name || u.email}
            </Select.Option>
          ))}
      </Select>
      <RangePicker
        style={{ width: "100%" }}
        placeholder={["Từ ngày", "Đến ngày"]}
        onChange={(dates) =>
          logic.setFilters({
            date_from: dates?.[0]?.toISOString(),
            date_to: dates?.[1]?.toISOString(),
          })
        }
      />
    </Space>
  );

  return (
    <Layout style={{ minHeight: "100vh", background: "#f2f7fc" }}>
      <Content style={{ padding: isMobile ? 8 : 12 }}>
        <Row gutter={16} style={{ marginBottom: isMobile ? 12 : 24 }}>
          <Col xs={24} sm={12} md={8}>
            <Card bordered={false} bodyStyle={isMobile ? { padding: 12 } : {}}>
              <Access
                permission={PERMISSIONS.FINANCE.VIEW_BALANCE}
                hide={true} // [FIX] Bắt buộc ẩn và hiện fallback
                fallback={
                  // Hiển thị khi không có quyền
                  <Statistic
                    title={
                      isMobile
                        ? "Tổng Quỹ"
                        : "Tổng Quỹ Thực Tế (Tất cả các quỹ)"
                    }
                    value="***"
                    valueStyle={{
                      color: "#1890ff",
                      filter: "blur(4px)",
                      fontSize: isMobile ? 20 : 24,
                    }}
                    prefix={<WalletOutlined />}
                  />
                }
              >
                <Statistic
                  title={
                    isMobile ? "Tổng Quỹ" : "Tổng Quỹ Thực Tế (Tất cả các quỹ)"
                  }
                  value={logic.totalBalance}
                  precision={0}
                  valueStyle={{
                    color: "#1890ff",
                    fontSize: isMobile ? 20 : 24,
                  }}
                  prefix={<WalletOutlined />}
                  suffix="đ"
                />
              </Access>
            </Card>
          </Col>
        </Row>

        <Card bordered={false} bodyStyle={isMobile ? { padding: 12 } : {}}>
          <div
            style={{
              marginBottom: 16,
              display: "flex",
              justifyContent: "space-between",
              flexWrap: "wrap",
              gap: 12,
            }}
          >
            <Space wrap style={{ flex: 1 }}>
              {/* --- SỬA LỖI 5: Mở rộng ô tìm kiếm --- */}
              <Input.Search
                placeholder={
                  isMobile
                    ? "Tìm kiếm..."
                    : "Tìm mã phiếu, Tên người tạo, Nội dung phiếu ..."
                }
                style={{ width: isMobile ? "calc(100vw - 80px)" : 400 }}
                allowClear
                onSearch={(val) => logic.setFilters({ search: val })}
                enterButton
              />
              {isMobile ? (
                <Button
                  icon={<FilterOutlined />}
                  onClick={() => setIsFilterDrawerOpen(true)}
                />
              ) : (
                <Space wrap>
                  <Select
                    placeholder="Loại phiếu (Thu / Chi)"
                    allowClear
                    style={{ width: 160 }}
                    value={logic.filters.flow || undefined}
                    onChange={(val) => logic.setFilters({ flow: val })}
                  >
                    <Select.Option value="in">
                      <Tag color="green" style={{ margin: 0 }}>
                        Phiếu Thu (+)
                      </Tag>
                    </Select.Option>
                    <Select.Option value="out">
                      <Tag color="red" style={{ margin: 0 }}>
                        Phiếu Chi (-)
                      </Tag>
                    </Select.Option>
                  </Select>
                  <Select
                    placeholder="Trạng thái"
                    allowClear
                    style={{ width: 140 }}
                    value={logic.filters.status || undefined}
                    onChange={(val) => logic.setFilters({ status: val })}
                  >
                    <Select.Option value="pending">Chờ duyệt</Select.Option>
                    <Select.Option value="confirmed">Đã duyệt</Select.Option>
                    <Select.Option value="completed">Đã hoàn tất</Select.Option>
                    <Select.Option value="cancelled">Đã hủy</Select.Option>
                  </Select>
                  <Select
                    placeholder="Người tạo"
                    allowClear
                    style={{ width: 180 }}
                    showSearch
                    optionFilterProp="children"
                    onChange={(val) => logic.setFilters({ creatorId: val })}
                  >
                    {users
                      // [FIX] Chỉ hiện nhân viên Active và Đang làm việc (Bỏ qua 'test', 'resigned')
                      .filter(
                        (u) =>
                          u.status === "active" && u.work_state === "working"
                      )
                      .map((u) => (
                        <Select.Option key={u.key} value={u.key}>
                          {u.full_name || u.name || u.email}{" "}
                          {/* [FIX] Dùng full_name ưu tiên */}
                        </Select.Option>
                      ))}
                  </Select>
                  <RangePicker
                    style={{ width: 240 }}
                    placeholder={["Từ ngày", "Đến ngày"]}
                    onChange={(dates) =>
                      logic.setFilters({
                        date_from: dates?.[0]?.toISOString(),
                        date_to: dates?.[1]?.toISOString(),
                      })
                    }
                  />
                </Space>
              )}
            </Space>

            <Space wrap>
              {isMobile ? null : (
                <Button
                  type="primary"
                  icon={<AuditOutlined />}
                  onClick={handleBulkPost}
                  disabled={selectedRowKeys.length === 0}
                >
                  Hạch toán Sổ Cái
                </Button>
              )}
              {isMobile ? null : (
                <Button icon={<FileExcelOutlined />} onClick={exportExcel}>
                  Xuất Excel
                </Button>
              )}
              <Button
                type="primary"
                style={{ backgroundColor: "#52c41a", borderColor: "#52c41a" }}
                icon={<ArrowUpOutlined />}
                onClick={() => logic.openCreateModal("in")}
              >
                {isMobile ? "" : "Lập Phiếu Thu"}
              </Button>
              <Button
                type="primary"
                danger
                icon={<ArrowDownOutlined />}
                onClick={() => logic.openCreateModal("out")}
              >
                {isMobile ? "" : "Lập Phiếu Chi"}
              </Button>
            </Space>
          </div>

          <Drawer
            title="Lọc giao dịch"
            placement="right"
            onClose={() => setIsFilterDrawerOpen(false)}
            open={isFilterDrawerOpen}
            width={280}
          >
            {renderFilters()}
          </Drawer>

          {isMobile ? (
            <List
              loading={logic.loading}
              dataSource={logic.transactions}
              renderItem={(record: TransactionRecord) => (
                <List.Item style={{ padding: "12px 0", borderBottom: "none" }}>
                  <Card
                    size="small"
                    style={{
                      width: "100%",
                      borderRadius: 12,
                      boxShadow: "0 2px 8px rgba(0,0,0,0.06)",
                    }}
                  >
                    <div
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        marginBottom: 8,
                      }}
                    >
                      <span style={{ fontWeight: 600, color: "#1890ff" }}>
                        {record.code}
                      </span>
                      <span
                        style={{
                          color: record.flow === "in" ? "#52c41a" : "#f5222d",
                          fontWeight: "bold",
                          fontSize: 16,
                        }}
                      >
                        {record.flow === "in" ? "+" : "-"}
                        {Number(record.amount).toLocaleString()}
                      </span>
                    </div>
                    <div style={{ marginBottom: 4 }}>
                      <Tag color={record.flow === "in" ? "green" : "red"}>
                        {record.flow === "in" ? "THU" : "CHI"}
                      </Tag>
                      <span style={{ color: "#888", fontSize: 12 }}>
                        {dayjs(record.transaction_date)
                          .tz("Asia/Ho_Chi_Minh")
                          .format("HH:mm - DD/MM/YYYY")}
                      </span>
                    </div>
                    <div
                      style={{ marginBottom: 12, fontSize: 13, color: "#555" }}
                    >
                      <strong>{record.partner_name}</strong> -{" "}
                      {record.description}
                    </div>
                    <div
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                      }}
                    >
                      <div>{renderStatusTag(record.status)}</div>
                      <div>{renderActions(record)}</div>
                    </div>
                  </Card>
                </List.Item>
              )}
              pagination={{
                current: logic.page,
                pageSize: logic.pageSize,
                total: logic.totalCount,
                onChange: logic.setPage,
              }}
            />
          ) : (
            <Table
              rowSelection={{
                selectedRowKeys,
                onChange: (keys) => setSelectedRowKeys(keys),
              }}
              dataSource={logic.transactions}
              columns={columns}
              rowKey="id"
              loading={logic.loading}
              pagination={{
                current: logic.page,
                pageSize: logic.pageSize,
                total: logic.totalCount,
                onChange: logic.setPage,
                showSizeChanger: true,
              }}
              scroll={{ x: 1000 }}
              expandable={{
                expandedRowRender: (record) => (
                  <FinanceAllocationNestedTable transactionId={record.id} />
                ),
              }}
            />
          )}
        </Card>

        <FinanceFormModal
          open={logic.isModalOpen}
          onCancel={() => logic.setIsModalOpen(false)}
          initialFlow={logic.modalFlow}
        />
        <TransactionDetailModal
          open={!!viewRecord}
          data={viewRecord}
          onCancel={() => setViewRecord(null)}
        />

        {/* [NEW] Modal cập nhật Hạch toán */}
        <Modal
          title="Cập nhật thông tin Hạch toán Sổ Cái"
          open={!!editGLRecord}
          onCancel={() => setEditGLRecord(null)}
          onOk={handleSaveGLEdits}
        >
          <Form layout="vertical">
            <Form.Item label="Lý do / Phân loại (Category)">
              <Select
                showSearch
                optionFilterProp="children"
                value={glCategory}
                onChange={setGlCategory}
              >
                {categories.map((cat) => (
                  <Select.Option key={cat.id} value={cat.id}>
                    {cat.name} ({cat.type === "thu" ? "Thu" : "Chi"})
                  </Select.Option>
                ))}
              </Select>
            </Form.Item>
            <Form.Item label="Ghi vào Sổ">
              <Select value={glBookType} onChange={setGlBookType}>
                <Select.Option value="INTERNAL">Sổ Nội Bộ</Select.Option>
                <Select.Option value="TAX">Sổ Thuế (VAT)</Select.Option>
                <Select.Option value="BOTH">Cả 2 sổ (BOTH)</Select.Option>
              </Select>
            </Form.Item>
          </Form>
        </Modal>
      </Content>
    </Layout>
  );
};

export default FinanceTransactionPage;
