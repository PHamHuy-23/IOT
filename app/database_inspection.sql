-- Database inspection script for Supabase/Postgres.
-- This script is read-only. Run each section in Supabase SQL Editor and share
-- the results if you want Codex to diagnose auth/schema/data issues.

-- 1) Current database context
select
  current_database() as database_name,
  current_schema() as current_schema,
  current_user as current_user,
  now() as inspected_at;

-- 2) Public tables and approximate row counts
select
  schemaname,
  relname as table_name,
  n_live_tup as approx_rows
from pg_stat_user_tables
where schemaname = 'public'
order by relname;

-- 3) Table columns, types, defaults, and nullable flags
select
  table_schema,
  table_name,
  ordinal_position,
  column_name,
  data_type,
  udt_name,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
order by table_name, ordinal_position;

-- 4) Primary keys, unique constraints, and foreign keys
select
  tc.table_schema,
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name,
  ccu.table_schema as foreign_table_schema,
  ccu.table_name as foreign_table_name,
  ccu.column_name as foreign_column_name
from information_schema.table_constraints tc
left join information_schema.key_column_usage kcu
  on tc.constraint_name = kcu.constraint_name
 and tc.table_schema = kcu.table_schema
left join information_schema.constraint_column_usage ccu
  on tc.constraint_name = ccu.constraint_name
 and tc.table_schema = ccu.table_schema
where tc.table_schema = 'public'
order by tc.table_name, tc.constraint_type, tc.constraint_name, kcu.ordinal_position;

-- 5) Indexes
select
  schemaname,
  tablename,
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
order by tablename, indexname;

-- 6) RLS status
select
  n.nspname as schemaname,
  c.relname as tablename,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind in ('r', 'p')
order by c.relname;

-- 7) RLS policies
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

-- 8) Public functions/RPCs
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  pg_get_function_result(p.oid) as returns,
  l.lanname as language,
  p.prosecdef as security_definer
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
join pg_language l on l.oid = p.prolang
where n.nspname = 'public'
order by p.proname, arguments;

-- 9) Triggers
select
  event_object_schema,
  event_object_table,
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
from information_schema.triggers
where event_object_schema = 'public'
order by event_object_table, trigger_name, event_manipulation;

-- 10) Extensions used by this database
select
  extname,
  extversion
from pg_extension
order by extname;

-- 11) Auth users summary.
-- If this fails due to permission, run it with a service-role/admin SQL session.
select
  id,
  email,
  email_confirmed_at is not null as email_confirmed,
  created_at,
  last_sign_in_at
from auth.users
order by created_at desc
limit 50;

-- 12) Compare Supabase Auth users with public.users profiles.
-- This is the most important section for "Invalid login credentials" and
-- "login succeeds but profile cannot load" issues.
select
  coalesce(au.id, pu.id) as user_id,
  au.email as auth_email,
  pu.email as public_email,
  pu.username,
  pu.display_name,
  pu.is_admin,
  pu.is_test_account,
  case
    when au.id is null then 'missing_in_auth_users'
    when pu.id is null then 'missing_in_public_users'
    when lower(au.email) <> lower(pu.email) then 'email_mismatch'
    else 'ok'
  end as status
from auth.users au
full outer join public.users pu on pu.id = au.id
order by status, public_email, auth_email;

-- 13) Public users sample.
-- Do not export password hashes to chat. This query intentionally does not
-- select password_hash.
select
  id,
  email,
  username,
  display_name,
  is_admin,
  is_test_account,
  avatar_color,
  created_at,
  updated_at
from public.users
order by created_at desc nulls last
limit 50;

-- 14) Health data counts per user
select
  u.id as user_id,
  u.email,
  u.username,
  count(hr.id) as health_record_count,
  min(hr.timestamp) as first_record_at,
  max(hr.timestamp) as last_record_at
from public.users u
left join public.health_records hr on hr.user_id = u.id
group by u.id, u.email, u.username
order by health_record_count desc, u.email;

-- 15) Daily summary counts per user
select
  u.id as user_id,
  u.email,
  u.username,
  count(ds.id) as daily_summary_count,
  min(ds.date) as first_summary_date,
  max(ds.date) as last_summary_date
from public.users u
left join public.daily_summary ds on ds.user_id = u.id
group by u.id, u.email, u.username
order by daily_summary_count desc, u.email;

-- 16) Family sharing overview if these tables exist.
select
  to_regclass('public.family_members') as family_members_table,
  to_regclass('public.family_relationships') as family_relationships_table,
  to_regclass('public.share_tokens') as share_tokens_table;

-- 17) Alert overview if these tables exist.
select
  to_regclass('public.health_alerts') as health_alerts_table,
  to_regclass('public.alert_recipients') as alert_recipients_table;
