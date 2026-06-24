import axiosClient from "@/shared/utils/axiosClient";
import type { Employee, Shift, Payroll, CheckInResponse } from "../types/hrTypes";

export const hrService = {
  getEmployees: async (page: number = 1, pageSize: number = 10) => {
    const response = await axiosClient.get("/api/v1/hr/employees", {
      params: { page, page_size: pageSize },
    });
    return response.data;
  },

  getEmployeeDetail: async (id: string): Promise<Employee> => {
    const response = await axiosClient.get(`/api/v1/hr/employees/${id}`);
    return response.data;
  },

  registerShift: async (data: Shift): Promise<Shift> => {
    const response = await axiosClient.post("/api/v1/hr/shifts/register", data);
    return response.data;
  },

  checkIn: async (shiftId: number, lat: number, lng: number): Promise<CheckInResponse> => {
    const response = await axiosClient.post("/api/v1/hr/shifts/check-in", {
      shift_id: shiftId,
      lat,
      lng,
    });
    return response.data;
  },

  calculatePayroll: async (id: string, month: number, year: number): Promise<Payroll> => {
    const response = await axiosClient.post(`/api/v1/hr/employees/${id}/payroll/calculate`, {
      month,
      year,
    });
    return response.data;
  },
};
