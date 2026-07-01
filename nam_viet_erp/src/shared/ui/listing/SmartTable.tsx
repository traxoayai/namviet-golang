// src/components/shared/listing/SmartTable.tsx
import { InboxOutlined } from "@ant-design/icons";
import { TableProps } from "antd";
import React from "react"; // Thêm React
import { ResponsiveTable } from "@/shared/ui/common/ResponsiveTable";

interface Props<T> extends TableProps<T> {
  emptyText?: string;
}

// Helper component để React.memo hoạt động tốt với Generic Type
const SmartTableInner = <T extends object>({
  emptyText,
  ...rest
}: Props<T>) => {
  return (
    <div style={{ background: "#fff", borderRadius: "8px", boxShadow: "0 1px 3px rgba(0,0,0,0.05)", border: "1px solid #f0f0f0", overflow: "hidden" }}>
      <ResponsiveTable
        {...rest}
        rowKey={(record: any) => record.key || record.id}
        size="middle"
        locale={{
          emptyText: (
            <div style={{ padding: 40, textAlign: "center" }}>
              <InboxOutlined style={{ fontSize: 48, color: "#d9d9d9" }} />
              <p style={{ color: "#888", marginTop: 12 }}>
                {emptyText || "Không có dữ liệu"}
              </p>
            </div>
          ),
        }}
        scroll={{ x: "max-content" }}
      />
    </div>
  );
};

// Áp dụng React.memo
export const SmartTable = React.memo(SmartTableInner) as typeof SmartTableInner;
