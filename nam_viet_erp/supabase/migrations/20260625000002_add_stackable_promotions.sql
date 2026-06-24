-- Migration for Stackable Promotions
ALTER TABLE promotions
ADD COLUMN IF NOT EXISTS is_stackable BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS promo_group VARCHAR(20) DEFAULT 'cash',
ADD COLUMN IF NOT EXISTS combinable_groups JSONB DEFAULT '[]'::jsonb;
