import React, { useState } from "react";
import { useParams } from "react-router-dom";
import { Layout, Typography, Card, Descriptions, Table, Tabs, Button, Space } from "antd";
import { useEmployeeDetail } from "@/features/hr/hooks/useEmployees";
import { useCalculatePayroll } from "@/features/hr/hooks/usePayroll";
import { useAuthStore } from "@/features/auth/stores/useAuthStore";
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

  const userProfile = profile as any;
  const canCalculatePayroll = userProfile?.role === "Admin" || userProfile?.role === "HR_Manager";

  const handleCalculatePayroll = () => {
    if (!id) return;
    calculatePayroll({ id, month, year });
  };

  const contractColumns = [
    { title: "Loại hợp đồng", dataIndex: "contract_type" },
    { title: "Lương cơ bản", dataIndex: "base_salary", render: (val: number) => val?.toLocaleString() + " đ" },
    { title: "Ngày bắt đầu", dataIndex: "start_date" },
    { title: "Trạng thái", dataIndex: "status" },
  ];

  const payrollColumns = [
    { title: "Tháng", render: (_: any, r: any) => `${r.month}/${r.year}` },
    { title: "Lương cơ bản", dataIndex: "base_salary", render: (val: number) => val?.toLocaleString() + " đ" },
    { title: "Hoa hồng", dataIndex: "commission", render: (val: number) => val?.toLocaleString() + " đ" },
    { title: "Thưởng KPI", dataIndex: "kpi_bonus", render: (val: number) => val?.toLocaleString() + " đ" },
    { title: "Tổng thực nhận", dataIndex: "total_salary", render: (val: number) => <Text strong>{val?.toLocaleString()} đ</Text> },
    { title: "Trạng thái", dataIndex: "status" },
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
        </Tabs>
      </Content>
    </Layout>
  );
};

export default EmployeeDetailPage;
