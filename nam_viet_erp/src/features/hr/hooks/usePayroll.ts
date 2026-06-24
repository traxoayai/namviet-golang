import { useMutation, useQueryClient } from "@tanstack/react-query";
import { hrService } from "../api/hrService";
import { message } from "antd";

export const useCalculatePayroll = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, month, year }: { id: string; month: number; year: number }) =>
      hrService.calculatePayroll(id, month, year),
    onSuccess: (data) => {
      message.success("Tính lương thành công!");
      queryClient.invalidateQueries({ queryKey: ["hr", "employee", data.user_id] });
    },
    onError: (error: any) => {
      const msg = error?.response?.data?.error || "Lỗi tính bảng lương";
      message.error(msg);
    },
  });
};
