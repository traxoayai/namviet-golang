-- Migration: 20260625000003_relax_promotions_discount_type_check.sql

ALTER TABLE public.promotions ALTER COLUMN discount_type DROP NOT NULL;
ALTER TABLE public.promotions DROP CONSTRAINT IF EXISTS promotions_discount_type_check;
ALTER TABLE public.promotions ADD CONSTRAINT promotions_discount_type_check CHECK (discount_type IN ('percent', 'fixed', 'fixed_amount', 'advanced') OR discount_type IS NULL);
