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
import React, { useMemo } from "react";
import { useTrialBalanceLogic } from "@/features/finance/hooks/useTrialBalanceLogic";
import { BookOutlined, BankOutlined } from "@ant-design/icons";

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

const TrialBalancePage: React.FC = () => {
  const {
    loading,
    data,
    bookType,
    setBookType,
    dateRange,
    setDateRange,
  } = useTrialBalanceLogic();

  const summary = useMemo(() => {
    let totalOpDebit = 0;
    let totalOpCredit = 0;
    let totalPerDebit = 0;
    let totalPerCredit = 0;
    let totalClDebit = 0;
    let totalClCredit = 0;

    data.forEach((row) => {
      totalOpDebit += Number(row.opening_debit) || 0;
      totalOpCredit += Number(row.opening_credit) || 0;
      totalPerDebit += Number(row.period_debit) || 0;
      totalPerCredit += Number(row.period_credit) || 0;
      totalClDebit += Number(row.closing_debit) || 0;
      totalClCredit += Number(row.closing_credit) || 0;
    });

    return {
      totalOpDebit,
      totalOpCredit,
      totalPerDebit,
      totalPerCredit,
      totalClDebit,
      totalClCredit,
    };
  }, [data]);

  const columns = [
    {
      title: "Tài khoản",
      children: [
        {
          title: "Mã TK",
          dataIndex: "account_code",
          key: "account_code",
          width: 100,
          render: (val: string) => <Text strong>{val}</Text>,
        },
        {
          title: "Tên tài khoản",
          dataIndex: "account_name",
          key: "account_name",
          width: 250,
          ellipsis: true,
        },
      ],
    },
    {
      title: "Dư đầu kỳ",
      children: [
        {
          title: "Nợ",
          dataIndex: "opening_debit",
          key: "opening_debit",
          width: 130,
          align: "right" as const,
          render: (val: number) => (val ? val.toLocaleString() : ""),
        },
        {
          title: "Có",
          dataIndex: "opening_credit",
          key: "opening_credit",
          width: 130,
          align: "right" as const,
          render: (val: number) => (val ? val.toLocaleString() : ""),
        },
      ],
    },
    {
      title: "Phát sinh trong kỳ",
      children: [
        {
          title: "Nợ",
          dataIndex: "period_debit",
          key: "period_debit",
          width: 130,
          align: "right" as const,
          render: (val: number) => (val ? val.toLocaleString() : ""),
        },
        {
          title: "Có",
          dataIndex: "period_credit",
          key: "period_credit",
          width: 130,
          align: "right" as const,
          render: (val: number) => (val ? val.toLocaleString() : ""),
        },
      ],
    },
    {
      title: "Dư cuối kỳ",
      children: [
        {
          title: "Nợ",
          dataIndex: "closing_debit",
          key: "closing_debit",
          width: 130,
          align: "right" as const,
          render: (val: number) => (val ? val.toLocaleString() : ""),
        },
        {
          title: "Có",
          dataIndex: "closing_credit",
          key: "closing_credit",
          width: 130,
          align: "right" as const,
          render: (val: number) => (val ? val.toLocaleString() : ""),
        },
      ],
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
              Bảng Cân Đối Số Phát Sinh
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
            rowKey="account_id"
            pagination={false}
            scroll={{ x: 1200, y: "calc(100vh - 350px)" }}
            summary={() => {
              if (data.length === 0) return null;
              return (
                <Table.Summary fixed>
                  <Table.Summary.Row style={{ background: "#fafafa" }}>
                    <Table.Summary.Cell index={0} colSpan={2}>
                      <Text strong>Tổng cộng</Text>
                    </Table.Summary.Cell>
                    <Table.Summary.Cell index={1} align="right">
                      <Text strong>{summary.totalOpDebit.toLocaleString()}</Text>
                    </Table.Summary.Cell>
                    <Table.Summary.Cell index={2} align="right">
                      <Text strong>{summary.totalOpCredit.toLocaleString()}</Text>
                    </Table.Summary.Cell>
                    <Table.Summary.Cell index={3} align="right">
                      <Text strong>{summary.totalPerDebit.toLocaleString()}</Text>
                    </Table.Summary.Cell>
                    <Table.Summary.Cell index={4} align="right">
                      <Text strong>{summary.totalPerCredit.toLocaleString()}</Text>
                    </Table.Summary.Cell>
                    <Table.Summary.Cell index={5} align="right">
                      <Text strong>{summary.totalClDebit.toLocaleString()}</Text>
                    </Table.Summary.Cell>
                    <Table.Summary.Cell index={6} align="right">
                      <Text strong>{summary.totalClCredit.toLocaleString()}</Text>
                    </Table.Summary.Cell>
                  </Table.Summary.Row>
                </Table.Summary>
              );
            }}
          />
        </Card>
      </div>
    </Layout>
  );
};

export default TrialBalancePage;
