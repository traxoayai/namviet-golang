import axiosClient from "@/shared/utils/axiosClient";

export const financeCodService = {
  getPendingCodReports: async () => {
    const { data } = await axiosClient.get("/api/v1/finance/pending-cod-reports");
    return data;
  },

  confirmCodDeposit: async (shipper_user_id: string, transaction_ids: number[]) => {
    const { data } = await axiosClient.post("/api/v1/finance/confirm-cod-deposit", {
      shipper_user_id,
      transaction_ids,
    });
    return data;
  },
};
