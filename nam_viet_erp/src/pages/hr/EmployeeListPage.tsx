import React, { useState } from "react";
import { Table, Layout, Typography, Card, Space, Button } from "antd";
import { EyeOutlined } from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import { useEmployees } from "@/features/hr/hooks/useEmployees";

const { Content } = Layout;
const { Title } = Typography;

const EmployeeListPage: React.FC = () => {
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const navigate = useNavigate();

  const { data, isLoading } = useEmployees(page, pageSize);
  const responseData = data as any;

  const columns = [
    {
      title: "Mã NV",
      dataIndex: "employee_code",
      key: "employee_code",
    },
    {
      title: "Họ và Tên",
      dataIndex: "full_name",
      key: "full_name",
    },
    {
      title: "Email",
      dataIndex: "email",
      key: "email",
    },
    {
      title: "Vị trí",
      dataIndex: "position",
      key: "position",
    },
    {
      title: "Hành động",
      key: "action",
      render: (_: any, record: any) => (
        <Space size="middle">
          <Button
            type="text"
            icon={<EyeOutlined />}
            onClick={() => navigate(`/hr/employees/${record.id}`)}
          >
            Chi tiết
          </Button>
        </Space>
      ),
    },
  ];

  return (
    <Layout style={{ minHeight: "100vh", background: "transparent" }}>
      <Content style={{ padding: "24px", maxWidth: 1200, margin: "0 auto", width: "100%" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
          <Title level={3} style={{ margin: 0 }}>Danh sách Nhân sự</Title>
        </div>
        <Card>
          <Table
            dataSource={responseData?.data || []}
            columns={columns}
            rowKey="id"
            loading={isLoading}
            pagination={{
              current: page,
              pageSize: pageSize,
              total: responseData?.total || 0,
              onChange: (p, ps) => {
                setPage(p);
                setPageSize(ps);
              },
            }}
          />
        </Card>
      </Content>
    </Layout>
  );
};

export default EmployeeListPage;
