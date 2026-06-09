import 'package:flutter/material.dart';
import '../models/daily_summary_model.dart';
import '../models/family_member.dart';
import '../models/health_metrics.dart';
import '../services/health_data_service.dart';
import '../themes/app_theme.dart';

class SharedHealthScreen extends StatefulWidget {
  final FamilyConnection owner;

  const SharedHealthScreen({super.key, required this.owner});

  @override
  State<SharedHealthScreen> createState() => _SharedHealthScreenState();
}

class _SharedHealthScreenState extends State<SharedHealthScreen> {
  final _health = HealthDataService();
  DailySummaryModel? _summary;
  List<HealthMetrics> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 1));
    final summary = await _health.getDailySummary(widget.owner.userId, now);
    final recent = await _health.getRecordsInRange(
      widget.owner.userId,
      start,
      now,
    );
    if (mounted) {
      setState(() {
        _summary = summary;
        _recent = recent.reversed.take(10).toList();
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.owner.displayName,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentRed))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.accentRed,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  _todayCard(),
                  const SizedBox(height: 16),
                  const Text(
                    'Đo gần đây',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_recent.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Chưa có dữ liệu từ thiết bị đeo',
                          style: TextStyle(color: AppTheme.mutedGrey),
                        ),
                      ),
                    )
                  else
                    ..._recent.map(_recordTile),
                ],
              ),
            ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.accentRed.withOpacity(0.2),
            child: Text(
              widget.owner.initials,
              style: const TextStyle(
                  color: AppTheme.accentRed, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.owner.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('@${widget.owner.username}',
                    style: const TextStyle(
                        color: AppTheme.mutedGrey, fontSize: 13)),
                const SizedBox(height: 4),
                const Text(
                  'Dữ liệu từ thiết bị đeo BLE',
                  style: TextStyle(color: AppTheme.neonGreen, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayCard() {
    final s = _summary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hôm nay',
              style: TextStyle(
                  color: AppTheme.mutedGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(Icons.favorite_rounded, 'Nhịp tim TB',
                  '${s?.avgHeartRate ?? '—'} BPM', AppTheme.accentRed),
              const SizedBox(width: 12),
              _stat(Icons.bloodtype_rounded, 'SpO2 TB',
                  '${s?.avgSpO2 ?? '—'}%', AppTheme.accentTeal),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${s?.totalHeartRateRecords ?? 0} lần đồng bộ hôm nay',
            style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardDarker,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 10)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _recordTile(HealthMetrics m) {
    final time =
        '${m.timestamp.hour.toString().padLeft(2, '0')}:${m.timestamp.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(time,
              style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
          const Spacer(),
          Text('${m.heartRate} BPM',
              style: const TextStyle(
                  color: AppTheme.accentRed, fontWeight: FontWeight.w600)),
          const SizedBox(width: 16),
          Text('${m.spO2}%',
              style: const TextStyle(
                  color: AppTheme.accentTeal, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
