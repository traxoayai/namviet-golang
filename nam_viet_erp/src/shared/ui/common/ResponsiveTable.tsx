import { Table, Card, Grid } from "antd";
import type { TableProps } from "antd";

const { useBreakpoint } = Grid;

interface ResponsiveTableProps<T> extends TableProps<T> {
  // Bổ sung các props nếu cần
}

export function ResponsiveTable<T extends object>(props: ResponsiveTableProps<T>) {
  const screens = useBreakpoint();
  // Dưới md (nhỏ hơn 768px) được tính là mobile
  const isMobile = !screens.md && screens.xs !== undefined; 

  if (!isMobile) {
    return <Table {...props} />;
  }

  const { dataSource, columns, rowKey, loading } = props;

  // Render Card List cho Mobile
  return (
    <div className="flex flex-col gap-3">
      {loading && (!dataSource || dataSource.length === 0) && (
        <Card className="shadow-sm rounded-lg" loading={true} />
      )}
      
      {dataSource?.map((record, index) => {
        const key = typeof rowKey === 'function' ? rowKey(record) : (rowKey ? (record as any)[rowKey as string] : index);
        
        return (
          <Card key={key} size="small" className="shadow-sm rounded-lg border border-gray-100" bodyStyle={{ padding: '12px' }}>
            <div className="flex flex-col gap-2">
              {columns?.map((col: any, colIndex: number) => {
                // Bỏ qua các cột không có title (hoặc checkbox column)
                if (!col.title || col.type === 'checkbox' || col.type === 'selection') return null;
                
                // dataIndex có thể là mảng ['orders', 'code']
                let value = undefined;
                if (col.dataIndex) {
                   if (Array.isArray(col.dataIndex)) {
                     value = record;
                     for (const k of col.dataIndex) {
                        if (value) value = (value as any)[k];
                     }
                   } else {
                     value = (record as any)[col.dataIndex];
                   }
                }
                const renderedValue = col.render ? col.render(value, record, index) : value;

                return (
                  <div key={col.key || colIndex} className="flex justify-between items-start gap-2 border-b border-gray-50 pb-2 last:border-0 last:pb-0">
                    <span className="text-gray-500 font-medium text-xs whitespace-nowrap">{col.title}</span>
                    <div className="text-right flex-1 break-words text-sm">
                      {renderedValue}
                    </div>
                  </div>
                );
              })}
            </div>
          </Card>
        );
      })}
      
      {!loading && (!dataSource || dataSource.length === 0) && (
        <div className="text-center text-gray-400 py-8 bg-white rounded-lg border border-gray-100">
          Không có dữ liệu
        </div>
      )}
    </div>
  );
}
