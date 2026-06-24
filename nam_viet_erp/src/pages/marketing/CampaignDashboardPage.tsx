import React, { useState } from "react";
import { Layout, Typography, Card, Table, Button, Space, Modal, Tag } from "antd";
import { PlayCircleOutlined, PlusOutlined, BarChartOutlined } from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import { useStartCampaign, useCampaignMetrics } from "@/features/marketing/hooks/useMarketing";
// Import ReactECharts or use simple stats for the dashboard if ECharts isn't installed.
// Assuming we display basic stats or Echarts if available. Let's use basic stats for simplicity if ECharts is missing.

const { Content } = Layout;
const { Title, Text } = Typography;

// Mock data cho danh sách (Thực tế sẽ gọi API danh sách campaigns)
const MOCK_CAMPAIGNS = [
  { id: 1, name: "Chiến dịch Sinh Nhật Tháng 6", budget: 5000000, status: "draft" },
  { id: 2, name: "Khuyến mãi Hè Sôi Động", budget: 20000000, status: "running" },
];

const MetricsModal: React.FC<{ visible: boolean; campaignId?: number; onClose: () => void }> = ({ visible, campaignId, onClose }) => {
  const { data: metrics, isLoading } = useCampaignMetrics(campaignId);

  return (
    <Modal title="Hiệu quả Chiến dịch (Funnel Metrics)" visible={visible} onCancel={onClose} footer={null}>
      {isLoading ? <Text>Đang tải dữ liệu...</Text> : (
        <div>
          <Card size="small" style={{ marginBottom: 8 }}>
            <Text>Tin đã gửi (Sent): </Text> <Text strong>{metrics?.sent_count || 0}</Text>
          </Card>
          <Card size="small" style={{ marginBottom: 8 }}>
            <Text>Tin đã mở (Open): </Text> <Text strong>{metrics?.open_count || 0}</Text>
          </Card>
          <Card size="small" style={{ marginBottom: 8 }}>
            <Text>Click Link (Clicked): </Text> <Text strong>{metrics?.clicked_count || 0}</Text>
          </Card>
          <Card size="small" style={{ marginBottom: 8 }}>
            <Text>Đã đổi mã (Redeemed): </Text> <Text strong>{metrics?.redeemed_count || 0}</Text>
          </Card>
        </div>
      )}
    </Modal>
  );
};

const CampaignDashboardPage: React.FC = () => {
  const navigate = useNavigate();
  const { mutate: startCampaign } = useStartCampaign();
  
  const [metricsModalOpen, setMetricsModalOpen] = useState(false);
  const [selectedCampaignId, setSelectedCampaignId] = useState<number>();

  const handleStart = (id: number) => {
    startCampaign(id);
  };

  const handleViewMetrics = (id: number) => {
    setSelectedCampaignId(id);
    setMetricsModalOpen(true);
  };

  const columns = [
    { title: "ID", dataIndex: "id" },
    { title: "Tên chiến dịch", dataIndex: "name" },
    { title: "Ngân sách", dataIndex: "budget", render: (val: number) => val.toLocaleString() + " đ" },
    { 
      title: "Trạng thái", 
      dataIndex: "status", 
      render: (val: string) => (
        <Tag color={val === "running" ? "green" : "default"}>
          {val.toUpperCase()}
        </Tag>
      )
    },
    {
      title: "Hành động",
      key: "action",
      render: (_: any, record: any) => (
        <Space size="middle">
          {record.status === "draft" && (
            <Button type="primary" icon={<PlayCircleOutlined />} onClick={() => handleStart(record.id)}>
              Bắt đầu
            </Button>
          )}
          <Button icon={<BarChartOutlined />} onClick={() => handleViewMetrics(record.id)}>
            Thống kê
          </Button>
        </Space>
      ),
    },
  ];

  return (
    <Layout style={{ minHeight: "100vh", background: "transparent" }}>
      <Content style={{ padding: "24px", maxWidth: 1200, margin: "0 auto", width: "100%" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
          <Title level={3} style={{ margin: 0 }}>Quản lý Chiến dịch (Marketing Automation)</Title>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => navigate("/marketing/campaigns/new")}>
            Tạo Chiến Dịch
          </Button>
        </div>
        <Card>
          <Table
            dataSource={MOCK_CAMPAIGNS}
            columns={columns}
            rowKey="id"
          />
        </Card>

        <MetricsModal 
          visible={metricsModalOpen} 
          campaignId={selectedCampaignId} 
          onClose={() => setMetricsModalOpen(false)} 
        />
      </Content>
    </Layout>
  );
};

export default CampaignDashboardPage;
