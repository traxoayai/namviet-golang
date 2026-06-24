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
  commission?: number;
}

export interface Employee {
  id: string;
  email: string;
  full_name: string;
  employee_code: string;
  position: string;
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
