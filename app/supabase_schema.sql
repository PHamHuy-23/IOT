-- Enable the pgcrypto extension for UUID generation
create extension if not exists "pgcrypto";

-- Users table
create table users (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  username text unique not null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Health records table (raw data from sensors)
create table health_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  heart_rate integer not null check (heart_rate > 0),
  spo2 integer not null check (spo2 >= 0 and spo2 <= 100),
  timestamp timestamp with time zone not null,
  created_at timestamp with time zone default now(),

  constraint valid_data check (heart_rate > 0 and spo2 > 0)
);

-- Daily summary table (aggregated data)
create table daily_summary (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  date date not null,

  -- Heart rate statistics
  avg_heart_rate integer,
  min_heart_rate integer,
  max_heart_rate integer,
  total_heart_rate_records integer default 0,

  -- SpO2 statistics
  avg_spo2 integer,
  min_spo2 integer,
  max_spo2 integer,
  total_spo2_records integer default 0,

  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),

  unique(user_id, date)
);

-- Create indexes for better query performance
create index idx_health_records_user_id on health_records(user_id);
create index idx_health_records_timestamp on health_records(timestamp);
create index idx_health_records_user_timestamp on health_records(user_id, timestamp desc);
create index idx_daily_summary_user_id on daily_summary(user_id);
create index idx_daily_summary_date on daily_summary(date desc);
create index idx_daily_summary_user_date on daily_summary(user_id, date desc);

-- Enable Row Level Security (RLS)
alter table users enable row level security;
alter table health_records enable row level security;
alter table daily_summary enable row level security;

-- RLS Policies for users table
create policy "Users can view their own profile"
  on users for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on users for update
  using (auth.uid() = id);

-- RLS Policies for health_records table
create policy "Users can view their own health records"
  on health_records for select
  using (auth.uid() = user_id);

create policy "Users can insert their own health records"
  on health_records for insert
  with check (auth.uid() = user_id);

-- RLS Policies for daily_summary table
create policy "Users can view their own daily summary"
  on daily_summary for select
  using (auth.uid() = user_id);

-- Function to automatically update daily summary when new health records are inserted
create or replace function update_daily_summary()
returns trigger as $$
declare
  summary_date date;
  v_avg_hr integer;
  v_min_hr integer;
  v_max_hr integer;
  v_count_hr integer;
  v_avg_spo2 integer;
  v_min_spo2 integer;
  v_max_spo2 integer;
  v_count_spo2 integer;
begin
  summary_date := date(new.timestamp);

  -- Calculate heart rate statistics
  select
    round(avg(heart_rate))::integer,
    min(heart_rate),
    max(heart_rate),
    count(*)
  into v_avg_hr, v_min_hr, v_max_hr, v_count_hr
  from health_records
  where user_id = new.user_id
    and date(timestamp) = summary_date
    and heart_rate > 0;

  -- Calculate SpO2 statistics
  select
    round(avg(spo2))::integer,
    min(spo2),
    max(spo2),
    count(*)
  into v_avg_spo2, v_min_spo2, v_max_spo2, v_count_spo2
  from health_records
  where user_id = new.user_id
    and date(timestamp) = summary_date
    and spo2 > 0;

  -- Insert or update daily summary
  insert into daily_summary (
    user_id, date, avg_heart_rate, min_heart_rate, max_heart_rate,
    total_heart_rate_records, avg_spo2, min_spo2, max_spo2, total_spo2_records
  ) values (
    new.user_id, summary_date, v_avg_hr, v_min_hr, v_max_hr, v_count_hr,
    v_avg_spo2, v_min_spo2, v_max_spo2, v_count_spo2
  )
  on conflict (user_id, date) do update set
    avg_heart_rate = v_avg_hr,
    min_heart_rate = v_min_hr,
    max_heart_rate = v_max_hr,
    total_heart_rate_records = v_count_hr,
    avg_spo2 = v_avg_spo2,
    min_spo2 = v_min_spo2,
    max_spo2 = v_max_spo2,
    total_spo2_records = v_count_spo2,
    updated_at = now();

  return new;
end;
$$ language plpgsql;

