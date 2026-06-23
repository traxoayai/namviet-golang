-- Fix: Delete portal users (customers) who were incorrectly given internal ERP roles
DELETE FROM public.user_roles 
WHERE user_id NOT IN (SELECT id FROM public.users);
