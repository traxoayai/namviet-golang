import React, { useEffect, useState } from "react";
import { Card, Spin, Typography, Tag, Statistic, Row, Col, DatePicker, Button, Modal, Layout } from "antd";
const { Content } = Layout;
import { Link } from "react-router-dom";
import { 
  Package, 
  ShoppingCart, 
  AlertTriangle, 
  DollarSign, 
  CreditCard, 
  TrendingUp,
  Megaphone,
  ArrowRight
} from "lucide-react";
import { useAuthStore } from "@/features/auth/stores/useAuthStore";
import { dashboardService, WarehouseStats, FinanceStats, Announcement } from "@/features/dashboard/api/dashboardService";
import PullToRefresh from "react-simple-pull-to-refresh";
import { supabase } from "@/shared/lib/supabaseClient";

const { Title, Text, Paragraph } = Typography;

export const DashboardPage: React.FC = () => {
  const { profile, permissions } = useAuthStore();
  const [loading, setLoading] = useState(true);
  
  const [announcements, setAnnouncements] = useState<Announcement[]>([]);
  const [warehouseStats, setWarehouseStats] = useState<WarehouseStats | null>(null);
  const [financeStats, setFinanceStats] = useState<FinanceStats | null>(null);
  const [financeLoading, setFinanceLoading] = useState(false);
  const [financeMonth, setFinanceMonth] = useState<string | undefined>(undefined);

  const hasWarehousePerm = permissions.some(p => p.startsWith("inv-")) || permissions.includes("admin-all");
  const hasFinancePerm = permissions.includes("finance.view") || permissions.includes("admin-all");

  useEffect(() => {
    // fetchData sẽ được gọi qua useEffect bên dưới
  }, []);

  const fetchData = async () => {
    // Chỉ set loading toàn trang lần đầu tiên
    if (!warehouseStats && !financeStats) {
      setLoading(true);
    }
      try {
        // Fetch announcements first (for everyone)
        try {
          const ann = await dashboardService.getAnnouncements();
          setAnnouncements(ann || []);
        } catch (e) {
          console.error("Lỗi lấy thông báo:", e);
        }

        // Fetch based on permissions
        const promises = [];
        if (hasWarehousePerm) {
          promises.push(
            dashboardService.getWarehouseStats()
              .then(res => setWarehouseStats(res))
              .catch(e => console.error("Lỗi lấy thông số kho", e))
          );
        }
        if (hasFinancePerm) {
          setFinanceLoading(true);
          promises.push(
            dashboardService.getFinanceStats(financeMonth)
              .then(res => setFinanceStats(res))
              .catch(e => console.error("Lỗi lấy thông số tài chính", e))
              .finally(() => setFinanceLoading(false))
          );
        }

        await Promise.all(promises);
      } finally {
        setLoading(false);
      }
  };

  useEffect(() => {
    fetchData();
  }, [hasWarehousePerm, hasFinancePerm, financeMonth]);

  // [NEW] True Realtime với Supabase WebSockets
  useEffect(() => {
    const channel = supabase
      .channel("dashboard_changes")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "finance_transactions" },
        () => {
          console.log("[Realtime] Có thay đổi giao dịch tài chính, tải lại Dashboard...");
          if (hasFinancePerm) fetchData();
        }
      )
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "orders" },
        () => {
          console.log("[Realtime] Có thay đổi đơn hàng, tải lại Dashboard...");
          if (hasWarehousePerm || hasFinancePerm) fetchData();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [hasWarehousePerm, hasFinancePerm]);

  // Greetings logic
  const hour = new Date().getHours();
  let greeting = "Chào buổi sáng";
  if (hour >= 11 && hour <= 13) greeting = "Chào buổi trưa";
  else if (hour >= 14 && hour <= 17) greeting = "Chào buổi chiều";
  else if (hour >= 18 && hour <= 22) greeting = "Chào buổi tối";
  else if (hour >= 23 || hour < 5) greeting = "Chào buổi đêm";

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full min-h-[50vh]">
        <Spin size="large" />
      </div>
    );
  }

  return (
    <Layout style={{ minHeight: "100vh", background: "#f2f7fc", overflowX: "hidden" }}>
      <Content style={{ padding: 12, overflowX: "hidden" }}>
        <PullToRefresh onRefresh={fetchData}>
          <div className="max-w-7xl mx-auto space-y-6 pb-6">
        {/* Header Greeting */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-400 rounded-2xl p-6 md:p-8 text-white shadow-sm">
        <Title level={2} style={{ color: 'white', margin: 0 }}>{greeting}, {profile?.full_name || 'Bạn'}! 👋</Title>
        <Text className="text-blue-50 text-base opacity-90 mt-2 block">
          Chúc bạn một ngày làm việc hiệu quả và tràn đầy năng lượng.
        </Text>
      </div>

      <Row gutter={[24, 24]}>
        {/* Cột trái: Thông báo công ty */}
        <Col xs={24} lg={8}>
          <Card 
            title={<><Megaphone size={18} className="mr-2 inline" /> Bảng tin Nội bộ</>} 
            className="h-full shadow-sm rounded-xl overflow-hidden"
            headStyle={{ borderBottom: '1px solid #f0f0f0', backgroundColor: '#fafafa' }}
            bodyStyle={{ padding: '16px' }}
          >
            {announcements.length === 0 ? (
              <div className="text-center text-gray-400 py-8">
                <Megaphone size={32} className="mx-auto mb-2 opacity-20" />
                <p>Chưa có thông báo mới</p>
              </div>
            ) : (
              <div className="space-y-4">
                {announcements.map(ann => (
                  <div key={ann.id} className="border-b border-gray-100 last:border-0 pb-3 last:pb-0">
                    <div className="flex justify-between items-start mb-1">
                      <Text strong className="text-gray-800 line-clamp-2">{ann.title}</Text>
                      {ann.is_urgent && <Tag color="red">Gấp</Tag>}
                    </div>
                    <Paragraph className="text-gray-500 text-sm mb-1 line-clamp-3">
                      {ann.content}
                    </Paragraph>
                    <div className="flex justify-between items-center mt-2">
                      <Text className="text-xs text-gray-400">
                        {new Date(ann.created_at).toLocaleDateString('vi-VN')}
                      </Text>
                      <Button 
                        size="small" 
                        type="link" 
                        className="p-0"
                        onClick={() => {
                          Modal.info({
                            title: ann.title,
                            content: (
                              <div className="mt-4">
                                <p>{ann.content}</p>
                                <p className="text-gray-400 mt-2 text-xs">Đăng lúc: {new Date(ann.created_at).toLocaleString('vi-VN')}</p>
                              </div>
                            ),
                          });
                        }}
                      >
                        Xem chi tiết <ArrowRight size={14} className="ml-1 inline" />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Card>
        </Col>

        {/* Cột phải: Các widget dựa trên Role */}
        <Col xs={24} lg={16}>
          <div className="space-y-6">
            {/* WAREHOUSE WIDGET */}
            {hasWarehousePerm && warehouseStats && (
              <Card 
                title={<><Package size={18} className="mr-2 inline" /> Tổng quan Kho vận</>}
                className="shadow-sm rounded-xl"
                headStyle={{ borderBottom: '1px solid #f0f0f0', backgroundColor: '#fafafa' }}
              >
                <Row gutter={[16, 16]}>
                  <Col xs={12} sm={6}>
                    <Link to="/inventory/inbound">
                      <Card size="small" className="bg-orange-50 border-orange-100 hover:shadow-md transition-shadow cursor-pointer">
                        <Statistic
                          title={<span className="text-orange-600 font-medium">Chờ Nhập kho</span>}
                          value={warehouseStats.pending_receive_count}
                          prefix={<ShoppingCart size={16} />}
                          valueStyle={{ color: '#d97706' }}
                        />
                      </Card>
                    </Link>
                  </Col>
                  <Col xs={12} sm={6}>
                    <Link to="/inventory/outbound">
                      <Card size="small" className="bg-blue-50 border-blue-100 hover:shadow-md transition-shadow cursor-pointer">
                        <Statistic
                          title={<span className="text-blue-600 font-medium">Chờ Xuất kho</span>}
                          value={warehouseStats.pending_pack_count}
                          prefix={<Package size={16} />}
                          valueStyle={{ color: '#2563eb' }}
                        />
                      </Card>
                    </Link>
                  </Col>
                  <Col xs={12} sm={6}>
                    <Link to="/purchasing/master?status=draft">
                      <Card size="small" className="bg-purple-50 border-purple-100 hover:shadow-md transition-shadow cursor-pointer">
                        <Statistic
                          title={<span className="text-purple-600 font-medium">Cần Đặt hàng</span>}
                          value={warehouseStats.draft_po_count || 0}
                          prefix={<ShoppingCart size={16} />}
                          valueStyle={{ color: '#9333ea' }}
                        />
                      </Card>
                    </Link>
                  </Col>
                  <Col xs={12} sm={6}>
                    <Link to="/inventory/stock?low_stock=true">
                      <Card size="small" className="bg-red-50 border-red-100 hover:shadow-md transition-shadow cursor-pointer">
                        <Statistic
                          title={<span className="text-red-600 font-medium">Sắp hết hàng</span>}
                          value={warehouseStats.low_stock_items}
                          prefix={<AlertTriangle size={16} />}
                          valueStyle={{ color: '#dc2626' }}
                        />
                      </Card>
                    </Link>
                  </Col>
                </Row>
              </Card>
            )}

            {/* FINANCE WIDGET */}
            {hasFinancePerm && financeStats && (
              <Card 
                title={
                  <div className="flex justify-between items-center w-full">
                    <span><DollarSign size={18} className="mr-2 inline" /> Tổng quan Tài chính</span>
                    <DatePicker 
                      picker="month" 
                      placeholder="Chọn tháng" 
                      size="small"
                      onChange={(_date, dateString) => setFinanceMonth(dateString as string)}
                    />
                  </div>
                }
                className="shadow-sm rounded-xl"
                headStyle={{ borderBottom: '1px solid #f0f0f0', backgroundColor: '#fafafa' }}
              >
                <Spin spinning={financeLoading}>
                <Row gutter={[16, 16]}>
                  <Col xs={24} sm={12}>
                    <Link to="/finance/reports?type=revenue">
                      <Card size="small" className="bg-green-50 border-green-100 hover:shadow-md transition-shadow cursor-pointer">
                        <Statistic
                          title={<span className="text-green-600 font-medium">Doanh thu tháng này</span>}
                          value={financeStats.total_revenue_month}
                          prefix={<TrendingUp size={16} />}
                          suffix="₫"
                          groupSeparator="."
                          valueStyle={{ color: '#16a34a' }}
                        />
                      </Card>
                    </Link>
                  </Col>
                  <Col xs={12} sm={12}>
                    <Link to="/finance/reports?type=receivable">
                      <Card size="small" className="bg-indigo-50 border-indigo-100 hover:shadow-md transition-shadow cursor-pointer">
                        <Statistic
                          title={<span className="text-indigo-600 font-medium">Công nợ Phải thu</span>}
                          value={financeStats.total_debt_receivable}
                          prefix={<CreditCard size={16} />}
                          suffix="₫"
                          groupSeparator="."
                          valueStyle={{ color: '#4f46e5' }}
                        />
                      </Card>
                    </Link>
                  </Col>
                  <Col xs={12} sm={12}>
                    <Link to="/finance/reports?type=payable">
                      <Card size="small" className="bg-red-50 border-red-100 hover:shadow-md transition-shadow cursor-pointer">
                        <Statistic
                          title={<span className="text-red-600 font-medium">Công nợ Phải trả</span>}
                          value={financeStats.total_debt_payable}
                          prefix={<AlertTriangle size={16} />}
                          suffix="₫"
                          groupSeparator="."
                          valueStyle={{ color: '#dc2626' }}
                        />
                      </Card>
                    </Link>
                  </Col>
                  <Col xs={12} sm={12}>
                    <Link to="/sales/b2b-orders?payment_status=pending">
                      <Card size="small" className="bg-yellow-50 border-yellow-100 hover:shadow-md transition-shadow cursor-pointer">
                        <Statistic
                          title={<span className="text-yellow-600 font-medium">Đơn chưa thu COD</span>}
                          value={financeStats.pending_cod_orders}
                          prefix={<Package size={16} />}
                          valueStyle={{ color: '#ca8a04' }}
                        />
                      </Card>
                    </Link>
                  </Col>
                </Row>
                </Spin>
              </Card>
            )}

            {/* DEFAULT FALLBACK (Nếu user không có quyền gì) */}
            {!hasWarehousePerm && !hasFinancePerm && (
              <Card className="text-center py-12 shadow-sm rounded-xl bg-white border-dashed border-2 border-gray-200">
                <AlertTriangle size={48} className="mx-auto text-gray-300 mb-4" />
                <Title level={4} className="text-gray-500">Chưa có Widget phân tích nào</Title>
                <Text className="text-gray-400">Tài khoản của bạn chưa được cấp quyền xem dữ liệu chuyên sâu.</Text>
              </Card>
            )}
          </div>
        </Col>
      </Row>
      </div>
        </PullToRefresh>
      </Content>
    </Layout>
  );
};
