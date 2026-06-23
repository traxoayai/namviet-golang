CREATE OR REPLACE FUNCTION public.recalculate_final_amount()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
        NEW.final_amount := NEW.total_goods_amount - NEW.discount_order + NEW.shipping_fee + NEW.other_fee;
        RETURN NEW;
    END;
    $function$
