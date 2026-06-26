import React, { useState, useMemo } from "react";
import {
  Layout,
  Typography,
  Card,
  Table,
  Button,
  Select,
  Space,
  InputNumber,
  Alert,
  Tag,
  Tooltip,
  Row,
  Col,
} from "antd";
import { SaveOutlined, PlusOutlined, DeleteOutlined, InfoCircleOutlined } from "@ant-design/icons";
import dayjs from "dayjs";
import { useAssignKpiTarget, useKpiMetrics } from "@/features/hr/hooks/useKpi";
import { useAuthStore } from "@/features/auth/stores/useAuthStore";
import { hrService } from "@/features/hr/api/hrService";
import { useQuery } from "@tanstack/react-query";
import type { KpiTargetPayload, KpiMetric } from "@/features/hr/types/hrTypes";
import { PERMISSIONS } from "@/features/auth/constants/permissions";

const { Content } = Layout;
const { Title, Text } = Typography;

interface KpiRow {
  key: string;
  employee_id: string;
  employee_name: string;
  metric_code: string;
  target_value: number | null;
}

const MONTHS = Array.from({ length: 12 }, (_, i) => ({ label: `Tháng ${i + 1}`, value: i + 1 }));
const YEARS = [2024, 2025, 2026, 2027].map((y) => ({ label: `${y}`, value: y }));

const getKpiUnit = (code: string) => {
  if (!code) return "";
  if (["SALES_REVENUE", "LOGISTICS_COD", "B2B_PAID_REVENUE", "B2B_AOV"].includes(code)) return "VNĐ";
  if (["LOGISTICS_ORDER_COUNT"].includes(code)) return "Đơn";
  if (["B2B_DSO"].includes(code)) return "Ngày";
  if (["LOGISTICS_SLA_4H", "LOGISTICS_COD_48H", "B2B_RETENTION", "B2B_GROSS_MARGIN", "WH_MINMAX_COMPLIANCE", "WH_AGING_STOCK"].includes(code)) return "%";
  return "";
};

