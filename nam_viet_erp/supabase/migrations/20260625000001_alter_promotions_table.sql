-- Migration: 20260625000001_alter_promotions_table.sql

ALTER TABLE public.promotions
ADD COLUMN IF NOT EXISTS promotion_class varchar(50) DEFAULT 'basic',
ADD COLUMN IF NOT EXISTS advanced_rules jsonb;
