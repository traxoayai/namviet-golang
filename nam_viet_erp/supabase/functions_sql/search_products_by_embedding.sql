CREATE OR REPLACE FUNCTION public.search_products_by_embedding(p_query_embedding vector, p_match_count integer DEFAULT 5, p_min_similarity double precision DEFAULT 0.3)
 RETURNS TABLE(product_id integer, product_name text, sku text, similarity double precision)
 LANGUAGE sql
 STABLE
AS $function$
  select
    p.id as product_id,
    p.name as product_name,
    p.sku,
    1 - (pe.embedding <=> p_query_embedding) as similarity
  from public.product_embeddings pe
  join public.products p on p.id = pe.product_id
  where p.status = 'active'
    and (1 - (pe.embedding <=> p_query_embedding)) >= p_min_similarity
  order by pe.embedding <=> p_query_embedding
  limit p_match_count;
$function$
