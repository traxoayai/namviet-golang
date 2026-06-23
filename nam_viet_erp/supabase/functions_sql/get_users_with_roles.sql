CREATE OR REPLACE FUNCTION public.get_users_with_roles()
 RETURNS TABLE(key text, id uuid, name text, email text, avatar text, status text, assignments jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    a_user.id::TEXT AS key,
    a_user.id,
    p_user.full_name AS name,
    a_user.email::TEXT AS email,
    p_user.avatar_url AS avatar,
    p_user.status::TEXT AS status,
    (
      SELECT jsonb_agg(jsonb_build_object(
        'branchId', w.id,
        'branchName', w.name,
        'roleId', r.id,
        'roleName', r.name
      ))
      FROM public.user_roles ur
      JOIN public.roles r ON ur.role_id = r.id
      JOIN public.warehouses w ON ur.branch_id = w.id
      WHERE ur.user_id = a_user.id
    ) AS assignments
  FROM auth.users AS a_user
  LEFT JOIN public.users AS p_user ON a_user.id = p_user.id
  WHERE NOT EXISTS (
    SELECT 1 FROM public.portal_users pu WHERE pu.auth_user_id = a_user.id
  )
  AND NOT EXISTS (
    SELECT 1 FROM public.registration_requests rr WHERE rr.auth_user_id = a_user.id
  );
END;
$function$
