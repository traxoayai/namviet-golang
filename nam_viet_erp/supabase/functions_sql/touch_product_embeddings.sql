CREATE OR REPLACE FUNCTION public.touch_product_embeddings()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();
  return new;
end$function$
