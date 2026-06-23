import React, { useState } from "react";
import {
  Modal,
  Upload,
  Button,
  message,
  Table,
  Typography,
  Progress,
  Space,
} from "antd";
import { supabase } from "@/shared/lib/supabaseClient";
import { InboxOutlined, FileTextOutlined } from "@ant-design/icons";

const { Dragger } = Upload;
const { Text } = Typography;

interface JsonInvoiceUploadModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export const JsonInvoiceUploadModal: React.FC<JsonInvoiceUploadModalProps> = ({
  isOpen,
  onClose,
  onSuccess,
}) => {
  const [fileList, setFileList] = useState<any[]>([]);
  const [invoices, setInvoices] = useState<any[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [progress, setProgress] = useState({ current: 0, total: 0 });

  const handleUpload = (file: File) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const result = e.target?.result as string;
        const parsed = JSON.parse(result);
        if (Array.isArray(parsed)) {
          setInvoices(parsed);
          message.success(`Đã đọc được ${parsed.length} hóa đơn từ file.`);
        } else {
          message.error("File JSON không đúng định dạng (phải là một mảng).");
        }
      } catch (err) {
        message.error("Lỗi khi parse file JSON.");
      }
    };
    reader.readAsText(file);
    return false; // Prevent automatic upload
  };

  const handleRemove = () => {
    setFileList([]);
    setInvoices([]);
  };

  const processImport = async () => {
    if (invoices.length === 0) return;
    setIsProcessing(true);
    setProgress({ current: 0, total: invoices.length });

    let successCount = 0;
    let errorCount = 0;

    for (let i = 0; i < invoices.length; i++) {
      const inv = invoices[i];
      try {
        // Map data
                // Extract tax breakdowns
        const taxBreakdowns = (inv.thttltsuat || []).map((t: any) => {
          let vatRateStr = t.tsuat;
          let vatRateNum = 0;
          if (vatRateStr !== undefined && vatRateStr !== null) {
            if (typeof vatRateStr === "string" && vatRateStr.includes("%")) {
               vatRateNum = parseFloat(vatRateStr.replace("%", ""));
            } else {
               vatRateNum = Number(vatRateStr) * 100;
            }
          }
          return {
            vat_rate: vatRateNum,
            total_amount_pre_tax: t.thtien ? Number(t.thtien) : 0,
            tax_amount: t.tthue ? Number(t.tthue) : 0,
          };
        });

        // Construct xml_data to match what InvoiceVerifyPage expects
        const parsed_data = {
          header: {
            supplier_name: inv.nbten || "",
            supplier_tax_code: inv.nbmst || "",
            supplier_address: inv.nbdchi || "",
            tax_breakdowns: taxBreakdowns,
            tgtcthue: inv.tgtcthue ? Number(inv.tgtcthue) : 0,
            ttcktmai: inv.ttcktmai ? Number(inv.ttcktmai) : 0,
            thttlphi: inv.thttlphi ? Number(inv.thttlphi) : 0,
            tgtthue: inv.tgtthue ? Number(inv.tgtthue) : 0,
            tgtttbso: inv.tgtttbso ? Number(inv.tgtttbso) : 0,
          },
          items: (inv.hdhhdvu || []).map((item: any) => {
            let vatRateStr = item.tsuat;
            let vatRateNum = 0;
            if (vatRateStr !== undefined && vatRateStr !== null) {
              if (typeof vatRateStr === "string" && vatRateStr.includes("%")) {
                 vatRateNum = parseFloat(vatRateStr.replace("%", ""));
              } else {
                 vatRateNum = Number(vatRateStr) * 100;
              }
            }
            return {
              name: item.ten || "",
              unit: item.dvtinh || "",
              quantity: item.sluong ? Number(item.sluong) : 0,
              unit_price: item.dgia ? Number(item.dgia) : 0,
              vat_rate: vatRateNum,
              amount_before_tax: item.thtien ? Number(item.thtien) : 0,
            };
          }),
          originalXml: inv
        };

        const p_invoice_data = {
          invoice_number: String(inv.shdon || ""),
          invoice_symbol: `${inv.khmshdon || ""}${inv.khhdon || ""}`,
          invoice_date: inv.tdlap ? new Date(inv.tdlap).toISOString() : null,
          supplier_id: null,
          supplier_tax: inv.nbmst || null,
          buyer_name: inv.nmten || null,
          buyer_tax_code: inv.nmmst || null,
          buyer_address: inv.nmdchi || null,
          buyer_email: inv.nmdctdtu || null,
          total_amount: inv.tgtttbso ? Number(inv.tgtttbso) : 0,
          total_price_excludes_vat: inv.tgtcthue ? Number(inv.tgtcthue) : 0,
          total_fee_amount: inv.thttlphi ? Number(inv.thttlphi) : 0,
          total_trade_discount: inv.ttcktmai ? Number(inv.ttcktmai) : 0,
          tax_amount: inv.tgtthue ? Number(inv.tgtthue) : 0,
          status: "draft",
          direction: "inbound",
          xml_data: parsed_data, // Store mapped parsed_data instead of raw inv
        };

        const p_items_data = (inv.hdhhdvu || []).map((item: any) => {
          let vatRateStr = item.tsuat;
          let vatRateNum = 0;
          if (vatRateStr !== undefined && vatRateStr !== null) {
            if (typeof vatRateStr === "string" && vatRateStr.includes("%")) {
               vatRateNum = parseFloat(vatRateStr.replace("%", ""));
            } else {
               vatRateNum = Number(vatRateStr) * 100;
            }
          }

          return {
            product_id: null,
            product_unit_id: null,
            product_name_raw: item.ten || "",
            quantity: item.sluong ? Number(item.sluong) : 0,
            quantity_buyer: item.sluong ? Number(item.sluong) : 0,
            vendor_unit: item.dvtinh || "",
            unit_price: item.dgia ? Number(item.dgia) : 0,
            total_amount_pre_vat: item.thtien ? Number(item.thtien) : 0,
            vat_rate: vatRateNum,
            vat_amount: item.tthue ? Number(item.tthue) : 0,
            total_amount_with_vat: item.thtcthue 
                ? Number(item.thtcthue) 
                : Number(item.thtien || 0) * (1 + (vatRateNum / 100)),
          };
        });

        // Call RPC
        const { error } = await supabase.rpc("upsert_finance_invoice", {
          p_invoice_data,
          p_items_data,
        });

        if (error) {
          console.error(`Error importing invoice ${inv.shdon}:`, error);
          errorCount++;
        } else {
          successCount++;
        }
      } catch (err) {
        console.error(`Exception importing invoice ${inv.shdon}:`, err);
        errorCount++;
      }

      setProgress({ current: i + 1, total: invoices.length });
    }

    setIsProcessing(false);
    
    if (errorCount > 0) {
      message.warning(`Đã nhập thành công ${successCount}/${invoices.length} hóa đơn. Có ${errorCount} lỗi.`);
    } else {
      message.success(`Đã nhập thành công toàn bộ ${successCount} hóa đơn!`);
    }

    onSuccess();
    handleClose();
  };

  const handleClose = () => {
    if (!isProcessing) {
      setFileList([]);
      setInvoices([]);
      onClose();
    }
  };

  const columns = [
    {
      title: "Số HĐ",
      dataIndex: "shdon",
      key: "shdon",
    },
    {
      title: "Ký hiệu",
      key: "symbol",
      render: (_: any, record: any) => `${record.khmshdon || ""}${record.khhdon || ""}`,
    },
    {
      title: "Ngày lập",
      dataIndex: "tdlap",
      key: "tdlap",
      render: (val: string) => (val ? new Date(val).toLocaleDateString("vi-VN") : ""),
    },
    {
      title: "MST Người bán",
      dataIndex: "nbmst",
      key: "nbmst",
    },
    {
      title: "Tên Người bán",
      dataIndex: "nbten",
      key: "nbten",
      ellipsis: true,
    },
    {
      title: "Tổng tiền",
      dataIndex: "tgtttbso",
      key: "tgtttbso",
      render: (val: number) => new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(val || 0),
    },
  ];

  return (
    <Modal
      title="Nhập dữ liệu Hóa đơn từ JSON (GDT)"
      open={isOpen}
      onCancel={handleClose}
      width={900}
      footer={[
        <Button key="cancel" onClick={handleClose} disabled={isProcessing}>
          Đóng
        </Button>,
        <Button
          key="submit"
          type="primary"
          disabled={invoices.length === 0 || isProcessing}
          onClick={processImport}
          loading={isProcessing}
        >
          Nhập Dữ Liệu
        </Button>,
      ]}
    >
      <Dragger
        accept=".json"
        multiple={false}
        fileList={fileList}
        beforeUpload={(file) => {
          setFileList([file]);
          return handleUpload(file as File);
        }}
        onRemove={handleRemove}
        disabled={isProcessing}
      >
        <p className="ant-upload-drag-icon">
          <InboxOutlined />
        </p>
        <p className="ant-upload-text">Nhấp hoặc kéo thả file JSON vào đây</p>
        <p className="ant-upload-hint">
          Chỉ hỗ trợ file JSON định dạng kết xuất của Tổng Cục Thuế
        </p>
      </Dragger>

      {invoices.length > 0 && (
        <div style={{ marginTop: 24 }}>
          <Space direction="vertical" style={{ width: "100%" }}>
            <Text strong>
              <FileTextOutlined style={{ marginRight: 8 }} />
              Dữ liệu tìm thấy: {invoices.length} hóa đơn
            </Text>

            {isProcessing && (
              <Progress
                percent={Math.round((progress.current / progress.total) * 100)}
                status="active"
              />
            )}

            <Table
              dataSource={invoices.slice(0, 5)} // preview top 5
              columns={columns}
              rowKey={(record, idx) => record.shdon || String(idx)}
              pagination={false}
              size="small"
              footer={() =>
                invoices.length > 5 ? (
                  <Text type="secondary">
                    ...và {invoices.length - 5} hóa đơn khác
                  </Text>
                ) : undefined
              }
            />
          </Space>
        </div>
      )}
    </Modal>
  );
};
