-- Add sales_permissions column to customers_b2b
ALTER TABLE public.customers_b2b 
ADD COLUMN IF NOT EXISTS sales_permissions text[] DEFAULT '{}'::text[];

-- Add a comment to describe it
COMMENT ON COLUMN public.customers_b2b.sales_permissions IS 'Quyền bán thuốc của cơ sở B2B (VD: {"rx", "essential", "narcotic", "psychotropic"})';
