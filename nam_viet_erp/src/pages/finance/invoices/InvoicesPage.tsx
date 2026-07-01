// src/pages/finance/invoices/InvoicesPage.tsx
import {
  CloudUploadOutlined,
  SearchOutlined,
  FilePdfOutlined,
  CheckCircleOutlined,
  SyncOutlined,
  DeleteOutlined,
  EyeOutlined,
  ScanOutlined,
  DollarCircleOutlined,
  DownloadOutlined,
  FileTextOutlined,
  MinusCircleOutlined,
  CloudSyncOutlined,
} from "@ant-design/icons";
import {
  Layout,
  Card,
  Table,
  Button,
  Tag,
  Typography,
  Space,
  Input,
  DatePicker,
  Select,
  Row,
  Col,
  Statistic,
  App,
  Alert,
  Tooltip,
  Popconfirm,
} from "antd";
import dayjs from "dayjs";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import * as XLSX from "xlsx";
import { parseGdtJsonInvoice } from "@/features/finance/utils/jsonParser";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

import { JsonInvoiceUploadModal } from "../../../features/finance/components/modals/JsonInvoiceUploadModal";
import { InvoiceXmlUpload } from "../../../features/finance/components/invoices/InvoiceXmlUpload";
import VatExportEntryModal from "../../../features/finance/components/invoices/VatExportEntryModal";
import InvoiceUploadModal from "./InvoiceUploadModal";

import { invoiceService } from "@/features/finance/api/invoiceService";
import { moneySum, fmtMoney } from "@/shared/utils/money";


const { Content } = Layout;
const { Text } = Typography;
const { RangePicker } = DatePicker;

const statusMap: any = {
  draft: {
    color: "orange",
    text: "Nháp",
    icon: <ScanOutlined spin />,
  },
  verified: {
    color: "green",
    text: "Đã Nhập Kho",
    icon: <CheckCircleOutlined />,
  },
  verified_outbound: {
    color: "red",
    text: "Đã xuất kho (VAT)",
    icon: <CheckCircleOutlined />,
  },
  rejected: { color: "red", text: "Từ chối", icon: <DeleteOutlined /> },
};

const paymentStatusMap: any = {
  UNPAID: { color: "red", text: "Chưa thanh toán" },
  PARTIAL: { color: "orange", text: "Thanh toán một phần" },
  PAID: { color: "green", text: "Đã thanh toán" },
};

