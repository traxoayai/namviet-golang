import { useEffect, useState } from "react";
import {
  Card,
  List,
  Typography,
  Button,
  message,
  Modal,
  Spin,
  Row,
  Col,
  Tag,
  Space,
} from "antd";
import { UserOutlined, CheckCircleOutlined } from "@ant-design/icons";

import { financeCodService } from "@/features/finance/api/financeCodService";

const { Title, Text } = Typography;

interface PendingTransaction {
  id: number;
  code: string;
  amount: number;
  ref_type: string;
  ref_id: string;
  status: string;
  created_at: string;
}

interface PendingReport {
  shipper_id: string;
  total_amount: number;
  transactions: PendingTransaction[];
}

const LogisticsCodClearancePage = () => {
  const [reports, setReports] = useState<PendingReport[]>([]);
  const [loading, setLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    fetchReports();
  }, []);

  const fetchReports = async () => {
    setLoading(true);
    try {
      const data = await financeCodService.getPendingCodReports();
      setReports(data || []);
    } catch (error: any) {
      console.error(error);
      message.error("Lỗi tải danh sách chờ đối soát COD");
    } finally {
      setLoading(false);
    }
  };

  const handleConfirm = (report: PendingReport) => {
    Modal.confirm({
      title: "Xác nhận đã thu tiền từ Shipper?",
      content: `Bạn chắc chắn đã nhận đủ ${report.total_amount.toLocaleString(
        "vi-VN"
      )} ₫ từ Shipper này?`,
      okText: "Xác nhận",
      cancelText: "Hủy",
      onOk: async () => {
        setActionLoading(true);
        try {
          const txIds = report.transactions.map((t) => t.id);
          await financeCodService.confirmCodDeposit(report.shipper_id, txIds);
          message.success("Xác nhận thu tiền thành công!");
          fetchReports();
        } catch (error: any) {
          message.error(error.message || "Xác nhận thất bại");
        } finally {
          setActionLoading(false);
        }
      },
    });
  };

  return (
    <div style={{ padding: 24 }}>
      <Title level={2}>Đối Soát Tiền Mặt Giao Vận (COD)</Title>
      <Text type="secondary">
        Danh sách các khoản Thu Hộ (COD) mà Shipper đang giữ và chưa nộp về công ty.
      </Text>

      <Spin spinning={loading}>
        <Row gutter={[24, 24]} style={{ marginTop: 24 }}>
          {reports.map((report) => (
            <Col xs={24} md={12} xl={8} key={report.shipper_id}>
              <Card
                title={
                  <Space>
                    <UserOutlined /> Shipper: {report.shipper_id.substring(0, 8)}...
                  </Space>
                }
                extra={
                  <Tag color="volcano" style={{ fontSize: 14, padding: "4px 8px" }}>
                    Chờ nộp
                  </Tag>
                }
                actions={[
                  <Button
                    type="primary"
                    icon={<CheckCircleOutlined />}
                    loading={actionLoading}
                    onClick={() => handleConfirm(report)}
                    disabled={report.total_amount <= 0}
                  >
                    Xác Nhận Đã Thu Tiền
                  </Button>,
                ]}
              >
                <div style={{ marginBottom: 16 }}>
                  <Text type="secondary">Tổng tiền đang giữ:</Text>
                  <br />
                  <Text strong style={{ fontSize: 24, color: "#f5222d" }}>
                    {report.total_amount.toLocaleString("vi-VN")} ₫
                  </Text>
                </div>
                <List
                  header={<b>Danh sách Đơn / Phiếu Thu ({report.transactions.length})</b>}
                  size="small"
                  dataSource={report.transactions}
                  style={{ maxHeight: 200, overflowY: "auto" }}
                  renderItem={(tx) => (
                    <List.Item>
                      <List.Item.Meta
                        title={tx.code}
                        description={`Mã đơn: ${tx.ref_id}`}
                      />
                      <Text strong>{tx.amount.toLocaleString("vi-VN")} ₫</Text>
                    </List.Item>
                  )}
                />
              </Card>
            </Col>
          ))}
          {reports.length === 0 && !loading && (
            <Col span={24}>
              <Card style={{ textAlign: "center", padding: 40 }}>
                <Text type="secondary">Không có Shipper nào đang giữ tiền COD.</Text>
              </Card>
            </Col>
          )}
        </Row>
      </Spin>
    </div>
  );
};

export default LogisticsCodClearancePage;
