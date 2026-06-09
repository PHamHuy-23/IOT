-- Migration v2: medical profile, share tokens, user settings, health RPCs
-- Chạy file này trong Supabase SQL Editor

-- ══════════════════════════════════════════════════════════════
-- 1. BẢNG MỚI
-- ══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS user_medical_profile (
  user_id           uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  blood_type        text,
  height_cm         integer,
  weight_kg         numeric(5,1),
  allergies         text,
  emergency_contact text,
  updated_at        timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS share_tokens (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token       text UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(16), 'hex'),
  expires_at  timestamptz,
  is_active   boolean DEFAULT true,
  created_at  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_share_tokens_user ON share_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_share_tokens_token ON share_tokens(token);

CREATE TABLE IF NOT EXISTS user_settings (
  user_id        uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  push_enabled   boolean DEFAULT true,
  health_alerts  boolean DEFAULT true,
  data_sharing   boolean DEFAULT false,
  biometric_lock boolean DEFAULT false,
  updated_at     timestamptz DEFAULT now()
);

-- ══════════════════════════════════════════════════════════════
-- 2. RLS — permissive (app dùng custom auth, không Supabase Auth JWT)
-- ══════════════════════════════════════════════════════════════

ALTER TABLE user_medical_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE share_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "app_access_medical" ON user_medical_profile;
CREATE POLICY "app_access_medical" ON user_medical_profile
  FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "app_access_share" ON share_tokens;
CREATE POLICY "app_access_share" ON share_tokens
  FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "app_access_settings" ON user_settings;
CREATE POLICY "app_access_settings" ON user_settings
  FOR ALL USING (true) WITH CHECK (true);

-- Health records: thêm policy cho custom auth (nếu chưa có)
DROP POLICY IF EXISTS "app_insert_health" ON health_records;
CREATE POLICY "app_insert_health" ON health_records
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "app_select_health" ON health_records;
CREATE POLICY "app_select_health" ON health_records
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "app_delete_health" ON health_records;
CREATE POLICY "app_delete_health" ON health_records
  FOR DELETE USING (true);

DROP POLICY IF EXISTS "app_select_summary" ON daily_summary;
CREATE POLICY "app_select_summary" ON daily_summary
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "app_delete_summary" ON daily_summary;
CREATE POLICY "app_delete_summary" ON daily_summary
  FOR DELETE USING (true);

-- ══════════════════════════════════════════════════════════════
-- 3. RPC — lưu health record (SECURITY DEFINER)
-- ══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION insert_health_record(
  p_user_id     uuid,
  p_heart_rate  integer,
  p_spo2        integer,
  p_timestamp   timestamptz DEFAULT now()
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  IF p_heart_rate <= 0 OR p_spo2 <= 0 OR p_spo2 > 100 THEN
    RAISE EXCEPTION 'Invalid health data';
  END IF;
  INSERT INTO health_records (user_id, heart_rate, spo2, timestamp)
  VALUES (p_user_id, p_heart_rate, p_spo2, p_timestamp);
END;
$$;

-- Xóa toàn bộ dữ liệu sức khỏe của user
CREATE OR REPLACE FUNCTION delete_user_health_data(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  DELETE FROM health_records WHERE user_id = p_user_id;
  DELETE FROM daily_summary WHERE user_id = p_user_id;
END;
$$;

-- Lấy hoặc tạo share token
CREATE OR REPLACE FUNCTION get_or_create_share_token(p_user_id uuid)
RETURNS TABLE(token text, expires_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_token text;
  v_expires timestamptz;
BEGIN
  SELECT st.token, st.expires_at
  INTO v_token, v_expires
  FROM share_tokens st
  WHERE st.user_id = p_user_id
    AND st.is_active = true
    AND (st.expires_at IS NULL OR st.expires_at > now())
  ORDER BY st.created_at DESC
  LIMIT 1;

  IF v_token IS NULL THEN
    v_expires := now() + interval '24 hours';
    INSERT INTO share_tokens (user_id, expires_at)
    VALUES (p_user_id, v_expires)
    RETURNING share_tokens.token, share_tokens.expires_at
    INTO v_token, v_expires;
  END IF;

  RETURN QUERY SELECT v_token, v_expires;
END;
$$;
