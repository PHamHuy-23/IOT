-- Migration v5: support username login with Supabase Auth.
-- Run this after public.users has been migrated to mirror auth.users ids.

UPDATE public.users
SET username = 'vana'
WHERE username = 'vāna'
  AND NOT EXISTS (
    SELECT 1 FROM public.users existing WHERE existing.username = 'vana'
  );

CREATE OR REPLACE FUNCTION public.resolve_login_email(p_login text)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT u.email
  FROM public.users u
  WHERE lower(u.username) = lower(trim(p_login))
     OR lower(u.email) = lower(trim(p_login))
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.resolve_login_email(text) TO anon, authenticated;

-- Supabase Auth does not use public.users.password_hash.
-- Make sure every public.users row you want to log in with has a matching
-- Authentication user with the same email and password in Supabase Auth.
