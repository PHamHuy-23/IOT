import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_alert.dart';
import '../utils/alert_evaluator.dart';

class HealthAlertService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> createAlert({
    required String ownerUserId,
    required AlertEvaluation evaluation,
    int? heartRate,
    int? spO2,
    bool isSimulated = false,
  }) async {
    final result = await _client.rpc('create_health_alert', params: {
      'p_owner_user_id': ownerUserId,
      'p_alert_type': evaluation.alertType,
      'p_severity': evaluation.severity,
      'p_heart_rate': heartRate,
      'p_spo2': spO2,
      'p_message': evaluation.message,
      'p_is_simulated': isSimulated,
    });
    return result as String?;
  }

  Future<List<HealthAlert>> getMyAlerts(String ownerUserId) async {
    final result = await _client.rpc('get_my_alerts', params: {
      'p_owner_user_id': ownerUserId,
    });
    if (result == null) return [];
    return (result as List).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map['owner_user_id'] = ownerUserId;
      return HealthAlert.fromOwnerMap(map);
    }).toList();
  }

  Future<List<HealthAlert>> getFamilyAlerts(String memberUserId) async {
    final result = await _client.rpc('get_family_alerts', params: {
      'p_member_user_id': memberUserId,
      'p_since': DateTime.now()
          .subtract(const Duration(hours: 24))
          .toIso8601String(),
    });
    if (result == null) return [];
    return (result as List)
        .map((e) => HealthAlert.fromFamilyMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> acknowledge(String alertId, String userId) async {
    await _client.rpc('acknowledge_alert', params: {
      'p_alert_id': alertId,
      'p_user_id': userId,
    });
  }
}
