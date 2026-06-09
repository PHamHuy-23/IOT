import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_summary_model.dart';
import '../models/health_metrics.dart';

class HealthDataService {
  final SupabaseClient _client = Supabase.instance.client;

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> saveHealthRecord({
    required String userId,
    required int heartRate,
    required int spo2,
    DateTime? timestamp,
  }) async {
    if (heartRate <= 0 || spo2 <= 0) return;

    await _client.rpc('insert_health_record', params: {
      'p_user_id': userId,
      'p_heart_rate': heartRate,
      'p_spo2': spo2,
      'p_timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    });
  }

  Future<DailySummaryModel?> getDailySummary(
      String userId, DateTime date) async {
    final data = await _client
        .from('daily_summary')
        .select()
        .eq('user_id', userId)
        .eq('date', _dateStr(date))
        .maybeSingle();

    if (data == null) return null;
    return DailySummaryModel.fromMap(data);
  }

  Future<List<DailySummaryModel>> getSummariesInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _client
        .from('daily_summary')
        .select()
        .eq('user_id', userId)
        .gte('date', _dateStr(start))
        .lte('date', _dateStr(end))
        .order('date', ascending: true);

    return (response as List)
        .map((e) => DailySummaryModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<HealthMetrics>> getRecordsInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _client
        .from('health_records')
        .select()
        .eq('user_id', userId)
        .gte('timestamp', start.toIso8601String())
        .lte('timestamp', end.toIso8601String())
        .order('timestamp', ascending: true);

    return (response as List)
        .map((e) => HealthMetrics(
              heartRate: e['heart_rate'] as int,
              spO2: e['spo2'] as int,
              timestamp: DateTime.parse(e['timestamp'] as String),
            ))
        .toList();
  }

  Future<void> deleteUserHealthData(String userId) async {
    await _client.rpc('delete_user_health_data', params: {
      'p_user_id': userId,
    });
  }

  Future<String> exportUserDataJson(String userId) async {
    final records = await _client
        .from('health_records')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false);

    final summaries = await _client
        .from('daily_summary')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    return jsonEncode({
      'health_records': records,
      'daily_summary': summaries,
    });
  }
}
