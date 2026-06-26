import React, { useState } from "react";
import {
  Layout,
  Typography,
  Card,
  Result,
  Button,
  Progress,
  Space,
  Row,
  Col,
  Select,
  Tag,
  Spin,
  Alert,
  Statistic,
} from "antd";
import {
  TrophyOutlined,
  FireOutlined,
  RocketOutlined,
  WarningOutlined,
} from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import dayjs from "dayjs";
import { useMyKpiProgress } from "@/features/hr/hooks/useKpi";
import type { KpiProgressItem } from "@/features/hr/types/hrTypes";

const { Content } = Layout;
const { Title, Text } = Typography;

const MONTHS = Array.from({ length: 12 }, (_, i) => ({ label: `Tháng ${i + 1}`, value: i + 1 }));
const YEARS = [2024, 2025, 2026, 2027].map((y) => ({ label: `${y}`, value: y }));

/** Xác định màu sắc và trạng thái thanh tiến độ theo % */
const getProgressProps = (percent: number) => {
  if (percent >= 80) {
    return {
      strokeColor: "#52c41a",
      status: "success" as const,
      icon: <TrophyOutlined style={{ color: "#52c41a" }} />,
    };
  }
  if (percent >= 50) {
    return {
      strokeColor: "#fa8c16",
      status: "normal" as const,
      icon: <FireOutlined style={{ color: "#fa8c16" }} />,
    };
  }
  return {
    strokeColor: "#ff4d4f",
    status: "exception" as const,
    icon: <WarningOutlined style={{ color: "#ff4d4f" }} />,
  };
};

/** Tạo text động lực dựa trên chỉ số */
const getMotivationText = (item: KpiProgressItem): string => {
  const remaining = item.target_value - item.actual_value;
  const isVnd = item.unit === "VNĐ";
  const formatValue = (v: number) =>
    isVnd
      ? v >= 1_000_000_000
        ? `${(v / 1_000_000_000).toFixed(1)} Tỷ`
        : `${(v / 1_000_000).toFixed(0)} Triệu`
      : `${v.toLocaleString()} ${item.unit}`;

  if (item.percent >= 100) {
    return `🎉 Xuất sắc! Bạn đã đạt ${formatValue(item.actual_value)} — vượt chỉ tiêu rồi!`;
  }
  if (remaining <= 0) return "";
  return `${item.metric_name} của bạn đang đạt ${formatValue(item.actual_value)} / ${formatValue(item.target_value)}. Cố lên ${formatValue(remaining)} nữa để đạt KPI nhé! 💪`;
};

const KpiProgressWidget: React.FC<{ month: number; year: number }> = ({ month, year }) => {
  const { data, isLoading, isError } = useMyKpiProgress(month, year);

  if (isLoading) {
    return (
      <div style={{ textAlign: "center", padding: 24 }}>
        <Spin tip="Đang tải tiến độ KPI..." />
      </div>
    );
  }

  if (isError || !data) {
    return (
      <Alert
        type="warning"
        showIcon
        message="Không thể tải tiến độ KPI"
        description="Dữ liệu KPI tháng này chưa được cập nhật hoặc bạn chưa được giao chỉ tiêu."
      />
    );
  }

  if (!data.items || data.items.length === 0) {
    return (
      <Alert
        type="info"
        showIcon
        message="Chưa có chỉ tiêu KPI"
        description="Bạn chưa được giao chỉ tiêu KPI cho tháng này. Vui lòng liên hệ quản lý."
      />
    );
  }

  return (
    <Space direction="vertical" style={{ width: "100%" }} size={16}>
      {data.items.map((item: KpiProgressItem) => {
        const { strokeColor, status, icon } = getProgressProps(item.percent);
        const motivationText = getMotivationText(item);
        return (
          <Card
            key={item.metric_code}
            size="small"
            style={{
              borderLeft: `4px solid ${strokeColor}`,
              borderRadius: 8,
            }}
          >
            <Row gutter={16} align="middle">
              <Col flex="auto">
                <Space>
                  {icon}
                  <Text strong>{item.metric_name}</Text>
                  <Tag color={status === "success" ? "green" : status === "exception" ? "red" : "orange"}>
                    {item.percent.toFixed(1)}%
                  </Tag>
                </Space>
                <Progress
                  percent={Math.min(item.percent, 100)}
                  strokeColor={strokeColor}
                  status={status}
                  style={{ marginTop: 8, marginBottom: 4 }}
                />
                {motivationText && (
                  <Text type="secondary" style={{ fontSize: 12 }}>
                    {motivationText}
                  </Text>
                )}
              </Col>
              <Col>
                <Row gutter={24} justify="end">
                  <Col>
                    <Statistic
                      title="Thực tế"
                      value={item.actual_value}
                      suffix={item.unit}
                      valueStyle={{ fontSize: 14, color: strokeColor }}
                    />
                  </Col>
                  <Col>
                    <Statistic
                      title="Chỉ tiêu"
                      value={item.target_value}
                      suffix={item.unit}
                      valueStyle={{ fontSize: 14 }}
                    />
                  </Col>
                </Row>
              </Col>
            </Row>
          </Card>
        );
      })}
    </Space>
  );
};

const PayrollPage: React.FC = () => {
  const navigate = useNavigate();
  const currentMonth = dayjs().month() + 1;
  const currentYear = dayjs().year();
  const [month, setMonth] = useState(currentMonth);
  const [year, setYear] = useState(currentYear);

  return (
    <Layout style={{ minHeight: "100vh", background: "transparent" }}>
      <Content style={{ padding: "24px", maxWidth: 1200, margin: "0 auto", width: "100%" }}>
        <Title level={3}>Bảng Lương & Tiến Độ KPI</Title>

        {/* Widget Tiến Độ KPI cá nhân */}
        <Card
          title={
            <Space>
              <RocketOutlined style={{ color: "#722ed1" }} />
              <span>Tiến độ KPI của tôi</span>
            </Space>
          }
          extra={
            <Space>
              <Select
                value={month}
                options={MONTHS}
                onChange={setMonth}
                style={{ width: 120 }}
                size="small"
              />
              <Select
                value={year}
                options={YEARS}
                onChange={setYear}
                style={{ width: 90 }}
                size="small"
              />
            </Space>
          }
          style={{ marginBottom: 24, borderTop: "3px solid #722ed1" }}
        >
          <KpiProgressWidget month={month} year={year} />
        </Card>

        {/* Chuyển đến trang tính lương cá nhân */}
        <Card>
          <Result
            status="info"
            title="Tính lương theo cá nhân"
            subTitle="Vui lòng vào chi tiết hồ sơ của từng nhân viên để thực hiện tính lương và xem phiếu lương chi tiết."
            extra={[
              <Button type="primary" key="employees" onClick={() => navigate("/hr/employees")}>
                Đến danh sách nhân viên
              </Button>,
            ]}
          />
        </Card>
      </Content>
    </Layout>
  );
};

export default PayrollPage;
