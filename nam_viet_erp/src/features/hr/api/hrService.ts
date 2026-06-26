import axiosClient from "@/shared/utils/axiosClient";
import type { Employee, Shift, Payroll, CheckInResponse, KpiTargetPayload, KpiMetric, KpiProgressResponse, KpiTarget } from "../types/hrTypes";

export const hrService = {
  getEmployees: async (page: number = 1, pageSize: number = 10, departmentId?: string) => {
    const response = await axiosClient.get("/api/v1/hr/employees", {
      params: { page, page_size: pageSize, ...(departmentId ? { department_id: departmentId } : {}) },
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

  // --- KPI APIs ---

  /** Lấy danh sách chỉ số KPI (load động để hỗ trợ mở rộng tương lai) */
  getKpiMetrics: async (): Promise<KpiMetric[]> => {
    try {
      const response = await axiosClient.get("/api/v1/hr/kpi-metrics");
      return response.data;
    } catch {
      // Fallback cứng nếu API chưa sẵn sàng
      return [
        { code: "SALES_REVENUE", name: "Doanh thu bán hàng", unit: "VNĐ" },
        { code: "LOGISTICS_COD", name: "Tổng tiền thu hộ COD", unit: "VNĐ" },
        { code: "LOGISTICS_ORDER_COUNT", name: "Số đơn giao thành công", unit: "Đơn" },
      ];
    }
  },

  /** Giao KPI cho nhân viên — POST /api/v1/hr/kpi-targets */
  assignKpiTarget: async (payload: KpiTargetPayload): Promise<void> => {
    await axiosClient.post("/api/v1/hr/kpi-targets", payload);
  },

  /** Lấy tiến độ KPI cá nhân (dựa trên JWT) */
  getMyKpiProgress: async (month: number, year: number): Promise<KpiProgressResponse> => {
    const response = await axiosClient.get("/api/v1/hr/kpi-progress/me", {
      params: { month, year },
    });
    return response.data;
  },

  /** Lấy danh sách KPI đã giao cho 1 nhân viên (trên trang chi tiết) */
  getKpiTargetsByEmployee: async (employeeId: string, month: number, year: number): Promise<KpiTarget[]> => {
    const response = await axiosClient.get(`/api/v1/hr/kpi-targets`, {
      params: { employee_id: employeeId, month, year },
    });
    return response.data ?? [];
  },
};
