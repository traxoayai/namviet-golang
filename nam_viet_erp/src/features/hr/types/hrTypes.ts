export interface Contract {
  id: number;
  contract_type: string;
  base_salary: number;
  start_date: string;
  status: string;
}

export interface Payroll {
  id: number;
  month: number;
  year: number;
  total_salary: number;
  status: string;
  user_id?: string;
  base_salary?: number;
  kpi_bonus?: number;
  kpi_bonus_note?: string;
  commission?: number;
  commission_note?: string;
}

export interface Employee {
  id: string;
  email: string;
  full_name: string;
  employee_code: string;
  position: string;
  department_id?: string;
  contracts?: Contract[];
  payrolls?: Payroll[];
}

export interface Shift {
  id?: number;
  shift_name: string;
  date: string;
  start_time: string;
  end_time: string;
}

export interface CheckInResponse {
  message: string;
  distance: number;
  is_valid: boolean;
}

// --- KPI Types ---
export interface KpiMetric {
  code: string;       // VD: "SALES_REVENUE"
  name: string;       // VD: "Doanh thu bán hàng"
  unit: string;       // VD: "VNĐ" | "Số đếm"
  description?: string;
}

export interface KpiTargetPayload {
  employee_id: string;
  month: number;
  year: number;
  metric_code: string;
  target_value: number;
}

export interface KpiTarget {
  id?: string;
  employee_id: string;
  employee_name?: string;
  month: number;
  year: number;
  metric_code: string;
  metric_name?: string;
  target_value: number;
  actual_value?: number;
  unit?: string;
}

export interface KpiProgressItem {
  metric_code: string;
  metric_name: string;
  target_value: number;
  actual_value: number;
  percent: number;
  unit: string;
}

export interface KpiProgressResponse {
  month: number;
  year: number;
  items: KpiProgressItem[];
}