const KpiAssignmentPage: React.FC = () => {
  const { profile, permissions } = useAuthStore();
  const userProfile = profile as any;

  const isAdmin = permissions.includes("admin-all") || permissions.includes("portal.manage") || userProfile?.role_id != null; // Tạm thời nới lỏng hoặc dùng admin-all
  const canAssign = isAdmin || permissions.includes(PERMISSIONS.HR.ASSIGN_KPI);
  const myDepartmentId: string | undefined = userProfile?.department_id;

  const currentMonth = dayjs().month() + 1;
  const currentYear = dayjs().year();

  const [selectedMonth, setSelectedMonth] = useState(currentMonth);
  const [selectedYear, setSelectedYear] = useState(currentYear);
  const [selectedDepartment, setSelectedDepartment] = useState<string | undefined>(
    !isAdmin ? myDepartmentId : undefined
  );
  const [rows, setRows] = useState<KpiRow[]>([]);

  const { data: metrics = [], isLoading: metricsLoading } = useKpiMetrics();
  const { mutate: assignKpi, isPending } = useAssignKpiTarget();

  // Load danh sách nhân viên (lọc theo phòng ban nếu là Manager)
  const { data: employeesData, isLoading: employeesLoading } = useQuery({
    queryKey: ["hr", "employees", selectedDepartment],
    queryFn: () => hrService.getEmployees(1, 200, selectedDepartment),
    enabled: canAssign,
  });

  const employees: any[] = employeesData?.data ?? [];

  const employeeOptions = useMemo(
    () => employees.map((e: any) => ({ label: e.full_name, value: e.id })),
    [employees]
  );

  const metricOptions = useMemo(
    () =>
      metrics.map((m: KpiMetric) => {
        const unit = m.unit || getKpiUnit(m.code);
        return {
          label: unit ? `${m.name} (${unit})` : m.name,
          value: m.code,
        };
      }),
    [metrics]
  );

  if (!canAssign) {
    return (
      <Layout style={{ minHeight: "100vh", background: "transparent" }}>
        <Content style={{ padding: 24 }}>
          <Alert
            type="error"
            showIcon
            message="Không có quyền truy cập"
            description="Bạn không có quyền giao chỉ tiêu KPI. Vui lòng liên hệ quản trị viên."
          />
        </Content>
      </Layout>
    );
  }

  const addRow = () => {
    setRows((prev) => [
      ...prev,
      {
        key: `row_${Date.now()}`,
        employee_id: "",
        employee_name: "",
        metric_code: "",
        target_value: null,
      },
    ]);
  };

  const removeRow = (key: string) => {
    setRows((prev) => prev.filter((r) => r.key !== key));
  };

  const updateRow = (key: string, field: keyof KpiRow, value: any) => {
    setRows((prev) =>
      prev.map((r) => {
        if (r.key !== key) return r;
        if (field === "employee_id") {
          const emp = employees.find((e) => e.id === value);
          return { ...r, employee_id: value, employee_name: emp?.full_name ?? "" };
        }
        return { ...r, [field]: value };
      })
    );
  };

  const handleSaveAll = () => {
    const invalid = rows.filter(
      (r) => !r.employee_id || !r.metric_code || r.target_value === null || r.target_value <= 0
    );
    if (invalid.length > 0) {
      import("antd").then(({ message }) =>
        message.warning("Vui lòng điền đầy đủ thông tin cho tất cả các dòng trước khi lưu.")
      );
      return;
    }

    const payloads: KpiTargetPayload[] = rows.map((r) => ({
      employee_id: r.employee_id,
      month: selectedMonth,
      year: selectedYear,
      metric_code: r.metric_code,
      target_value: r.target_value!,
    }));

    // Gọi lần lượt từng payload
    payloads.forEach((p) => assignKpi(p));
  };

  const columns = [
    {
      title: "Nhân viên",
      dataIndex: "employee_id",
      width: "30%",
      render: (_: any, record: KpiRow) => (
        <Select
          showSearch
          placeholder="Chọn nhân viên..."
          style={{ width: "100%" }}
          value={record.employee_id || undefined}
          options={employeeOptions}
          filterOption={(input, option) =>
            (option?.label as string)?.toLowerCase().includes(input.toLowerCase())
          }
          loading={employeesLoading}
          onChange={(val) => updateRow(record.key, "employee_id", val)}
          disabled={!isAdmin && !!myDepartmentId && selectedDepartment !== myDepartmentId}
        />
      ),
    },
    {
      title: (
        <Space>
          Chỉ số KPI
          <Tooltip title="Chọn loại chỉ tiêu cần giao cho nhân viên">
            <InfoCircleOutlined style={{ color: "#aaa" }} />
          </Tooltip>
        </Space>
      ),
      dataIndex: "metric_code",
      width: "35%",
      render: (_: any, record: KpiRow) => (
        <Select
          placeholder="Chọn chỉ số..."
          style={{ width: "100%" }}
          value={record.metric_code || undefined}
          options={metricOptions}
          loading={metricsLoading}
          onChange={(val) => updateRow(record.key, "metric_code", val)}
        />
      ),
    },
    {
      title: "Chỉ tiêu (Target)",
      dataIndex: "target_value",
      width: "25%",
      render: (_: any, record: KpiRow) => {
        const metric = metrics.find((m: KpiMetric) => m.code === record.metric_code);
        return (
          <InputNumber
            style={{ width: "100%" }}
            min={0}
            value={record.target_value ?? undefined}
            formatter={(v) => `${v}`.replace(/\B(?=(\d{3})+(?!\d))/g, ",")}
            parser={(v) => Number(v?.replace(/,/g, "")) as any}
            addonAfter={metric?.unit || getKpiUnit(record.metric_code)}
            onChange={(val) => updateRow(record.key, "target_value", val)}
            placeholder={getKpiUnit(record.metric_code) === "%" ? "VD: 95" : "VD: 100000"}
          />
        );
      },
    },
    {
      title: "",
      key: "action",
      width: 60,
      render: (_: any, record: KpiRow) => (
        <Button
          type="text"
          danger
          icon={<DeleteOutlined />}
          onClick={() => removeRow(record.key)}
        />
      ),
    },
  ];

  return (
    <Layout style={{ minHeight: "100vh", background: "transparent" }}>
      <Content style={{ padding: "24px" }}>
        <Title level={3}>🎯 Giao Chỉ Tiêu KPI</Title>

        <Card style={{ marginBottom: 16 }}>
          <Row gutter={16} align="middle">
            <Col>
              <Text strong>Tháng:</Text>{" "}
              <Select
                value={selectedMonth}
                options={MONTHS}
                onChange={setSelectedMonth}
                style={{ width: 130 }}
              />
            </Col>
            <Col>
              <Text strong>Năm:</Text>{" "}
              <Select
                value={selectedYear}
                options={YEARS}
                onChange={setSelectedYear}
                style={{ width: 100 }}
              />
            </Col>
            <Col>
              <Text strong>Phòng ban:</Text>{" "}
              {isAdmin ? (
                <Select
                  placeholder="Tất cả phòng ban"
                  allowClear
                  value={selectedDepartment}
                  onChange={setSelectedDepartment}
                  style={{ width: 200 }}
                  options={[]} // Backend cần cung cấp API phòng ban
                />
              ) : (
                <Tag color="blue">{myDepartmentId || "Phòng của bạn"}</Tag>
              )}
            </Col>
          </Row>
        </Card>

        <Card
          title={
            <Space>
              <span>Danh sách giao chỉ tiêu</span>
              <Tag color="geekblue">
                Tháng {selectedMonth}/{selectedYear}
              </Tag>
            </Space>
          }
          extra={
            <Space>
              <Button icon={<PlusOutlined />} onClick={addRow}>
                Thêm dòng
              </Button>
              <Button
                type="primary"
                icon={<SaveOutlined />}
                loading={isPending}
                onClick={handleSaveAll}
                disabled={rows.length === 0}
              >
                Lưu Tất Cả
              </Button>
            </Space>
          }
        >
          {rows.length === 0 ? (
            <div style={{ textAlign: "center", padding: "40px 0", color: "#aaa" }}>
              <p>Chưa có dòng nào. Bấm &ldquo;Thêm dòng&rdquo; để bắt đầu giao chỉ tiêu.</p>
            </div>
          ) : (
            <Table
              dataSource={rows}
              columns={columns}
              rowKey="key"
              pagination={false}
              size="middle"
            />
          )}
        </Card>
      </Content>
    </Layout>
  );
};

export default KpiAssignmentPage;
