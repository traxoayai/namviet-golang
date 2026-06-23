-- Migration: Add product_images array column to products table
-- Created by AI

ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS product_images TEXT[] DEFAULT '{}'::TEXT[];

COMMENT ON COLUMN public.products.product_images IS 'Mảng chứa các đường dẫn hình ảnh phụ của sản phẩm';
