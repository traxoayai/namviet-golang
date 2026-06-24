import { useQuery } from "@tanstack/react-query";
import { hrService } from "../api/hrService";
import type { Employee } from "../types/hrTypes";

export const useEmployees = (page: number = 1, pageSize: number = 10) => {
  return useQuery({
    queryKey: ["hr", "employees", page, pageSize],
    queryFn: () => hrService.getEmployees(page, pageSize),
    placeholderData: (prev) => prev,
  });
};

export const useEmployeeDetail = (id: string) => {
  return useQuery<Employee>({
    queryKey: ["hr", "employee", id],
    queryFn: () => hrService.getEmployeeDetail(id),
    enabled: !!id,
  });
};
