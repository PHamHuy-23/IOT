import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_metrics.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  // Auth
  Future<String?> signUp(String email, String password, String username) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await client.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'username': username,
          'created_at': DateTime.now().toIso8601String(),
        });
        return response.user!.id;
      }
      return null;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      print('Sign in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  String? getCurrentUserId() => client.auth.currentUser?.id;

  // Health metrics
  Future<void> saveHealthMetric(HealthMetrics metric) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    await client.from('health_records').insert({
      'user_id': userId,
      'heart_rate': metric.heartRate,
      'spo2': metric.spO2,
      'timestamp': metric.timestamp.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<HealthMetrics>> getTodayMetrics() async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await client
        .from('health_records')
        .select()
        .eq('user_id', userId)
        .gte('timestamp', startOfDay.toIso8601String())
        .lt('timestamp', endOfDay.toIso8601String())
        .order('timestamp', ascending: false);

    return (response as List)
        .map((e) => HealthMetrics(
          heartRate: e['heart_rate'],
          spO2: e['spo2'],
          timestamp: DateTime.parse(e['timestamp']),
        ))
        .toList();
  }

  Future<List<HealthMetrics>> getMetricsByDateRange(DateTime start, DateTime end) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await client
        .from('health_records')
        .select()
        .eq('user_id', userId)
        .gte('timestamp', start.toIso8601String())
        .lte('timestamp', end.toIso8601String())
        .order('timestamp', ascending: false);

    return (response as List)
        .map((e) => HealthMetrics(
          heartRate: e['heart_rate'],
          spO2: e['spo2'],
          timestamp: DateTime.parse(e['timestamp']),
        ))
        .toList();
  }

  Future<Map<String, dynamic>?> getDailySummary(DateTime date) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    final response = await client
        .from('daily_summary')
        .select()
        .eq('user_id', userId)
        .eq('date', '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}')
        .single();

    return response as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getWeeklySummary(DateTime weekStart) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    final weekEnd = weekStart.add(const Duration(days: 7));

    final response = await client
        .from('daily_summary')
        .select()
        .eq('user_id', userId)
        .gte('date', '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}')
        .lt('date', '${weekEnd.year}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}')
        .order('date', ascending: true);

    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getMonthlySummary(int year, int month) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 1);

    final response = await client
        .from('daily_summary')
        .select()
        .eq('user_id', userId)
        .gte('date', '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-${monthStart.day.toString().padLeft(2, '0')}')
        .lt('date', '${monthEnd.year}-${monthEnd.month.toString().padLeft(2, '0')}-${monthEnd.day.toString().padLeft(2, '0')}')
        .order('date', ascending: true);

    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getYearlySummary(int year) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year + 1, 1, 1);

    final response = await client
        .from('daily_summary')
        .select()
        .eq('user_id', userId)
        .gte('date', '${yearStart.year}-${yearStart.month.toString().padLeft(2, '0')}-${yearStart.day.toString().padLeft(2, '0')}')
        .lt('date', '${yearEnd.year}-${yearEnd.month.toString().padLeft(2, '0')}-${yearEnd.day.toString().padLeft(2, '0')}')
        .order('date', ascending: true);

    return (response as List).cast<Map<String, dynamic>>();
  }

  // Cleanup old data (older than 1 year)
  Future<void> deleteOldRecords() async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));

    await client
        .from('health_records')
        .delete()
        .eq('user_id', userId)
        .lt('created_at', oneYearAgo.toIso8601String());
  }
}
