import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_summary_model.dart';
import '../providers/auth_provider.dart';
import '../services/health_data_service.dart';
import '../themes/app_theme.dart';

class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  final _health = HealthDataService();
  String _period = 'week';
  List<DailySummaryModel> _summaries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    setState(() => _loading = true);
    final now = DateTime.now();
    DateTime start;

    if (_period == 'month') {
      start = DateTime(now.year, now.month, 1);
    } else if (_period == 'year') {
      start = DateTime(now.year, 1, 1);
    } else {
      start = now.subtract(Duration(days: now.weekday - 1));
    }

    final data = await _health.getSummariesInRange(userId, start, now);
    if (mounted) {
      setState(() {
        _summaries = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: const Text('Lịch sử & Báo cáo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _periodBtn('Tuần', 'week'),
                const SizedBox(width: 8),
                _periodBtn('Tháng', 'month'),
                const SizedBox(width: 8),
                _periodBtn('Năm', 'year'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accentRed))
                : _summaries.isEmpty
                    ? const Center(
                        child: Text('Chưa có dữ liệu',
                            style: TextStyle(color: AppTheme.mutedGrey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _summaries.length,
                        itemBuilder: (_, i) => _row(_summaries[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _periodBtn(String label, String value) {
    final selected = _period == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _period = value);
          _load();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accentRed : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _row(DailySummaryModel s) {
    final date =
        '${s.date.day}/${s.date.month}/${s.date.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              _stat('HR trung bình', '${s.avgHeartRate ?? '—'} BPM'),
              const SizedBox(width: 16),
              _stat('SpO2 TB', '${s.avgSpO2 ?? '—'}%'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${s.totalHeartRateRecords} bản ghi đồng bộ',
            style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 10)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
