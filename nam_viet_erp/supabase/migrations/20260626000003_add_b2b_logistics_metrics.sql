-- Seed dữ liệu cho 10 Chỉ số KPI B2B, Logistics, Warehouse
INSERT INTO public.hr_kpi_metrics (code, name, description, query_source, is_active)
VALUES 
    ('LOGISTICS_SLA_4H', 'Tỷ lệ giao đúng hạn <= 4H', 'Tỷ lệ đơn giao thành công trong vòng 4 giờ', 'calc_logistics_sla_4h', true),
    ('LOGISTICS_COD_48H', 'Tỷ lệ nộp COD trong 48H', 'Tỷ lệ đơn COD nộp tiền trong 48 giờ sau khi giao', 'calc_logistics_cod_48h', true),
    ('B2B_PAID_REVENUE', 'Doanh thu B2B đã thu tiền', 'Tổng doanh thu các đơn B2B đã thanh toán', 'calc_b2b_paid_revenue', true),
    ('B2B_RETENTION', 'Tỷ lệ KH quay lại (B2B)', 'Tỷ lệ khách hàng mua lại so với tổng khách hàng', 'calc_b2b_retention', true),
    ('B2B_GROSS_MARGIN', 'Biên lợi nhuận gộp B2B', 'Tỷ lệ lợi nhuận gộp trên tổng doanh thu B2B', 'calc_b2b_gross_margin', true),
    ('B2B_DSO', 'Số ngày thu hồi nợ B2B', 'Số ngày trung bình để thu hồi công nợ B2B', 'calc_b2b_dso', true),
    ('B2B_AOV', 'Giá trị TB đơn hàng B2B', 'Giá trị trung bình trên mỗi đơn hàng B2B', 'calc_b2b_aov', true),
    ('WH_MINMAX_COMPLIANCE', 'Tỷ lệ tuân thủ tồn kho Min-Max', 'Tỷ lệ mã hàng tuân thủ quy định Min/Max trong kho', 'calc_wh_minmax', true),
    ('WH_AGING_STOCK', 'Tỷ lệ hàng tồn kho cũ', 'Tỷ lệ hàng tồn trong kho quá 60 ngày', 'calc_wh_aging_stock', true),
    ('B2B_SURVEY_RATE', 'Tỷ lệ khảo sát B2B', 'Tỷ lệ khách hàng B2B hoàn thành khảo sát', 'calc_b2b_survey_rate', true)
ON CONFLICT (code) DO NOTHING;
