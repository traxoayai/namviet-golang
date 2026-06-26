-- Migration: 20260626000001_add_hr_permissions.sql

INSERT INTO public.permissions (key, name, module)
VALUES
  ('hr.assign_kpi', 'Giao chỉ tiêu KPI', 'hr')
ON CONFLICT (key) DO NOTHING;
