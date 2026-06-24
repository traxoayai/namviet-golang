import { Table } from "antd";
import { useEffect, useState } from "react";
import { supabase } from "@/shared/lib/supabaseClient";

interface Props {
  transactionId: number;
}

export const FinanceAllocationNestedTable = ({ transactionId }: Props) => {
  const [data, setData] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchAllocations();
  }, [transactionId]);

  const fetchAllocations = async () => {
    setLoading(true);
    try {
      const { data: allocations, error } = await supabase
        .from("finance_transaction_allocations" as any)
        .select(`
          id,
          allocated_amount,
          created_at,
          orders ( code )
        `)
        .eq("transaction_id", transactionId);

      if (error) throw error;
      setData(allocations || []);
    } catch (err) {
      console.error("Lỗi lấy chi tiết phân bổ:", err);
    } finally {
      setLoading(false);
    }
  };

  const columns = [
    {
      title: "Mã Đơn Hàng",
      dataIndex: ["orders", "code"],
      key: "order_code",
    },
    {
      title: "Số Tiền Gạch Nợ",
      dataIndex: "allocated_amount",
      key: "allocated_amount",
      render: (val: number) => `${val.toLocaleString("vi-VN")} ₫`,
    },
    {
      title: "Ngày Thực Hiện",
      dataIndex: "created_at",
      key: "created_at",
      render: (val: string) => new Date(val).toLocaleString("vi-VN"),
    },
  ];

  return (
    <Table
      columns={columns}
      dataSource={data}
      rowKey="id"
      pagination={false}
      size="small"
      loading={loading}
    />
  );
};
