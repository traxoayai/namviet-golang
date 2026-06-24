import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { marketingService } from "../api/marketingService";
import type { Campaign, Survey } from "../types/marketingTypes";
import { message } from "antd";

export const useCreateCampaign = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Campaign) => marketingService.createCampaign(data),
    onSuccess: () => {
      message.success("Tạo chiến dịch thành công!");
      queryClient.invalidateQueries({ queryKey: ["marketing", "campaigns"] });
    },
    onError: () => {
      message.error("Lỗi tạo chiến dịch!");
    },
  });
};

export const useStartCampaign = () => {
  return useMutation({
    mutationFn: (id: number) => marketingService.startCampaign(id),
    onSuccess: () => {
      message.success("Bắt đầu chiến dịch thành công!");
    },
    onError: () => {
      message.error("Lỗi chạy chiến dịch!");
    },
  });
};

export const useCampaignMetrics = (id?: number) => {
  return useQuery({
    queryKey: ["marketing", "campaign", id, "metrics"],
    queryFn: () => marketingService.getCampaignMetrics(id!),
    enabled: !!id,
  });
};

export const useSurveys = () => {
  return useQuery({
    queryKey: ["marketing", "surveys"],
    queryFn: () => marketingService.getSurveys(),
  });
};

export const useCreateSurvey = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Survey) => marketingService.createSurvey(data),
    onSuccess: () => {
      message.success("Tạo form khảo sát thành công!");
      queryClient.invalidateQueries({ queryKey: ["marketing", "surveys"] });
    },
    onError: () => {
      message.error("Lỗi tạo khảo sát!");
    },
  });
};
