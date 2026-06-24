import axiosClient from "@/shared/utils/axiosClient";
import type { Campaign, CampaignMetrics, Survey } from "../types/marketingTypes";

export const marketingService = {
  createCampaign: async (data: Campaign): Promise<Campaign> => {
    const response = await axiosClient.post("/api/v1/marketing/campaigns", data);
    return response.data;
  },

  startCampaign: async (id: number): Promise<void> => {
    await axiosClient.post(`/api/v1/marketing/campaigns/${id}/start`);
  },

  getCampaignMetrics: async (id: number): Promise<CampaignMetrics> => {
    const response = await axiosClient.get(`/api/v1/marketing/campaigns/${id}/metrics`);
    return response.data;
  },

  createSurvey: async (data: Survey): Promise<Survey> => {
    const response = await axiosClient.post("/api/v1/marketing/surveys", data);
    return response.data;
  },

  getSurveys: async (): Promise<Survey[]> => {
    const response = await axiosClient.get("/api/v1/marketing/surveys");
    return response.data;
  },
};
