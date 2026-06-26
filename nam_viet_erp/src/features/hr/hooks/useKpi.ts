import { useMutation, useQuery } from "@tanstack/react-query";
import { hrService } from "../api/hrService";
import { message } from "antd";
import type { KpiTargetPayload } from "../types/hrTypes";

/**
 * Hook giao KPI cho nhân viên (POST /api/v1/hr/kpi-targets)
 * Xử lý lỗi 403 Forbidden khi không đủ quyền hoặc nhân viên khác phòng.
 */
export const useAssignKpiTarget = () => {
  return useMutation({
    mutationFn: (payload: KpiTargetPayload) => hrService.assignKpiTarget(payload),
    onSuccess: () => {
      message.success("Giao chỉ tiêu KPI thành công!");
    },
    onError: (error: any) => {
      const status = error?.response?.status;
      if (status === 403) {
        message.error(
          "Bạn không có quyền giao chỉ tiêu, hoặc nhân sự này không thuộc phòng ban của bạn."
        );
      } else {
        const msg = error?.response?.data?.error || "Lỗi giao KPI. Vui lòng thử lại.";
        message.error(msg);
      }
    },
  });
};

/**
 * Hook load danh sách chỉ số KPI (dynamic, có fallback cứng)
 */
export const useKpiMetrics = () => {
  return useQuery({
    queryKey: ["hr", "kpi-metrics"],
    queryFn: () => hrService.getKpiMetrics(),
    staleTime: 5 * 60 * 1000, // cache 5 phút
  });
};

/**
 * Hook lấy tiến độ KPI cá nhân (dựa trên JWT token — không cần truyền employee_id)
 */
export const useMyKpiProgress = (month: number, year: number) => {
  return useQuery({
    queryKey: ["hr", "kpi-progress", "me", month, year],
    queryFn: () => hrService.getMyKpiProgress(month, year),
    retry: 1,
  });
};

/**
 * Hook lấy KPI đã giao cho một nhân viên cụ thể (dùng trên trang chi tiết nhân viên)
 */
export const useKpiTargetsByEmployee = (employeeId: string, month: number, year: number) => {
  return useQuery({
    queryKey: ["hr", "kpi-targets", employeeId, month, year],
    queryFn: () => hrService.getKpiTargetsByEmployee(employeeId, month, year),
    enabled: !!employeeId,
  });
};
