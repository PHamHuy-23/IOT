-- Migration v3: Chia sẻ gia đình qua QR (trong app, không cần web)
-- Chạy sau supabase_migration_v2.sql

-- ══════════════════════════════════════════════════════════════
-- 1. Bảng liên kết chủ thiết bị ↔ người thân
-- ══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS family_members (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  member_user_id  uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  share_token_id  uuid REFERENCES share_tokens(id) ON DELETE SET NULL,
  joined_at       timestamptz DEFAULT now(),
  is_active       boolean DEFAULT true,
  UNIQUE(owner_user_id, member_user_id),
  CHECK (owner_user_id <> member_user_id)
);

CREATE INDEX IF NOT EXISTS idx_family_owner ON family_members(owner_user_id)
  WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_family_member ON family_members(member_user_id)
  WHERE is_active = true;

ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "app_access_family" ON family_members;
CREATE POLICY "app_access_family" ON family_members
  FOR ALL USING (true) WITH CHECK (true);

-- Gia hạn mã QR mời lên 7 ngày
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
    v_expires := now() + interval '7 days';
    INSERT INTO share_tokens (user_id, expires_at)
    VALUES (p_user_id, v_expires)
    RETURNING share_tokens.token, share_tokens.expires_at
    INTO v_token, v_expires;
  END IF;

  RETURN QUERY SELECT v_token, v_expires;
END;
$$;

-- Người thân quét QR → tham gia theo dõi
CREATE OR REPLACE FUNCTION join_family_share(
  p_member_user_id uuid,
  p_token          text
) RETURNS TABLE(
  owner_id           uuid,
  owner_display_name text,
  owner_username     text
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_owner_id   uuid;
  v_token_id   uuid;
BEGIN
  SELECT st.user_id, st.id
  INTO v_owner_id, v_token_id
  FROM share_tokens st
  LEFT JOIN user_settings us ON us.user_id = st.user_id
  WHERE st.token = p_token
    AND st.is_active = true
    AND (st.expires_at IS NULL OR st.expires_at > now())
    AND COALESCE(us.data_sharing, false) = true;

  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'Mã QR không hợp lệ hoặc đã hết hạn';
  END IF;

  IF v_owner_id = p_member_user_id THEN
    RAISE EXCEPTION 'Không thể theo dõi chính mình';
  END IF;

  INSERT INTO family_members (owner_user_id, member_user_id, share_token_id)
  VALUES (v_owner_id, p_member_user_id, v_token_id)
  ON CONFLICT (owner_user_id, member_user_id) DO UPDATE SET
    is_active = true,
    joined_at = now(),
    share_token_id = EXCLUDED.share_token_id;

  RETURN QUERY
  SELECT u.id, COALESCE(u.display_name, u.username), u.username
  FROM users u WHERE u.id = v_owner_id;
END;
$$;

-- Chủ thiết bị: danh sách người thân đã kết nối
CREATE OR REPLACE FUNCTION get_family_members(p_owner_user_id uuid)
RETURNS TABLE(
  member_id           uuid,
  member_display_name text,
  member_username     text,
  joined_at           timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT u.id, COALESCE(u.display_name, u.username), u.username, fm.joined_at
  FROM family_members fm
  JOIN users u ON u.id = fm.member_user_id
  WHERE fm.owner_user_id = p_owner_user_id AND fm.is_active = true
  ORDER BY fm.joined_at DESC;
END;
$$;

-- Người thân: danh sách người đang chia sẻ cho mình
CREATE OR REPLACE FUNCTION get_shared_with_me(p_member_user_id uuid)
RETURNS TABLE(
  owner_id           uuid,
  owner_display_name text,
  owner_username     text,
  joined_at          timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT u.id, COALESCE(u.display_name, u.username), u.username, fm.joined_at
  FROM family_members fm
  JOIN users u ON u.id = fm.owner_user_id
  WHERE fm.member_user_id = p_member_user_id AND fm.is_active = true
  ORDER BY fm.joined_at DESC;
END;
$$;

-- Chủ thiết bị thu hồi quyền
CREATE OR REPLACE FUNCTION revoke_family_member(
  p_owner_user_id  uuid,
  p_member_user_id uuid
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  UPDATE family_members
  SET is_active = false
  WHERE owner_user_id = p_owner_user_id
    AND member_user_id = p_member_user_id;
END;
$$;

-- Người thân rời khỏi theo dõi
CREATE OR REPLACE FUNCTION leave_family_share(
  p_member_user_id uuid,
  p_owner_user_id  uuid
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  UPDATE family_members
  SET is_active = false
  WHERE owner_user_id = p_owner_user_id
    AND member_user_id = p_member_user_id;
END;
$$;
