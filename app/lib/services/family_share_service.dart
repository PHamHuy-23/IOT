import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_member.dart';

/// Payload QR: IOT_HEALTH:JOIN:<token>
class FamilyShareService {
  static const String qrPrefix = 'IOT_HEALTH:JOIN:';

  final SupabaseClient _client = Supabase.instance.client;

  String buildQrPayload(String token) => '$qrPrefix$token';

  String? parseTokenFromQr(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith(qrPrefix)) {
      return trimmed.substring(qrPrefix.length);
    }
    // Hỗ trợ mã cũ dạng URL
    if (trimmed.contains('/share/')) {
      return trimmed.split('/share/').last.split('?').first;
    }
    return null;
  }

  Future<FamilyConnection> joinByToken({
    required String memberUserId,
    required String token,
  }) async {
    final result = await _client.rpc('join_family_share', params: {
      'p_member_user_id': memberUserId,
      'p_token': token,
    });

    if (result == null || (result is List && result.isEmpty)) {
      throw Exception('Không thể kết nối. Kiểm tra mã QR.');
    }

    final row = result is List ? result.first : result;
    return FamilyConnection.fromOwnerMap(row as Map<String, dynamic>);
  }

  Future<List<FamilyConnection>> getFamilyMembers(String ownerUserId) async {
    final result = await _client.rpc('get_family_members', params: {
      'p_owner_user_id': ownerUserId,
    });

    if (result == null) return [];
    return (result as List)
        .map((e) => FamilyConnection.fromMemberMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FamilyConnection>> getSharedWithMe(String memberUserId) async {
    final result = await _client.rpc('get_shared_with_me', params: {
      'p_member_user_id': memberUserId,
    });

    if (result == null) return [];
    return (result as List)
        .map((e) => FamilyConnection.fromOwnerMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> revokeMember({
    required String ownerUserId,
    required String memberUserId,
  }) async {
    await _client.rpc('revoke_family_member', params: {
      'p_owner_user_id': ownerUserId,
      'p_member_user_id': memberUserId,
    });
  }

  Future<void> leaveShare({
    required String memberUserId,
    required String ownerUserId,
  }) async {
    await _client.rpc('leave_family_share', params: {
      'p_member_user_id': memberUserId,
      'p_owner_user_id': ownerUserId,
    });
  }
}
