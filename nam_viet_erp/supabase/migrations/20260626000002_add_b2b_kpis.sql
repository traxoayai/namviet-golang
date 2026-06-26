-- Migration: 20260626000002_add_b2b_kpis.sql

-- 1. Add delivered_at to orders
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP WITH TIME ZONE;

-- 2. Add unit to hr_kpi_metrics
ALTER TABLE public.hr_kpi_metrics ADD COLUMN IF NOT EXISTS unit TEXT;

-- Update existing units
UPDATE public.hr_kpi_metrics SET unit = 'VNĐ' WHERE code = 'SALES_REVENUE';
UPDATE public.hr_kpi_metrics SET unit = 'VNĐ' WHERE code = 'LOGISTICS_COD';
UPDATE public.hr_kpi_metrics SET unit = 'Đơn' WHERE code = 'LOGISTICS_ORDER_COUNT';

-- 3. Insert new B2B and Logistics KPIs
INSERT INTO public.hr_kpi_metrics (code, name, description, query_source, unit, is_active)
VALUES 
    ('LOGISTICS_SLA_4H', 'Đạt SLA giao 4h', 'Tỷ lệ đơn hàng giao trong vòng 4 tiếng', 'calc_logistics_sla', '%', true),
    ('LOGISTICS_COD_48H', 'Thu COD trong 2 ngày', 'Tỷ lệ đơn COD được thu về và đối soát trong 48h', 'calc_logistics_cod_48h', '%', true),
    ('B2B_PAID_REVENUE', 'Doanh thu B2B (Đã thu)', 'Doanh thu các đơn hàng B2B phát sinh và đã thanh toán trong tháng', 'calc_b2b_paid_revenue', 'VNĐ', true),
    ('B2B_RETENTION', 'Tỷ lệ khách B2B quay lại', 'Tỷ lệ khách hàng mua hàng tháng này đã từng mua các tháng trước', 'calc_b2b_retention', '%', true),
    ('B2B_SURVEY_RATE', 'Tỷ lệ tham gia khảo sát', 'Tỷ lệ khách hàng B2B điền form khảo sát', 'calc_b2b_survey', '%', true),
    ('WH_MINMAX_COMPLIANCE', 'Tỷ lệ tồn kho chuẩn (Min/Max)', 'Tỷ lệ sản phẩm luôn duy trì tồn kho trong mức Min-Max an toàn', 'calc_wh_minmax', '%', true),
    ('WH_AGING_STOCK', 'Tỷ lệ tồn kho quá hạn (60 ngày)', 'Tỷ lệ hàng hoá nằm trong kho vượt quá 60 ngày', 'calc_wh_aging', '%', true),
    ('B2B_GROSS_MARGIN', 'Biên lợi nhuận gộp B2B', 'Tỷ suất lợi nhuận gộp trung bình của các đơn hàng B2B', 'calc_b2b_gross_margin', '%', true),
    ('B2B_DSO', 'Số ngày thu hồi nợ (DSO)', 'Số ngày trung bình để khách hàng thanh toán hết công nợ', 'calc_b2b_dso', 'Ngày', true),
    ('B2B_AOV', 'Giá trị trung bình 1 đơn (AOV)', 'Doanh thu trung bình trên mỗi đơn hàng B2B', 'calc_b2b_aov', 'VNĐ', true)
ON CONFLICT (code) DO NOTHING;
