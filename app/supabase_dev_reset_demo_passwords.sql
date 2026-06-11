-- DEV ONLY: reset demo/seed Supabase Auth passwords to 123456.
-- Use this only for your school/demo project, not production.
--
-- Why this exists:
-- public.users.password_hash is not used by Supabase Auth. If auth.users rows
-- were migrated/created without the expected password hash, signInWithPassword
-- returns "Invalid login credentials" even when public.users matches auth.users.

begin;

update auth.users
set
  encrypted_password = crypt('123456', gen_salt('bf')),
  email_confirmed_at = coalesce(email_confirmed_at, now()),
  confirmation_sent_at = null,
  recovery_sent_at = null,
  updated_at = now()
where lower(email) in (
  'admin@health.app',
  'demo@health.app',
  'testing@example.com',
  'nguyenvana@example.com',
  'lethib@example.com',
  'tranvanc@example.com'
);

select
  id,
  email,
  email_confirmed_at is not null as email_confirmed,
  updated_at
from auth.users
where lower(email) in (
  'admin@health.app',
  'demo@health.app',
  'testing@example.com',
  'nguyenvana@example.com',
  'lethib@example.com',
  'tranvanc@example.com'
)
order by email;

commit;

-- After running this, these logins should work:
-- admin / 123456
-- user1 / 123456
-- testing / 123456
-- vana / 123456
-- lethib / 123456
-- tranvanc / 123456
