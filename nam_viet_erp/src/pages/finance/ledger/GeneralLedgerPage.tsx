import {
  Card,
  Col,
  DatePicker,
  Layout,
  Row,
  Select,
  Space,
  Table,
  Typography,
  Switch,
  Tag,
} from "antd";
import dayjs from "dayjs";
import React, { useMemo } from "react";
import { useGeneralLedgerLogic } from "@/features/finance/hooks/useGeneralLedgerLogic";
import { BookOutlined, BankOutlined } from "@ant-design/icons";

const { Title, Text } = Typography;
const { RangePicker } = DatePicker;

const GeneralLedgerPage: React.FC = () => {
  const {
    loading,
    data,
    accounts,
    selectedAccount,
    setSelectedAccount,
    bookType,
    setBookType,
    dateRange,
    setDateRange,
  } = useGeneralLedgerLogic();

  // Summary logic
  const summary = useMemo(() => {
    let totalDebit = 0;
    let totalCredit = 0;
    
    data.forEach((row) => {
      if (!row.is_opening_balance) {
        totalDebit += Number(row.debit) || 0;
        totalCredit += Number(row.credit) || 0;
      }
    });

    return { totalDebit, totalCredit };
  }, [data]);

  const columns = [
    {
      title: "Ngày HT",
      dataIndex: "transaction_date",
      key: "transaction_date",
      width: 120,
      render: (val: string, record: any) =>
        record.is_opening_balance ? "" : dayjs(val).format("DD/MM/YYYY"),
    },
    {
      title: "Số CT",
      dataIndex: "doc_id",
      key: "doc_id",
      width: 150,
      render: (val: string, record: any) =>
        record.is_opening_balance ? "" : <Text strong>{val}</Text>,
    },
    {
      title: "Diễn giải",
      dataIndex: "description",
      key: "description",
      render: (val: string, record: any) =>
        record.is_opening_balance ? <Text strong style={{ color: '#1890ff' }}>{val}</Text> : val,
    },
    {
      title: "TK Đối Ứng",
      dataIndex: "cor_account_code",
      key: "cor_account_code",
      width: 150,
      render: (val: string) => (val ? <Tag color="blue">{val}</Tag> : ""),
    },
    {
      title: "Phát Sinh Nợ",
      dataIndex: "debit",
      key: "debit",
      width: 150,
      align: "right" as const,
      render: (val: number, record: any) =>
        record.is_opening_balance || !val ? "" : val.toLocaleString(),
    },
    {
      title: "Phát Sinh Có",
      dataIndex: "credit",
      key: "credit",
      width: 150,
      align: "right" as const,
      render: (val: number, record: any) =>
        record.is_opening_balance || !val ? "" : val.toLocaleString(),
    },
    {
      title: "Số Dư",
      dataIndex: "running_balance",
      key: "running_balance",
      width: 150,
      align: "right" as const,
      render: (val: number, record: any) => (
        <Text strong={record.is_opening_balance} style={{ color: val < 0 ? '#cf1322' : 'inherit' }}>
          {val ? val.toLocaleString() : "0"}
        </Text>
      ),
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
              Sổ Cái Kế Toán
            </Title>
          </Col>
          <Col>
            <Space size="large">
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
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

      <div style={{ padding: 24, background: "#f0f2f5" }}>
        <Card style={{ marginBottom: 16 }}>
          <Row gutter={16}>
            <Col span={8}>
              <Text strong style={{ display: "block", marginBottom: 8 }}>
                Tài khoản:
              </Text>
              <Select
                showSearch
                placeholder="Chọn tài khoản kế toán"
                style={{ width: "100%" }}
                value={selectedAccount}
                onChange={setSelectedAccount}
                filterOption={(input, option) =>
                  (option?.label ?? "").toLowerCase().includes(input.toLowerCase())
                }
                options={accounts.map((acc) => ({
                  value: acc.id,
                  label: `${acc.account_code} - ${acc.name}`,
                }))}
              />
            </Col>
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
            columns={columns}
            dataSource={data}
            loading={loading}
            rowKey={(record, index) => `${record.doc_id}_${index}`}
            pagination={false}
            scroll={{ x: 1000, y: "calc(100vh - 350px)" }}
            summary={() => {
              if (!selectedAccount || data.length === 0) return null;
              return (
                <Table.Summary fixed>
                  <Table.Summary.Row style={{ background: "#fafafa" }}>
                    <Table.Summary.Cell index={0} colSpan={4}>
                      <Text strong>Cộng phát sinh trong kỳ</Text>
                    </Table.Summary.Cell>
                    <Table.Summary.Cell index={1} align="right">
                      <Text strong>{summary.totalDebit.toLocaleString()}</Text>
                    </Table.Summary.Cell>
                    <Table.Summary.Cell index={2} align="right">
                      <Text strong>{summary.totalCredit.toLocaleString()}</Text>
                    </Table.Summary.Cell>
                    <Table.Summary.Cell index={3} align="right">
                       {/* Empty balance cell for "Cộng phát sinh" */}
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

export default GeneralLedgerPage;
