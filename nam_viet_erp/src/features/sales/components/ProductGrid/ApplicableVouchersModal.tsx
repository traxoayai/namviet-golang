import React, { useEffect, useState, useMemo } from 'react';
import { Modal, List, Typography, Space, Tag, Button, Spin, Empty, Alert } from 'antd';
import { GiftOutlined, TagOutlined, RightCircleOutlined } from '@ant-design/icons';

import { salesService } from '@/features/sales/api/salesService';
import { VoucherRecord } from '@/features/sales/types/b2b_sales';
import { useSalesStore } from '@/features/sales/stores/useSalesStore';

const { Text } = Typography;

interface ApplicableVouchersModalProps {
  open: boolean;
  onClose: () => void;
}

export const ApplicableVouchersModal: React.FC<ApplicableVouchersModalProps> = ({
  open,
  onClose,
}) => {
  const store = useSalesStore();
  const customerId = store.customer?.id;
  
  // Tính tổng tiền không bao gồm quà tặng
  const orderTotal = useMemo(() => {
    return store.items.reduce((sum, item) => sum + (item.is_gift ? 0 : item.quantity * item.price_wholesale), 0);
  }, [store.items]);

  const [vouchers, setVouchers] = useState<VoucherRecord[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (open && customerId) {
      setLoading(true);
      salesService
        .getVouchers(customerId, orderTotal)
        .then(setVouchers)
        .catch(console.error)
        .finally(() => setLoading(false));
    }
  }, [open, customerId, orderTotal]);

  const handleApply = (voucher: VoucherRecord) => {
    store.setVoucher(voucher);
    onClose();
  };

  return (
    <Modal
      title={
        <Space>
          <GiftOutlined style={{ color: '#fa8c16' }} />
          <span>Danh sách Khuyến mãi</span>
        </Space>
      }
      open={open}
      onCancel={onClose}
      footer={null}
      width={600}
      styles={{ body: { padding: '0 24px 24px' } }}
    >
      {!customerId ? (
        <Alert 
          message="Vui lòng chọn khách hàng" 
          description="Hệ thống cần biết khách hàng để hiển thị các chương trình khuyến mãi phù hợp." 
          type="info" 
          showIcon 
          style={{ marginTop: 16 }}
        />
      ) : loading ? (
        <div style={{ textAlign: 'center', padding: '40px 0' }}>
          <Spin size="large" />
          <div style={{ marginTop: 16, color: '#888' }}>Đang tải danh sách khuyến mãi...</div>
        </div>
      ) : vouchers.length === 0 ? (
        <Empty
          image={Empty.PRESENTED_IMAGE_SIMPLE}
          description="Không có mã khuyến mãi nào cho khách hàng này"
          style={{ margin: '40px 0' }}
        />
      ) : (
        <List
          itemLayout="horizontal"
          dataSource={vouchers}
          renderItem={(voucher) => {
            const isApplicable = orderTotal >= voucher.min_order_value;
            const remaining = voucher.min_order_value - orderTotal;
            const isSelected = store.selectedVoucher?.id === voucher.id;

            return (
              <List.Item
                style={{
                  background: isSelected ? '#fff9e6' : '#fff',
                  border: `1px solid ${isSelected ? '#ffd591' : '#f0f0f0'}`,
                  borderRadius: 8,
                  marginBottom: 12,
                  padding: 16,
                  transition: 'all 0.3s',
                }}
                actions={[
                  <Button
                    key="apply"
                    type={isSelected ? 'default' : 'primary'}
                    size="middle"
                    icon={<RightCircleOutlined />}
                    disabled={!isApplicable}
                    onClick={() => handleApply(voucher)}
                  >
                    {isSelected ? 'Đang áp dụng' : 'Áp dụng ngay'}
                  </Button>,
                ]}
              >
                <List.Item.Meta
                  avatar={
                    <div style={{
                      width: 48,
                      height: 48,
                      background: '#fff2e8',
                      color: '#fa541c',
                      borderRadius: '50%',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: 24
                    }}>
                      <TagOutlined />
                    </div>
                  }
                  title={
                    <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: 8 }}>
                      <Text strong style={{ fontSize: 16 }}>{voucher.name}</Text>
                      <Tag color={isApplicable ? "green" : "default"}>{voucher.code}</Tag>
                    </div>
                  }
                  description={
                    <div style={{ marginTop: 8 }}>
                      <div style={{ marginBottom: 4, color: '#595959' }}>
                        Giảm {voucher.discount_type === 'percent' ? `${voucher.discount_value}%` : `${voucher.discount_value.toLocaleString()}đ`} 
                        {voucher.max_discount_value ? ` (Tối đa ${voucher.max_discount_value.toLocaleString()}đ)` : ''}
                      </div>
                      <div style={{ fontSize: 12, color: '#8c8c8c' }}>
                        Đơn tối thiểu: {voucher.min_order_value.toLocaleString()}đ
                      </div>
                      
                      {!isApplicable && remaining > 0 && (
                        <div style={{ 
                          marginTop: 8, 
                          color: '#d4380d', 
                          background: '#fff2e8', 
                          padding: '4px 8px', 
                          borderRadius: 4,
                          fontSize: 13,
                          display: 'inline-block'
                        }}>
                          <GiftOutlined /> Khách đang mua <b>{orderTotal.toLocaleString()}đ</b>. 
                          Chỉ cần mua thêm <b>{remaining.toLocaleString()}đ</b> nữa để dùng mã này!
                        </div>
                      )}
                    </div>
                  }
                />
              </List.Item>
            );
          }}
        />
      )}
    </Modal>
  );
};