const InvoicesPage = () => {
  const { message } = App.useApp();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 10,
  });
  const [filters, setFilters] = useState<any>({});
  const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);

  const [isUploadOpen, setIsUploadOpen] = useState(false);
  const [isXmlUploadOpen, setIsXmlUploadOpen] = useState(false);
  const [isVatExportOpen, setIsVatExportOpen] = useState(false);
  const [isXmlOutboundOpen, setIsXmlOutboundOpen] = useState(false);
  const [isJsonUploadOpen, setIsJsonUploadOpen] = useState(false);
  const [syncProgress, setSyncProgress] = useState<{
    current: number;
    total: number;
  } | null>(null);
  const [, setSyncDebounce] = useState<any>(null);

  // FETCH DATA WITH REACT QUERY
  const { data: gdtStatus, refetch: refetchGdt } = useQuery({
    queryKey: ["gdt_status"],
    queryFn: invoiceService.getGdtStatus,
    refetchInterval: 60000,
  });

  const {
    data: queryData,
    isLoading,
    refetch,
  } = useQuery({
    queryKey: ["invoices", pagination.current, pagination.pageSize, filters],
    queryFn: () =>
      invoiceService.getInvoices(
        pagination.current,
        pagination.pageSize,
        filters
      ),
  });

  const data = queryData?.data || [];
  const total = queryData?.total || 0;

  const pendingCount = data.filter((i: any) => i.status === "draft").length;
  const totalAmt = moneySum(data.map((i: any) => i.total_amount_post_tax || 0));

  // MUTATIONS
  const deleteMutation = useMutation({
    mutationFn: (id: number) => invoiceService.deleteInvoice(id),
    onSuccess: () => {
      message.success("Đã xóa hóa đơn");
      queryClient.invalidateQueries({ queryKey: ["invoices"] });
    },
    onError: (error: any) => {
      message.error(error?.message || "Xóa thất bại. Vui lòng liên hệ ADMIN.");
    },
  });

  const bulkDeleteMutation = useMutation({
    mutationFn: (ids: number[]) => invoiceService.deleteInvoices(ids),
    onSuccess: () => {
      message.success("Đã xóa hàng loạt hóa đơn");
      setSelectedRowKeys([]);
      queryClient.invalidateQueries({ queryKey: ["invoices"] });
    },
    onError: (error: any) => {
      message.error(
        error?.message || "Xóa hàng loạt thất bại. Vui lòng liên hệ ADMIN."
      );
    },
  });

  // GDT SYNC LOGIC
  useEffect(() => {
    const handleSync = async (e: any) => {
      let gdtInvoices = e.detail;
      if (typeof gdtInvoices === "string") {
        try {
          gdtInvoices = JSON.parse(gdtInvoices);
        } catch (err) {
          console.error("Invalid JSON in detail");
        }
      }
      if (!gdtInvoices || gdtInvoices.length === 0) return;

      const parsedInvoices = gdtInvoices.map((inv: any) => {
        return parseGdtJsonInvoice(inv);
      });

      setSyncProgress((prev: any) => {
        const newTotal = (prev?.total || 0) + parsedInvoices.length;
        return { current: newTotal, total: newTotal };
      });

      try {
        const result = await invoiceService.syncGdtInvoices(parsedInvoices);

        queryClient.setQueryData(
          ["invoices", pagination.current, pagination.pageSize, filters],
          (oldData: any) => {
            if (!oldData) return oldData;

            const newRows = parsedInvoices.map((pi: any) => ({
              id: Date.now() + Math.random(), 
              invoice_number: pi.header.invoice_number,
              invoice_symbol: pi.header.invoice_symbol,
              invoice_date: pi.header.invoice_date,
              supplier_name_raw: pi.header.supplier_name,
              total_amount_post_tax: pi.header.total_amount_post_tax,
              status: "draft",
              created_at: new Date().toISOString(),
            }));

            return {
              ...oldData,
              data: [...newRows, ...oldData.data],
            };
          }
        );

        setSyncDebounce((oldTimer: any) => {
          if (oldTimer) clearTimeout(oldTimer);
          return setTimeout(() => {
            message.success({
              content: `Hoàn tất đồng bộ ${result.synced_count} hóa đơn mới!`,
              key: "syncGdtComplete",
            });
            setSyncProgress(null);
            queryClient.invalidateQueries(["invoices"] as any);
            queryClient.invalidateQueries(["sales_invoices"] as any);
          }, 2000);
        });
      } catch (err: any) {
        message.error({
          content: "Lỗi đồng bộ: " + err.message,
          key: "syncGdtErr",
        });
      }
    };

    window.addEventListener("NAMVIET_ERP_SYNC_INVOICE", handleSync);
    return () =>
      window.removeEventListener("NAMVIET_ERP_SYNC_INVOICE", handleSync);
  }, [queryClient, message]);

  // --- ACTIONS ---
  const handleDelete = (id: number) => {
    deleteMutation.mutate(id);
  };

  const handleBulkDelete = () => {
    if (selectedRowKeys.length === 0) return;
    bulkDeleteMutation.mutate(selectedRowKeys as number[]);
  };

  const handleExportExcel = () => {
    if (data.length === 0) return message.warning("Không có dữ liệu để xuất");

    const exportData = data.map((inv) => ({
      "Số HĐ": inv.invoice_number,
      "Ký hiệu": inv.invoice_symbol,
      "Ngày HĐ": inv.invoice_date,
      Loại: inv.direction === "outbound" ? "Bán ra" : "Mua vào",
      "Đối tác":
        inv.direction === "outbound"
          ? (inv as any).buyer_company_name ||
            (inv as any).buyer_name ||
            "(Chưa có thông tin)"
          : inv.supplier_name_raw || "(Chưa map)",
      "Tổng tiền (Sau thuế)": inv.total_amount_post_tax || 0,
      "Đã Thanh Toán": inv.paid_amount || 0,
      "Trạng thái": inv.status === "verified" ? "Đã nhập kho" : "Chờ xử lý",
      "Ngày nhập": dayjs(inv.created_at).format("DD/MM/YYYY HH:mm"),
    }));

    const worksheet = XLSX.utils.json_to_sheet(exportData);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, "DanhSachHoaDon");
    XLSX.writeFile(workbook, `DS_HoaDon_${dayjs().format("DDMMYYYY")}.xlsx`);
  };

  const onSelectChange = (newSelectedRowKeys: React.Key[]) => {
    setSelectedRowKeys(newSelectedRowKeys);
  };

  const rowSelection = {
    selectedRowKeys,
    onChange: onSelectChange,
  };

  const columns = [
    {
      title: "Số Hóa Đơn",
      dataIndex: "invoice_number",
      render: (text: string, record: any) => (
        <div>
          <Text strong>{text || "(Chưa có số)"}</Text>
          <div style={{ fontSize: 12, color: "#888" }}>
            KH: {record.invoice_symbol}
          </div>
        </div>
      ),
    },
    {
      title: "Ngày HĐ",
      dataIndex: "invoice_date",
      sorter: (a: any, b: any) =>
        dayjs(a.invoice_date).unix() - dayjs(b.invoice_date).unix(),
      render: (d: string) => (d ? dayjs(d).format("DD/MM/YYYY") : "--"),
    },
    {
      title: "Loại",
      dataIndex: "direction",
      align: "center" as const,
      width: 100,
      render: (dir: string) => {
        if (dir === "outbound") {
          return <Tag color="blue">Bán ra</Tag>;
        }
        return <Tag color="orange">Mua vào</Tag>;
      },
    },
    {
      title: "Đối tác",
      dataIndex: "supplier_name_raw",
      render: (text: string, record: any) => {
        if (record.direction === "outbound") {
          return (
            <Text strong style={{ wordBreak: "break-word" }}>
              {record.buyer_company_name || record.buyer_name || "--"}
            </Text>
          );
        }
        return (
          <Text strong style={{ wordBreak: "break-word" }}>
            {text || record.suppliers?.name || "--"}
          </Text>
        );
      },
    },
    {
      title: "Tổng Tiền",
      dataIndex: "total_amount_post_tax",
      align: "right" as const,
      render: (v: number, record: any) => {
        let amount = v || 0;
        if (!amount && record.items_json && Array.isArray(record.items_json)) {
          amount = record.items_json.reduce((sum: number, item: any) => {
            const price = Number(item.price) || 0;
            const qty = Number(item.vat_qty || item.quantity || 0);
            const vatRate = Number(item.vat_rate || 0);
            const lineTotal = price * qty;
            return sum + lineTotal + (lineTotal * vatRate) / 100;
          }, 0);
        }
        return <Text strong>{fmtMoney(amount)} ₫</Text>;
      },
    },
    {
      title: "Đã Thanh Toán",
      dataIndex: "paid_amount",
      align: "right" as const,
      render: (v: number) => (
        <Text strong style={{ color: "#3f8600" }}>
          {fmtMoney(v || 0)} ₫
        </Text>
      ),
    },
    {
      title: "Nhập kho HĐ",
      dataIndex: "status",
      align: "center" as const,
      width: 150,
      render: (status: string) => {
        const s = statusMap[status] || { color: "default", text: status };
        return (
          <Tag color={s.color} icon={s.icon}>
            {s.text}
          </Tag>
        );
      },
    },
    {
      title: "TT Thanh Toán",
      dataIndex: "payment_status",
      align: "center" as const,
      width: 150,
      render: (status: string) => {
        const s = paymentStatusMap[status] || {
          color: "default",
          text: "Chưa thanh toán",
        };
        return <Tag color={s.color}>{s.text}</Tag>;
      },
    },
    {
      title: "Hành động",
      align: "center" as const,
      width: 120,
      render: (_: any, record: any) => (
        <Space>
          <Tooltip
            title={
              record.status === "draft" ? "Đối chiếu ngay" : "Xem chi tiết"
            }
          >
            <Button
              type={record.status === "draft" ? "primary" : "default"}
              size="small"
              icon={
                record.status === "draft" ? <ScanOutlined /> : <EyeOutlined />
              }
              onClick={() => navigate(`/finance/invoices/verify/${record.id}`)}
            />
          </Tooltip>

          {record.status === "draft" && (
            <Popconfirm
              title="Xóa hóa đơn này?"
              onConfirm={() => handleDelete(record.id)}
            >
              <Button
                danger
                icon={<DeleteOutlined />}
                size="small"
                type="text"
              />
            </Popconfirm>
          )}
        </Space>
      ),
    },
  ];

  const headerExtra = (
    <Space wrap>
      <Button
        type="primary"
        icon={<CloudUploadOutlined />}
        onClick={() => setIsUploadOpen(true)}
      >
        Scan Ảnh (AI Gemini)
      </Button>
      <Button
        type="primary"
        icon={<FileTextOutlined />}
        onClick={() => setIsXmlUploadOpen(true)}
      >
        Nhập XML (Chuẩn Thuế)
      </Button>
      <Button
        type="primary"
        icon={<FileTextOutlined />}
        onClick={() => setIsJsonUploadOpen(true)}
      >
        Nhập JSON (GDT)
      </Button>
      <Button
        icon={<MinusCircleOutlined />}
        style={{ borderColor: "#ff4d4f", color: "#ff4d4f" }}
        onClick={() => setIsXmlOutboundOpen(true)}
      >
        Trừ kho VAT (XML)
      </Button>
      <Button
        icon={<MinusCircleOutlined />}
        style={{ borderColor: "#ff4d4f", color: "#ff4d4f" }}
        onClick={() => setIsVatExportOpen(true)}
      >
        Trừ kho VAT (Nhập tay)
      </Button>
      <Button icon={<DownloadOutlined />} onClick={handleExportExcel}>
        Xuất Excel
      </Button>
    </Space>
  );

  const expandedRowRender = (record: any) => {
    const items = record.finance_invoice_items || [];
    if (!items.length) {
      return <Text type="secondary">Chưa có chi tiết sản phẩm.</Text>;
    }

    const itemColumns = [
      {
        title: "Tên SP",
        dataIndex: "vendor_product_name",
        key: "vendor_product_name",
        render: (text: string, r: any) =>
          text || r.product_name_raw || `SP ID: ${r.product_id}`,
      },
      { title: "ĐVT", dataIndex: "vendor_unit", key: "vendor_unit" },
      { title: "S.Lượng", dataIndex: "quantity", key: "quantity" },
      {
        title: "Đơn giá",
        dataIndex: "pre_vat_price",
        key: "pre_vat_price",
        render: (val: number) => fmtMoney(val),
      },
      { title: "VAT %", dataIndex: "vat_rate", key: "vat_rate" },
      {
        title: "Thành tiền",
        dataIndex: "total_amount_pre_vat",
        key: "total_amount_pre_vat",
        render: (val: number) => fmtMoney(val),
      },
    ];

    return (
      <Table
        columns={itemColumns}
        dataSource={items}
        pagination={false}
        size="small"
        rowKey="id"
      />
    );
  };

  return (
    <Layout style={{ minHeight: "100vh", background: "#f2f7fc" }}>
      {syncProgress && (
        <div
          style={{
            padding: "16px 24px 0 24px",
            maxWidth: 1900,
            margin: "0 auto",
            width: "100%",
          }}
        >
          <Alert
            message={`Đang đồng bộ hóa đơn thời gian thực (Streaming): ${syncProgress.current} tờ...`}
            type="info"
            showIcon
            style={{ marginBottom: 0 }}
            icon={<SyncOutlined spin />}
          />
        </div>
      )}

        <Card style={{ margin: "24px 24px 0 24px", borderRadius: 8 }}>
          <Row justify="space-between" align="middle">
            <Col>
              <Space>
                <CloudSyncOutlined style={{ fontSize: 24, color: gdtStatus?.status === 'active' ? '#52c41a' : '#ff4d4f' }} />
                <Typography.Text strong>Trạng thái kết nối Tổng Cục Thuế:</Typography.Text>
                {gdtStatus?.status === 'active' ? (
                  <Tag color="success">Đã kết nối</Tag>
                ) : (
                  <Tag color="error">Mất kết nối</Tag>
                )}
                {gdtStatus?.status === 'active' && <Typography.Text type="secondary">(Cập nhật: {new Date(gdtStatus.updated_at).toLocaleString('vi-VN')})</Typography.Text>}
              </Space>
            </Col>
            <Col>
              <Space>
                <Button 
                  type="primary" 
                  onClick={() => {
                    const interval = setInterval(() => {
                      refetchGdt();
                    }, 5000);
                    setTimeout(() => clearInterval(interval), 60000); // stop polling after 1 min
                  }}
                  href="https://hoadondientu.gdt.gov.vn"
                  target="_blank"
                >
                  Đăng nhập Cục Thuế
                </Button>
                <Button 
                  onClick={async () => {
                    try {
                      await invoiceService.syncGdtNow();
                      message.success("Đã gửi lệnh đồng bộ ngầm lên server.");
                    } catch (e: any) {
                      message.error("Lỗi đồng bộ: " + e.message);
                    }
                  }}
                >
                  Đồng bộ khẩn cấp
                </Button>
              </Space>
            </Col>
          </Row>
        </Card>

      <Content
        style={{ padding: 24, maxWidth: 1900, margin: "0 auto", width: "100%" }}
      >
        <Row gutter={16} style={{ marginBottom: 24 }}>
          <Col span={12}>
            <Card bordered={false}>
              <Statistic
                title="Hóa đơn chờ đối chiếu"
                value={pendingCount}
                valueStyle={{ color: "#faad14" }}
                prefix={<ScanOutlined />}
              />
            </Card>
          </Col>
          <Col span={12}>
            <Card bordered={false}>
              <Statistic
                title="Tổng tiền (Trang này)"
                value={totalAmt}
                valueStyle={{ color: "#3f8600" }}
                prefix={<DollarCircleOutlined />}
              />
            </Card>
          </Col>
        </Row>

        <Card
          title={
            <Space>
              <FilePdfOutlined /> Quản lý Hóa Đơn VAT
            </Space>
          }
          extra={headerExtra}
          styles={{ body: { padding: 0 } }}
        >
          <div style={{ padding: 24, borderBottom: "1px solid #f0f0f0" }}>
            <Row gutter={16}>
              <Col span={6}>
                <Input
                  prefix={<SearchOutlined />}
                  placeholder="Tìm số HĐ, đối tác..."
                  onChange={(e) =>
                    setFilters({ ...filters, search: e.target.value })
                  }
                />
              </Col>
              <Col span={4}>
                <Select
                  placeholder="Loại HĐ"
                  allowClear
                  style={{ width: "100%" }}
                  onChange={(val: string) =>
                    setFilters({ ...filters, direction: val })
                  }
                >
                  <Select.Option value="inbound">Mua vào</Select.Option>
                  <Select.Option value="outbound">Bán ra</Select.Option>
                </Select>
              </Col>
              <Col span={4}>
                <Select
                  placeholder="Trạng thái"
                  allowClear
                  style={{ width: "100%" }}
                  onChange={(val: string) =>
                    setFilters({ ...filters, status: val })
                  }
                >
                  <Select.Option value="draft">Chờ đối chiếu</Select.Option>
                  <Select.Option value="verified">Đã nhập kho</Select.Option>
                  <Select.Option value="verified_outbound">
                    Đã xuất kho (VAT)
                  </Select.Option>
                </Select>
              </Col>
              <Col span={5}>
                <RangePicker
                  style={{ width: "100%" }}
                  onChange={(dates) =>
                    setFilters({
                      ...filters,
                      dateFrom: dates?.[0]?.toISOString(),
                      dateTo: dates?.[1]?.toISOString(),
                    })
                  }
                />
              </Col>
              <Col span={5} style={{ textAlign: "right" }}>
                <Space>
                  {selectedRowKeys.length > 0 && (
                    <Popconfirm
                      title={`Xóa ${selectedRowKeys.length} hóa đơn đã chọn?`}
                      onConfirm={handleBulkDelete}
                    >
                      <Button
                        danger
                        icon={<DeleteOutlined />}
                        loading={bulkDeleteMutation.isPending}
                      >
                        Xóa hàng loạt
                      </Button>
                    </Popconfirm>
                  )}
                  <Button icon={<SyncOutlined />} onClick={() => refetch()}>
                    Làm mới
                  </Button>
                </Space>
              </Col>
            </Row>
          </div>
          <Table
            rowSelection={rowSelection}
            dataSource={data}
            columns={columns}
            rowKey="id"
            loading={isLoading}
            expandable={{ expandedRowRender }}
            pagination={{
              current: pagination.current,
              pageSize: pagination.pageSize,
              total: total,
              showSizeChanger: true,
              showTotal: (total) => `Tổng số ${total} hóa đơn`,
              onChange: (page, pageSize) =>
                setPagination({ current: page, pageSize }),
            }}
          />
        </Card>

        <InvoiceUploadModal
          open={isUploadOpen}
          onCancel={() => {
            setIsUploadOpen(false);
            refetch();
          }}
        />
        <JsonInvoiceUploadModal
          isOpen={isJsonUploadOpen}
          onClose={() => setIsJsonUploadOpen(false)}
          onSuccess={() => {
            setIsJsonUploadOpen(false);
            refetch();
          }}
        />
        <InvoiceXmlUpload
          open={isXmlUploadOpen}
          onCancel={() => {
            setIsXmlUploadOpen(false);
            refetch();
          }}
        />
        <InvoiceXmlUpload
          open={isXmlOutboundOpen}
          onCancel={() => {
            setIsXmlOutboundOpen(false);
            refetch();
          }}
          direction="outbound"
        />
        <VatExportEntryModal
          open={isVatExportOpen}
          onCancel={() => setIsVatExportOpen(false)}
          onSuccess={() => refetch()}
        />
      </Content>
    </Layout>
  );
};

export default InvoicesPage;
