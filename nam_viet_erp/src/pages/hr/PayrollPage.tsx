import React from "react";
import { Layout, Typography, Card, Result, Button } from "antd";
import { useNavigate } from "react-router-dom";

const { Content } = Layout;
const { Title } = Typography;

const PayrollPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <Layout style={{ minHeight: "100vh", background: "transparent" }}>
      <Content style={{ padding: "24px", maxWidth: 1200, margin: "0 auto", width: "100%" }}>
        <Title level={3}>Tính Bảng Lương</Title>
        <Card>
          <Result
            status="info"
            title="Tính lương theo cá nhân"
            subTitle="Vui lòng vào chi tiết hồ sơ của từng nhân viên để thực hiện tính lương."
            extra={[
              <Button type="primary" key="console" onClick={() => navigate("/hr/employees")}>
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
