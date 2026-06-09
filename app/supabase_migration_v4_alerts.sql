-- Migration v4: Cảnh báo sức khỏe + té ngã + tài khoản mô phỏng
-- Chạy sau migration v2 và v3

ALTER TABLE users ADD COLUMN IF NOT EXISTS is_test_account boolean NOT NULL DEFAULT false;

-- ══════════════════════════════════════════════════════════════
-- Bảng cảnh báo
-- ══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS health_alerts (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  alert_type      text NOT NULL,
  severity        text NOT NULL DEFAULT 'warning',
  heart_rate      integer,
  spo2            integer,
  message         text NOT NULL,
  is_simulated    boolean DEFAULT false,
  acknowledged    boolean DEFAULT false,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_health_alerts_owner ON health_alerts(owner_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_health_alerts_created ON health_alerts(created_at DESC);

ALTER TABLE health_alerts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "app_access_alerts" ON health_alerts;
CREATE POLICY "app_access_alerts" ON health_alerts
  FOR ALL USING (true) WITH CHECK (true);

-- Tạo cảnh báo (gọi từ app khi chỉ số bất thường / té ngã)
CREATE OR REPLACE FUNCTION create_health_alert(
  p_owner_user_id uuid,
  p_alert_type    text,
  p_severity      text,
  p_heart_rate    integer DEFAULT NULL,
  p_spo2          integer DEFAULT NULL,
  p_message       text DEFAULT '',
  p_is_simulated  boolean DEFAULT false
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  INSERT INTO health_alerts (
    owner_user_id, alert_type, severity,
    heart_rate, spo2, message, is_simulated
  ) VALUES (
    p_owner_user_id, p_alert_type, p_severity,
    p_heart_rate, p_spo2, p_message, p_is_simulated
  ) RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

-- Cảnh báo của chính mình (chủ thiết bị)
CREATE OR REPLACE FUNCTION get_my_alerts(
  p_owner_user_id uuid,
  p_limit         integer DEFAULT 50
) RETURNS TABLE(
  id uuid, alert_type text, severity text,
  heart_rate integer, spo2 integer, message text,
  is_simulated boolean, acknowledged boolean, created_at timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT ha.id, ha.alert_type, ha.severity,
         ha.heart_rate, ha.spo2, ha.message,
         ha.is_simulated, ha.acknowledged, ha.created_at
  FROM health_alerts ha
  WHERE ha.owner_user_id = p_owner_user_id
  ORDER BY ha.created_at DESC
  LIMIT p_limit;
END;
$$;

-- Cảnh báo từ người thân đang theo dõi (cho tài khoản member)
CREATE OR REPLACE FUNCTION get_family_alerts(
  p_member_user_id uuid,
  p_since          timestamptz DEFAULT now() - interval '24 hours'
) RETURNS TABLE(
  id uuid, owner_id uuid, owner_display_name text,
  alert_type text, severity text,
  heart_rate integer, spo2 integer, message text,
  is_simulated boolean, created_at timestamptz
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT ha.id, u.id, COALESCE(u.display_name, u.username),
         ha.alert_type, ha.severity,
         ha.heart_rate, ha.spo2, ha.message,
         ha.is_simulated, ha.created_at
  FROM health_alerts ha
  JOIN family_members fm
    ON fm.owner_user_id = ha.owner_user_id
   AND fm.member_user_id = p_member_user_id
   AND fm.is_active = true
  JOIN users u ON u.id = ha.owner_user_id
  LEFT JOIN user_settings us ON us.user_id = fm.owner_user_id
  WHERE ha.created_at >= p_since
    AND COALESCE(us.data_sharing, false) = true
  ORDER BY ha.created_at DESC;
END;
$$;

-- Đánh dấu đã xem
CREATE OR REPLACE FUNCTION acknowledge_alert(
  p_alert_id uuid,
  p_user_id  uuid
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  UPDATE health_alerts
  SET acknowledged = true
  WHERE id = p_alert_id
    AND (owner_user_id = p_user_id OR EXISTS (
      SELECT 1 FROM family_members fm
      WHERE fm.owner_user_id = health_alerts.owner_user_id
        AND fm.member_user_id = p_user_id
        AND fm.is_active = true
    ));
END;
$$;

-- ══════════════════════════════════════════════════════════════
-- Gán tài khoản mô phỏng (chỉnh email/username cho đúng DB của bạn)
-- ══════════════════════════════════════════════════════════════
-- UPDATE users SET is_admin = true WHERE username = 'admin';
-- UPDATE users SET is_test_account = true WHERE username = 'testing';
