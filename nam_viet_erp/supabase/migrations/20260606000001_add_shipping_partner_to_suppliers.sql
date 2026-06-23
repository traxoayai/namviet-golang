ALTER TABLE "public"."suppliers" 
ADD COLUMN "shipping_partner_id" bigint REFERENCES "public"."shipping_partners"("id") ON DELETE SET NULL;
