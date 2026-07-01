import axiosClient from "@/shared/utils/axiosClient";

export interface WarehouseStats {
  pending_receive_count: number;
  pending_pack_count: number;
  low_stock_items: number;
  draft_po_count: number;
}

export interface FinanceStats {
  total_revenue_month: number;
  total_debt_receivable: number;
  total_debt_payable: number;
  pending_cod_orders: number;
}

export interface Announcement {
  id: string;
  title: string;
  content: string;
  created_at: string;
  is_urgent: boolean;
}

export const dashboardService = {
  getWarehouseStats: async (): Promise<WarehouseStats> => {
    // try catch handled by axios interceptors
    const response = await axiosClient.get("/api/v1/dashboard/warehouse-stats");
    return response.data;
  },

  getFinanceStats: async (monthString?: string): Promise<FinanceStats> => {
    let params: any = {};
    if (monthString) {
      // monthString có dạng YYYY-MM (ví dụ 2026-06)
      const parts = monthString.split('-');
      if (parts.length === 2) {
        params = {
          year: parseInt(parts[0], 10),
          month: parseInt(parts[1], 10)
        };
      }
    }
    const response = await axiosClient.get("/api/v1/dashboard/finance-stats", { params });
    return response.data;
  },

  getAnnouncements: async (): Promise<Announcement[]> => {
    const response = await axiosClient.get("/api/v1/dashboard/announcements");
    return response.data;
  },
};