-- Trigger to call the function after each insert
create trigger health_records_insert_trigger
  after insert on health_records
  for each row
  execute function update_daily_summary();

-- Function to delete records older than 1 year
create or replace function delete_old_records()
returns void as $$
begin
  delete from health_records
  where created_at < now() - interval '1 year';

  delete from daily_summary
  where created_at < now() - interval '1 year';
end;
$$ language plpgsql;



-- =========================================================================
-- 1. CHÈN DỮ LIỆU MẪU CHO BẢNG USERS
-- Tạo ra 3 người dùng mẫu
-- =========================================================================
INSERT INTO users (id, email, username) VALUES 
('a1111111-1111-1111-1111-111111111111', 'nguyenvana@example.com', 'vāna'),
('b2222222-2222-2222-2222-222222222222', 'lethib@example.com', 'lethib'),
('c3333333-3333-3333-3333-333333333333', 'tranvanc@example.com', 'tranvanc')
ON CONFLICT (id) DO NOTHING;


-- =========================================================================
-- 2. CHÈN DỮ LIỆU MẪU CHO BẢNG HEALTH_RECORDS
-- Giả lập dữ liệu đo sức khỏe trong 2 ngày gần đây cho các user.
-- Các giá trị tuân thủ ràng buộc: heart_rate > 0 và spo2 từ 1 đến 100.
-- =========================================================================
INSERT INTO health_records (user_id, heart_rate, spo2, timestamp) VALUES

-- --- Người dùng A (Nguyễn Văn A) ---
-- Ngày hôm qua (Giả định đo cách nhau vài tiếng)
('a1111111-1111-1111-1111-111111111111', 72, 98, NOW() - INTERVAL '1 day' - INTERVAL '8 hour'),
('a1111111-1111-1111-1111-111111111111', 85, 97, NOW() - INTERVAL '1 day' - INTERVAL '4 hour'),
('a1111111-1111-1111-1111-111111111111', 68, 99, NOW() - INTERVAL '1 day'),
-- Ngày hôm nay
('a1111111-1111-1111-1111-111111111111', 75, 98, NOW() - INTERVAL '2 hour'),
('a1111111-1111-1111-1111-111111111111', 110, 96, NOW() - INTERVAL '1 hour'), -- Lúc này có thể đang vận động
('a1111111-1111-1111-1111-111111111111', 78, 99, NOW()),

-- --- Người dùng B (Lê Thị B) ---
-- Ngày hôm qua
('b2222222-2222-2222-2222-222222222222', 65, 99, NOW() - INTERVAL '1 day' - INTERVAL '6 hour'),
('b2222222-2222-2222-2222-222222222222', 70, 98, NOW() - INTERVAL '1 day' - INTERVAL '2 hour'),
-- Ngày hôm nay
('b2222222-2222-2222-2222-222222222222', 68, 100, NOW() - INTERVAL '3 hour'),
('b2222222-2222-2222-2222-222222222222', 72, 99, NOW()),

-- --- Người dùng C (Trần Văn C) ---
-- Ngày hôm nay (Chỉ có dữ liệu ngày hôm nay)
('c3333333-3333-3333-3333-333333333333', 80, 95, NOW() - INTERVAL '5 hour'),
('c3333333-3333-3333-3333-333333333333', 88, 94, NOW() - INTERVAL '3 hour'),
('c3333333-3333-3333-3333-333333333333', 82, 96, NOW());


-- 1. Thêm cột password_hash vào bảng users
ALTER TABLE users ADD COLUMN password_hash TEXT;

-- 2. Cập nhật mật khẩu mẫu là '123456' cho cả 3 user (sử dụng mã hóa bcrypt)
UPDATE users 
SET password_hash = crypt('123456', gen_salt('bf'))
WHERE username IN ('vāna', 'lethib', 'tranvanc');

-- 3. Cột profile (đã có trên Supabase production)
ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin boolean NOT NULL DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_color text;

-- 4. Bảng mở rộng — xem chi tiết trong supabase_migration_v2.sql
--    user_medical_profile, share_tokens, user_settings
--    + RPC: insert_health_record, delete_user_health_data, get_or_create_share_token