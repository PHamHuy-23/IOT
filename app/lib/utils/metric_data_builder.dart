import 'package:flutter/material.dart';
import '../models/daily_summary_model.dart';
import '../models/health_metrics.dart';
import '../screens/metric_detail_screen.dart';
import '../services/health_data_service.dart';
import '../themes/app_theme.dart';

class MetricDataBuilder {
  static final _health = HealthDataService();

  static Future<MetricData> heartRate({
    required String? userId,
    required int current,
  }) async {
    if (userId == null) return _mockHeartRate(current);
    try {
      final now = DateTime.now();
      final records = await _health.getRecordsInRange(
        userId,
        now.subtract(const Duration(days: 365)),
        now,
      );
      if (records.isEmpty) return _mockHeartRate(current);
      return MetricData(
        title: 'Nhịp tim',
        unit: 'BPM',
        icon: Icons.favorite_rounded,
        color: AppTheme.accentRed,
        current: current.toDouble(),
        target: 80,
        history: {
          'D': _bucketToday(records, (r) => r.heartRate.toDouble()),
          'W': await _weeklyAvgs(userId, (s) => s.avgHeartRate?.toDouble()),
          'M': await _monthlyAvgs(userId, (s) => s.avgHeartRate?.toDouble()),
          'Y': await _yearlyAvgs(userId, (s) => s.avgHeartRate?.toDouble()),
        },
      );
    } catch (_) {
      return _mockHeartRate(current);
    }
  }

  static Future<MetricData> spO2({
    required String? userId,
    required int current,
  }) async {
    if (userId == null) return _mockSpO2(current);
    try {
      final now = DateTime.now();
      final records = await _health.getRecordsInRange(
        userId,
        now.subtract(const Duration(days: 365)),
        now,
      );
      if (records.isEmpty) return _mockSpO2(current);
      return MetricData(
        title: 'Oxy trong máu',
        unit: '%',
        icon: Icons.bloodtype_rounded,
        color: AppTheme.accentTeal,
        current: current.toDouble(),
        target: 98,
        history: {
          'D': _bucketToday(records, (r) => r.spO2.toDouble()),
          'W': await _weeklyAvgs(userId, (s) => s.avgSpO2?.toDouble()),
          'M': await _monthlyAvgs(userId, (s) => s.avgSpO2?.toDouble()),
          'Y': await _yearlyAvgs(userId, (s) => s.avgSpO2?.toDouble()),
        },
      );
    } catch (_) {
      return _mockSpO2(current);
    }
  }

  static List<double> _bucketToday(
    List<HealthMetrics> records,
    double Function(HealthMetrics) pick,
  ) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final buckets = List<double>.filled(8, 0);
    final counts = List<int>.filled(8, 0);

    for (final r in records) {
      if (r.timestamp.isBefore(start)) continue;
      final hour = r.timestamp.hour;
      final idx = (hour / 3).floor().clamp(0, 7);
      buckets[idx] += pick(r);
      counts[idx]++;
    }

    return List.generate(8, (i) {
      if (counts[i] == 0) return 0;
      return buckets[i] / counts[i];
    });
  }

  static Future<List<double>> _weeklyAvgs(
    String userId,
    double? Function(DailySummaryModel) pick,
  ) async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final summaries =
        await _health.getSummariesInRange(userId, monday, now);
    return _fillDays(summaries, monday, 7, pick);
  }

  static Future<List<double>> _monthlyAvgs(
    String userId,
    double? Function(DailySummaryModel) pick,
  ) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final summaries =
        await _health.getSummariesInRange(userId, start, now);
    final days = now.day;
    return _fillDays(summaries, start, days, pick);
  }

  static Future<List<double>> _yearlyAvgs(
    String userId,
    double? Function(DailySummaryModel) pick,
  ) async {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final summaries =
        await _health.getSummariesInRange(userId, start, now);
    final months = List<double>.filled(12, 0);
    final counts = List<int>.filled(12, 0);
    for (final s in summaries) {
      final m = s.date.month - 1;
      final v = pick(s);
      if (v != null && v > 0) {
        months[m] += v;
        counts[m]++;
      }
    }
    return List.generate(12, (i) => counts[i] == 0 ? 0 : months[i] / counts[i]);
  }

  static List<double> _fillDays(
    List<DailySummaryModel> summaries,
    DateTime start,
    int count,
    double? Function(DailySummaryModel) pick,
  ) {
    final map = {for (final s in summaries) _dayKey(s.date): s};
    return List.generate(count, (i) {
      final day = start.add(Duration(days: i));
      final s = map[_dayKey(day)];
      if (s == null) return 0;
      return pick(s) ?? 0;
    });
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month}-${d.day}';

  static MetricData _mockHeartRate(int current) => MetricData(
        title: 'Nhịp tim',
        unit: 'BPM',
        icon: Icons.favorite_rounded,
        color: AppTheme.accentRed,
        current: current.toDouble(),
        target: 80,
        history: {'D': [], 'W': [], 'M': [], 'Y': []},
      );

  static MetricData _mockSpO2(int current) => MetricData(
        title: 'Oxy trong máu',
        unit: '%',
        icon: Icons.bloodtype_rounded,
        color: AppTheme.accentTeal,
        current: current.toDouble(),
        target: 98,
        history: {'D': [], 'W': [], 'M': [], 'Y': []},
      );
}
