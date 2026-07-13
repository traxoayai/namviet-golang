ALTER TABLE "public"."finance_transactions"
ADD CONSTRAINT "finance_transactions_created_by_fkey"
FOREIGN KEY ("created_by") REFERENCES "public"."users" ("id");
