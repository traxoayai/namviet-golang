-- 1. Bảng Từ điển Chỉ số (Định nghĩa những gì công ty có thể đo lường)
CREATE TABLE IF NOT EXISTS public.hr_kpi_metrics (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    query_source TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Bảng Giao Chỉ Tiêu (Target)
CREATE TABLE IF NOT EXISTS public.hr_kpi_targets (
    id BIGSERIAL PRIMARY KEY,
    employee_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    month INT NOT NULL,
    year INT NOT NULL,
    metric_code TEXT NOT NULL REFERENCES public.hr_kpi_metrics(code) ON DELETE CASCADE,
    target_value NUMERIC NOT NULL,
    assigned_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Bảng Luật Trả Thưởng (Reward Rules)
CREATE TABLE IF NOT EXISTS public.hr_kpi_reward_rules (
    id BIGSERIAL PRIMARY KEY,
    metric_code TEXT NOT NULL REFERENCES public.hr_kpi_metrics(code) ON DELETE CASCADE,
    condition_type TEXT NOT NULL, -- '>=', '<=', '=='
    reward_type TEXT NOT NULL, -- 'PERCENTAGE', 'FIXED'
    reward_value NUMERIC NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Bổ sung trường department_id và permissions cho bảng users
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS department_id UUID, -- Giả sử department_id có thể trỏ tới 1 bảng departments, tạm thời để UUID
ADD COLUMN IF NOT EXISTS permissions JSONB DEFAULT '{}'::jsonb;

-- Seed dữ liệu mẫu cho Từ điển Chỉ số
INSERT INTO public.hr_kpi_metrics (code, name, description, query_source, is_active)
VALUES 
    ('SALES_REVENUE', 'Doanh thu bán hàng', 'Tổng doanh thu các đơn hàng thành công', 'calc_sales_revenue', true),
    ('LOGISTICS_COD', 'Tổng tiền thu hộ COD', 'Tổng tiền COD đã thu thành công', 'calc_logistics_cod', true),
    ('LOGISTICS_ORDER_COUNT', 'Số lượng đơn giao thành công', 'Số lượng đơn vận chuyển đã giao', 'calc_logistics_order_count', true)
ON CONFLICT (code) DO NOTHING;

-- Seed dữ liệu mẫu cho Reward Rules (tuỳ chọn, để test)
INSERT INTO public.hr_kpi_reward_rules (metric_code, condition_type, reward_type, reward_value)
VALUES
    ('SALES_REVENUE', '>=', 'PERCENTAGE', 5.0), -- Thưởng 5% nếu đạt hoặc vượt target doanh thu
    ('LOGISTICS_COD', '>=', 'PERCENTAGE', 1.0), -- Thưởng 1% trên tổng COD
    ('LOGISTICS_ORDER_COUNT', '>=', 'FIXED', 10000) -- Thưởng 10.000 VNĐ / đơn giao thành công
ON CONFLICT DO NOTHING;
