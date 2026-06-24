import { useMutation, useQueryClient } from "@tanstack/react-query";
import { hrService } from "../api/hrService";
import type { Shift } from "../types/hrTypes";
import { message } from "antd";

export const useRegisterShift = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: Shift) => hrService.registerShift(data),
    onSuccess: () => {
      message.success("Đăng ký ca làm thành công!");
      queryClient.invalidateQueries({ queryKey: ["hr", "shifts"] });
    },
    onError: (error: any) => {
      const msg = error?.response?.data?.error || "Lỗi đăng ký ca làm";
      message.error(msg);
    },
  });
};

export const useCheckIn = () => {
  return useMutation({
    mutationFn: ({ shiftId, lat, lng }: { shiftId: number; lat: number; lng: number }) =>
      hrService.checkIn(shiftId, lat, lng),
    onSuccess: (data) => {
      if (data.is_valid) {
        message.success(`Check-in thành công! (Khoảng cách: ${data.distance.toFixed(1)}m)`);
      } else {
        message.warning(`Check-in thành công nhưng sai vị trí! (Khoảng cách: ${data.distance.toFixed(1)}m)`);
      }
    },
    onError: () => {
      message.error("Lỗi chấm công!");
    },
  });
};
