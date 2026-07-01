import {
  Card,
  Col,
  DatePicker,
  Layout,
  Row,
  Space,
  Table,
  Typography,
  Switch,
} from "antd";
import React from "react";
import { useProfitAndLossLogic } from "@/features/finance/hooks/useProfitAndLossLogic";
import { BookOutlined, BankOutlined } from "@ant-design/icons";

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

const ProfitAndLossPage: React.FC = () => {
  const {
    loading,
    data,
    bookType,
    setBookType,
    dateRange,
    setDateRange,
  } = useProfitAndLossLogic();

  // Highlight specific items
  const getRowClassName = (record: any) => {
    const boldItems = ["10", "20", "30", "40", "50", "60"];
    if (boldItems.includes(record.item_code)) {
      return "font-bold bg-gray-50";
    }
    return "";
  };

  const columns = [
    {
      title: "Chỉ tiêu",
      dataIndex: "item_name",
      key: "item_name",
      render: (val: string, record: any) => {
        const boldItems = ["10", "20", "30", "40", "50", "60"];
        const isBold = boldItems.includes(record.item_code);
        return <Text strong={isBold}>{val}</Text>;
      },
    },
    {
      title: "Mã số",
      dataIndex: "item_code",
      key: "item_code",
      width: 100,
      align: "center" as const,
    },
    {
      title: "Kỳ báo cáo",
      dataIndex: "current_period_amount",
      key: "current_period_amount",
      width: 200,
      align: "right" as const,
      render: (val: number, record: any) => {
        const boldItems = ["10", "20", "30", "40", "50", "60"];
        const isBold = boldItems.includes(record.item_code);
        return <Text strong={isBold}>{val ? val.toLocaleString() : "0"}</Text>;
      },
    },
    {
      title: "Kỳ trước",
      dataIndex: "previous_period_amount",
      key: "previous_period_amount",
      width: 200,
      align: "right" as const,
      render: (val: number) => (val ? val.toLocaleString() : "0"),
    },
  ];

  return (
    <Layout style={{ minHeight: "100vh" }}>
      <div
        style={{
          padding: "16px 24px",
          background: "#fff",
          borderBottom: "1px solid #f0f0f0",
        }}
      >
        <Row justify="space-between" align="middle">
          <Col>
            <Title level={4} style={{ margin: 0 }}>
              Báo Cáo Kết Quả Hoạt Động Kinh Doanh
            </Title>
          </Col>
          <Col>
            <Space size="large">
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <Text strong>Loại sổ:</Text>
                <Switch
                  checkedChildren={<><BankOutlined /> Sổ Thuế</>}
                  unCheckedChildren={<><BookOutlined /> Sổ Nội Bộ</>}
                  checked={bookType === "TAX"}
                  onChange={(checked) => setBookType(checked ? "TAX" : "INTERNAL")}
                  style={{ background: bookType === "TAX" ? "#fa8c16" : "#1890ff" }}
                />
              </div>
            </Space>
          </Col>
        </Row>
      </div>

      <div style={{ padding: 24, background: "#f2f7fc" }}>
        <Card style={{ marginBottom: 16 }}>
          <Row gutter={16}>
            <Col span={8}>
              <Text strong style={{ display: "block", marginBottom: 8 }}>
                Kỳ báo cáo:
              </Text>
              <RangePicker
                style={{ width: "100%" }}
                value={dateRange}
                onChange={(dates) => {
                  if (dates && dates[0] && dates[1]) {
                    setDateRange([dates[0], dates[1]]);
                  }
                }}
                format="DD/MM/YYYY"
              />
            </Col>
          </Row>
        </Card>

        <Card bodyStyle={{ padding: 0 }}>
          <Table
            bordered
            columns={columns}
            dataSource={data}
            loading={loading}
            rowKey="item_code"
            pagination={false}
            rowClassName={getRowClassName}
          />
        </Card>
      </div>
    </Layout>
  );
};

export default ProfitAndLossPage;
