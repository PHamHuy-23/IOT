import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_medical_profile.dart';
import '../models/user_settings.dart';

class ShareTokenInfo {
  final String token;
  final DateTime? expiresAt;

  const ShareTokenInfo({required this.token, this.expiresAt});
}

class UserProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Medical profile ────────────────────────────────────────

  Future<UserMedicalProfile> getMedicalProfile(String userId) async {
    final data = await _client
        .from('user_medical_profile')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return UserMedicalProfile.empty(userId);
    return UserMedicalProfile.fromMap(data);
  }

  Future<void> upsertMedicalProfile(UserMedicalProfile profile) async {
    await _client.from('user_medical_profile').upsert(profile.toMap());
  }

  // ── Settings ───────────────────────────────────────────────

  Future<UserSettings> getSettings(String userId) async {
    final data = await _client
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return UserSettings.defaults(userId);
    return UserSettings.fromMap(data);
  }

  Future<void> upsertSettings(UserSettings settings) async {
    await _client.from('user_settings').upsert(settings.toMap());
  }

  // ── Share token ────────────────────────────────────────────

  Future<ShareTokenInfo?> getOrCreateShareToken(String userId) async {
    final result = await _client.rpc('get_or_create_share_token', params: {
      'p_user_id': userId,
    });

    if (result == null || (result is List && result.isEmpty)) return null;

    final row = result is List ? result.first : result;
    final map = row as Map<String, dynamic>;
    return ShareTokenInfo(
      token: map['token'] as String,
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
    );
  }

  String buildShareUrl(String token) =>
      'https://health.iot.app/share/$token';
}
