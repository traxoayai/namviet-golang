// src/pages/purchasing/PurchaseOrderMasterPage.tsx
import { DeleteOutlined } from "@ant-design/icons";
import { Layout, Typography, App, Button, Popconfirm, Space } from "antd";
import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";

import { purchaseOrderService } from "../../features/purchasing/api/purchaseOrderService";
import { PurchaseOrderFilters } from "../../features/purchasing/components/PurchaseOrderFilters";
import { PurchaseOrderTable } from "../../features/purchasing/components/PurchaseOrderTable";
import { usePurchaseOrderMaster } from "../../features/purchasing/hooks/usePurchaseOrderMaster";
import { PurchaseOrderMaster } from "../../features/purchasing/types/purchase";
import { FinanceFormModal } from "../../pages/finance/components/FinanceFormModal";
import { parseNumericOrZero } from "@/shared/utils/numeric";

import { AutoReplenishPreviewModal } from "../../features/purchasing/components/AutoReplenishPreviewModal";

const { Content } = Layout;
const { Title } = Typography;

const PurchaseOrderMasterPage: React.FC = () => {
  const {
    orders,
    loading,
    pagination,
    setPagination,
    filters,
    setFilters,
    deleteOrder,
    bulkDeleteOrders,
    autoCreate,
    fetchOrders,
  } = usePurchaseOrderMaster();

  const navigate = useNavigate();
  const { message } = App.useApp();
  const [cloningId, setCloningId] = useState<number | null>(null);

  // Auto Replenish Modal State
  const [isReplenishModalVisible, setIsReplenishModalVisible] = useState(false);
  const [replenishData, setReplenishData] = useState<any[]>([]);

  const handleAutoCreate = async () => {
    const data = await autoCreate();
    if (data && data.generated_pos) {
      setReplenishData(data.generated_pos);
      setIsReplenishModalVisible(true);
    }
  };

  useEffect(() => {
    const onFocus = () => {
      fetchOrders();
    };
    window.addEventListener("focus", onFocus);
    return () => window.removeEventListener("focus", onFocus);
  }, [fetchOrders]);

  const [selectedRowKeys, setSelectedRowKeys] = useState<number[]>([]);
  const [selectedRows, setSelectedRows] = useState<PurchaseOrderMaster[]>([]);

  const totalPackagesSelected = selectedRows.reduce(
    (sum, r) => sum + (r.total_packages || 0),
    0
  );
  
  const totalUnpaidSupplier = selectedRows.reduce((sum, r) => {
    const finalAmount = parseNumericOrZero(r.final_amount);
    const shippingFee = parseNumericOrZero(r.shipping_fee);
    const paid = parseNumericOrZero(r.total_paid);
    return sum + (finalAmount - shippingFee - paid);
  }, 0);

  const isSameSupplier =
    selectedRows.length > 0 &&
    selectedRows.every((r) => r.supplier_id === selectedRows[0].supplier_id);

  const canBulkDelete =
    selectedRows.length > 0 &&
    selectedRows.every(
      (r) =>
        r.status?.toUpperCase() === "DRAFT" &&
        (!r.delivery_status || r.delivery_status === "pending" || r.delivery_status === "draft")
    );

  // DEBUG
  useEffect(() => {
    if (selectedRows.length > 0) {
      console.log("DEBUG BulkDelete - selectedRows:", selectedRows.map(r => ({ id: r.id, status: r.status, delivery_status: r.delivery_status })));
      console.log("DEBUG BulkDelete - canBulkDelete:", canBulkDelete);
    }
  }, [selectedRows, canBulkDelete]);

  const handleBulkDelete = () => {
    if (!canBulkDelete) return;
    bulkDeleteOrders(selectedRowKeys);
    setSelectedRowKeys([]);
    setSelectedRows([]);
  };

  const handleBulkPayment = () => {
    if (!isSameSupplier || selectedRows.length === 0) return;
    const firstOrder = selectedRows[0];
    setPaymentModalConfig({
      visible: true,
      partner_type: "supplier",
      partner_id: firstOrder.supplier_id,
      partner_name: firstOrder.supplier_name,
      amount: totalUnpaidSupplier,
      description: `Thanh toán ${selectedRows.length} đơn hàng: ${selectedRows
        .map((r) => r.code)
        .join(", ")}`,
      ref_type: "purchase_order",
      ref_id: firstOrder.id,
      category_id: 5,
      po_bulk_allocations: selectedRows.map((r) => ({
        po_id: String(r.id),
        amount: Number(r.final_amount || 0) - Number(r.total_paid || 0),
      })),
    });
  };

  const [paymentModalConfig, setPaymentModalConfig] = useState<any>({
    visible: false,
    partner_type: "supplier",
  });

  const handleCloneOrder = async (order: PurchaseOrderMaster) => {
    setCloningId(order.id);
    try {
      const rawDetail = await purchaseOrderService.getPODetail(order.id);
      if (!rawDetail) throw new Error("Không tải được dữ liệu gốc");
      const detail = rawDetail as unknown as Record<string, unknown>;

      const clonePayload = {
        supplier_id: detail.supplier_id as number,
        expected_date: undefined as string | undefined,
        note: `Sao chép từ đơn ${detail.code as string}`,
        delivery_method: detail.delivery_method as string,
        shipping_partner_id: detail.shipping_partner_id as number,
        shipping_fee: detail.shipping_fee as number,
        status: "DRAFT" as const,

        items: ((detail.items as unknown[]) || []).map((i: unknown) => {
          const item = i as Record<string, unknown>;
          return {
            product_id: item.product_id as number,
            quantity: item.quantity_ordered as number,
            unit_price: item.unit_price as number,
            unit: (item.uom_ordered as string) || (item.unit as string),
            is_bonus: item.is_bonus as boolean,
          };
        }),
      };

      const res = await purchaseOrderService.createPO(clonePayload);

      message.success("Sao chép thành công!");
      const created = res as unknown as { id: number };
      const newId = created.id || res;
      navigate(`/purchase-orders/${newId}`);
    } catch (error: unknown) {
      const errMsg =
        error instanceof Error ? error.message : "Lỗi không xác định";
      message.error("Lỗi sao chép: " + errMsg);
    } finally {
      setCloningId(null);
    }
  };

  const handleOpenPayment = (order: PurchaseOrderMaster) => {
    const finalAmt = parseNumericOrZero(order.final_amount);
    const shipFee = parseNumericOrZero(order.shipping_fee);
    const paid = parseNumericOrZero(order.total_paid);
    
    setPaymentModalConfig({
      visible: true,
      partner_type: "supplier",
      partner_id: order.supplier_id,
      partner_name: order.supplier_name,
      amount: finalAmt - shipFee - paid,
      description: `Thanh toán đơn hàng ${order.code}`,
      ref_type: "purchase_order",
      ref_id: order.id,
      category_id: 5,
    });
  };

  const handleOpenShippingPayment = (order: PurchaseOrderMaster) => {
    const shipFee = parseNumericOrZero(order.shipping_fee);
    const shipPaid = parseNumericOrZero(order.shipping_paid);
    
    setPaymentModalConfig({
      visible: true,
      partner_type: "shipping_partner",
      partner_id: order.shipping_partner_id,
      partner_name: order.shipping_partner_name || order.carrier_name,
      amount: shipFee - shipPaid,
      description: `Thanh toán phí vận chuyển đơn hàng ${order.code}`,
      ref_type: "purchase_order",
      ref_id: order.id,
      category_code: "CHI006",
      category_id: 32,
    });
  };

  const handlePaymentModalClose = () => {
    setPaymentModalConfig({ ...paymentModalConfig, visible: false });
    fetchOrders();
    setSelectedRowKeys([]);
    setSelectedRows([]);
  };

  return (
    <Layout style={{ minHeight: "100vh", background: "#f2f7fc" }}>
      <Content style={{ padding: "12px" }}>
        <div style={{ marginBottom: 16 }}>
          <Title level={3} style={{ marginTop: 6 }}>
            Quản Lý Đơn Mua Hàng
          </Title>
        </div>

        <PurchaseOrderFilters
          filters={filters}
          setFilters={setFilters}
          onAutoCreate={handleAutoCreate}
        />

        <div style={{ background: "#fff", padding: 12, borderRadius: 8 }}>
          {selectedRowKeys.length > 0 && (
            <div style={{ marginBottom: 16, padding: "8px 16px", background: "#e6f7ff", border: "1px solid #91d5ff", borderRadius: 4, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <Typography.Text strong>
                Đã chọn {selectedRowKeys.length} đơn | Tổng {totalPackagesSelected} kiện | Nợ cần trả: {new Intl.NumberFormat("vi-VN").format(totalUnpaidSupplier)}đ
              </Typography.Text>
              <Space>
                {isSameSupplier ? (
                  <Button type="primary" onClick={handleBulkPayment}>Thanh toán hàng loạt</Button>
                ) : (
                  <Typography.Text type="warning" style={{ fontSize: 13 }}>
                    (Thanh toán hàng loạt chỉ hỗ trợ các đơn cùng NCC)
                  </Typography.Text>
                )}
                {canBulkDelete && (
                  <Popconfirm
                    title={`Bạn có chắc chắn muốn xóa ${selectedRows.length} đơn hàng này không?`}
                    onConfirm={handleBulkDelete}
                    okText="Có"
                    cancelText="Không"
                  >
                    <Button danger icon={<DeleteOutlined />}>Xóa hàng loạt</Button>
                  </Popconfirm>
                )}
              </Space>
            </div>
          )}
          
          <PurchaseOrderTable
            orders={orders}
            loading={loading || cloningId !== null}
            pagination={{
              current: pagination.page,
              pageSize: pagination.pageSize,
              total: pagination.total,
            }}
            setPagination={setPagination}
            onDelete={deleteOrder}
            onOpenPaymentModal={handleOpenPayment}
            onOpenShippingPaymentModal={handleOpenShippingPayment}
            onClone={handleCloneOrder}
            selectedRowKeys={selectedRowKeys}
            onRowSelectionChange={(keys, rows) => {
              setSelectedRowKeys(keys as number[]);
              setSelectedRows(rows);
            }}
            onFilterChange={(tableFilters: any) => {
              const newFilters = { ...filters };
              
              if (tableFilters.status && tableFilters.status.length > 0) {
                newFilters.status = tableFilters.status[0];
              } else {
                delete newFilters.status;
              }

              if (tableFilters.delivery_status && tableFilters.delivery_status.length > 0) {
                newFilters.status_delivery = tableFilters.delivery_status[0];
              } else {
                delete newFilters.status_delivery;
              }

              if (tableFilters.payment && tableFilters.payment.length > 0) {
                newFilters.status_payment = tableFilters.payment[0];
              } else {
                delete newFilters.status_payment;
              }

              if (tableFilters.supplier_name && tableFilters.supplier_name.length > 0) {
                newFilters.search = tableFilters.supplier_name[0];
              } else {
                delete newFilters.search; // Mượn tính năng tìm kiếm cho nhà cung cấp
              }

              setFilters(newFilters);
              setPagination({ ...pagination, page: 1 });
            }}
          />
        </div>

        {paymentModalConfig.visible && paymentModalConfig.partner_id ? (
          <FinanceFormModal
            open={paymentModalConfig.visible}
            onCancel={handlePaymentModalClose}
            initialFlow="out"
            initialValues={{
              business_type: "trade",
              partner_type: paymentModalConfig.partner_type,
              [paymentModalConfig.partner_type === "supplier" ? "supplier_id" : "partner_id"]: paymentModalConfig.partner_id,
              partner_name: paymentModalConfig.partner_name,
              amount: paymentModalConfig.amount,
              description: paymentModalConfig.description,
              ref_type: "purchase_order",
              ref_id: paymentModalConfig.ref_id,
              category_code: paymentModalConfig.category_code,
              category_id: paymentModalConfig.category_id,
              po_bulk_allocations: paymentModalConfig.po_bulk_allocations,
            }}
            onSuccess={() => {
              handlePaymentModalClose();
              fetchOrders();
              setSelectedRowKeys([]);
              setSelectedRows([]);
            }}
          />
        ) : null}

        <AutoReplenishPreviewModal
          visible={isReplenishModalVisible}
          onCancel={() => setIsReplenishModalVisible(false)}
          data={replenishData}
        />
      </Content>
    </Layout>
  );
};

export default PurchaseOrderMasterPage;
