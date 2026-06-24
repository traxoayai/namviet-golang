import axiosClient from "@/shared/utils/axiosClient";

export const logisticsService = {
  markCodPaid: async (orderId: string) => {
    const { data } = await axiosClient.post("/api/v1/logistics/mark-cod-paid", {
      order_id: orderId,
    });
    return data;
  },

  rollbackCod: async (orderId: string) => {
    const { data } = await axiosClient.post("/api/v1/logistics/rollback-cod", {
      order_id: orderId,
    });
    return data;
  },
};
