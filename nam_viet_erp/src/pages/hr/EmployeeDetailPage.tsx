import React from "react";
import { useParams } from "react-router-dom";
import {
  Layout,
  Typography,
  Card,
  Descriptions,
  Table,
  Tabs,
  Button,
  Space,
  Tooltip,
  Tag,
  Progress,
  Spin,
  Alert,
} from "antd";
import { QuestionCircleOutlined } from "@ant-design/icons";
import { useEmployeeDetail } from "@/features/hr/hooks/useEmployees";
import { useCalculatePayroll } from "@/features/hr/hooks/usePayroll";
import { useKpiTargetsByEmployee } from "@/features/hr/hooks/useKpi";
import { useAuthStore } from "@/features/auth/stores/useAuthStore";
import type { KpiTarget } from "@/features/hr/types/hrTypes";
import dayjs from "dayjs";

const { Content } = Layout;
const { Title, Text } = Typography;

const EmployeeDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const { data: employee, isLoading } = useEmployeeDetail(id || "");
  const { mutate: calculatePayroll, isPending } = useCalculatePayroll();
  const { profile } = useAuthStore();

  const month = dayjs().month() + 1;
  const year = dayjs().year();

  // Load KPI targets cho nhân viên này
  const { data: kpiTargets = [], isLoading: kpiLoading } = useKpiTargetsByEmployee(
    id || "",
    month,
    year
  );

  const userProfile = profile as any;
  const canCalculatePayroll =
    userProfile?.role === "Admin" || userProfile?.role === "HR_Manager";

  const handleCalculatePayroll = () => {
    if (!id) return;
    calculatePayroll({ id, month, year });
  };

  const contractColumns = [
    { title: "Loại hợp đồng", dataIndex: "contract_type" },
    {
      title: "Lương cơ bản",
      dataIndex: "base_salary",
      render: (val: number) => val?.toLocaleString() + " đ",
    },
    { title: "Ngày bắt đầu", dataIndex: "start_date" },
    { title: "Trạng thái", dataIndex: "status" },
  ];

  const payrollColumns = [
    { title: "Tháng", render: (_: any, r: any) => `${r.month}/${r.year}` },
    {
      title: "Lương cơ bản",
      dataIndex: "base_salary",
      render: (val: number) => val?.toLocaleString() + " đ",
    },
    {
      title: (
        <Space>
          Hoa hồng
          <Tooltip title="Hoa hồng được tính dựa trên % doanh thu đạt được trong tháng">
            <QuestionCircleOutlined style={{ color: "#aaa" }} />
          </Tooltip>
        </Space>
      ),
      dataIndex: "commission",
      render: (val: number, record: any) => (
        <Tooltip
          title={
            record.commission_note ||
            (val ? `Hoa hồng từ doanh thu tháng ${record.month}/${record.year}` : "Chưa có dữ liệu")
          }
        >
          <Text style={{ color: val ? "#1677ff" : undefined }}>
            {val?.toLocaleString() ?? 0} đ
          </Text>
        </Tooltip>
      ),
    },
    {
      title: (
        <Space>
          Thưởng KPI
          <Tooltip title="Thưởng hiệu suất dựa trên việc đạt/vượt chỉ tiêu KPI được giao">
            <QuestionCircleOutlined style={{ color: "#aaa" }} />
          </Tooltip>
        </Space>
      ),
      dataIndex: "kpi_bonus",
      render: (val: number, record: any) => (
        <Tooltip
          title={
            record.kpi_bonus_note ||
            (val ? `Thưởng KPI tháng ${record.month}/${record.year}` : "Chưa đủ điều kiện thưởng")
          }
        >
          <Text style={{ color: val ? "#52c41a" : undefined }}>
            {val?.toLocaleString() ?? 0} đ
          </Text>
        </Tooltip>
      ),
    },
    {
      title: "Tổng thực nhận",
      dataIndex: "total_salary",
      render: (val: number) => <Text strong>{val?.toLocaleString()} đ</Text>,
    },
    { title: "Trạng thái", dataIndex: "status" },
  ];

  // Cột bảng KPI targets
  const kpiColumns = [
    {
      title: "Chỉ số",
      dataIndex: "metric_name",
      render: (val: string, record: KpiTarget) => val || record.metric_code,
    },
    {
      title: "Chỉ tiêu",
      dataIndex: "target_value",
      render: (val: number, record: KpiTarget) =>
        `${val?.toLocaleString()} ${record.unit || ""}`,
    },
    {
      title: "Thực tế",
      dataIndex: "actual_value",
      render: (val: number, record: KpiTarget) =>
        val !== undefined && val !== null
          ? `${val.toLocaleString()} ${record.unit || ""}`
          : <Tag color="default">Chưa cập nhật</Tag>,
    },
    {
      title: "Tiến độ",
      render: (_: any, record: KpiTarget) => {
        if (record.actual_value === undefined || record.actual_value === null) return null;
        const pct = Math.min((record.actual_value / record.target_value) * 100, 100);
        const color = pct >= 80 ? "#52c41a" : pct >= 50 ? "#fa8c16" : "#ff4d4f";
        return (
          <Progress
            percent={parseFloat(pct.toFixed(1))}
            strokeColor={color}
            status={pct >= 80 ? "success" : pct < 50 ? "exception" : "normal"}
            size="small"
          />
        );
      },
    },
  ];

  if (isLoading) return <div style={{ padding: 24 }}>Đang tải...</div>;
  if (!employee) return <div style={{ padding: 24 }}>Không tìm thấy nhân viên</div>;

  return (
    <Layout style={{ minHeight: "100vh", background: "transparent" }}>
      <Content style={{ padding: "24px", maxWidth: 1200, margin: "0 auto", width: "100%" }}>
        <Title level={3}>Hồ sơ Nhân viên: {employee.full_name}</Title>
        <Card style={{ marginBottom: 24 }}>
          <Descriptions bordered column={2}>
            <Descriptions.Item label="Mã NV">{employee.employee_code}</Descriptions.Item>
            <Descriptions.Item label="Email">{employee.email}</Descriptions.Item>
            <Descriptions.Item label="Vị trí">{employee.position}</Descriptions.Item>
          </Descriptions>
        </Card>

        <Tabs defaultActiveKey="1">
          <Tabs.TabPane tab="Hợp đồng" key="1">
            <Table
              dataSource={employee.contracts || []}
              columns={contractColumns}
              rowKey="id"
              pagination={false}
            />
          </Tabs.TabPane>

          <Tabs.TabPane tab="Bảng lương" key="2">
            <Space direction="vertical" style={{ width: "100%" }}>
              <Space>
                <Button
                  type="primary"
                  onClick={handleCalculatePayroll}
                  loading={isPending}
                  disabled={!canCalculatePayroll}
                >
                  Tính lương tháng {month}/{year}
                </Button>
                {!canCalculatePayroll && (
                  <Text type="secondary">Bạn không có quyền tính lương</Text>
                )}
              </Space>
              <Table
                dataSource={employee.payrolls || []}
                columns={payrollColumns}
                rowKey="id"
                pagination={false}
              />
            </Space>
          </Tabs.TabPane>

          <Tabs.TabPane tab="Chỉ tiêu KPI" key="3">
            <Space direction="vertical" style={{ width: "100%" }}>
              <Alert
                type="info"
                showIcon
                message={`Chỉ tiêu KPI tháng ${month}/${year}`}
                description="Dữ liệu thực tế được cập nhật tự động từ hệ thống đơn hàng và tài chính."
                style={{ marginBottom: 16 }}
              />
              {kpiLoading ? (
                <Spin tip="Đang tải KPI..." />
              ) : kpiTargets.length === 0 ? (
                <Text type="secondary">
                  Chưa có chỉ tiêu KPI nào được giao cho tháng này.
                </Text>
              ) : (
                <Table
                  dataSource={kpiTargets}
                  columns={kpiColumns}
                  rowKey={(r) => `${r.metric_code}_${r.month}_${r.year}`}
                  pagination={false}
                />
              )}
            </Space>
          </Tabs.TabPane>
        </Tabs>
      </Content>
    </Layout>
  );
};

export default EmployeeDetailPage;
