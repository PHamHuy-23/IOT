import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/health_alert.dart';
import '../providers/alert_provider.dart';
import '../themes/app_theme.dart';

class HealthAlertsScreen extends StatefulWidget {
  const HealthAlertsScreen({super.key});

  @override
  State<HealthAlertsScreen> createState() => _HealthAlertsScreenState();
}

class _HealthAlertsScreenState extends State<HealthAlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<AlertProvider>();

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Cảnh báo sức khỏe',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.accentRed,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.mutedGrey,
          tabs: [
            Tab(text: 'Của tôi (${alerts.myAlerts.length})'),
            Tab(text: 'Người thân (${alerts.familyAlerts.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _list(alerts.myAlerts, isFamily: false),
          _list(alerts.familyAlerts, isFamily: true),
        ],
      ),
    );
  }

  Widget _list(List<HealthAlert> items, {required bool isFamily}) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Chưa có cảnh báo',
            style: TextStyle(color: AppTheme.mutedGrey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => _tile(items[i], isFamily: isFamily),
    );
  }

  Widget _tile(HealthAlert alert, {required bool isFamily}) {
    final color = alert.isCritical ? AppTheme.accentRed : AppTheme.accentOrange;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                alert.alertType == 'fall_detected'
                    ? Icons.warning_amber_rounded
                    : Icons.favorite_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFamily
                      ? '${alert.ownerDisplayName ?? 'Người thân'} — ${alert.typeLabel}'
                      : alert.typeLabel,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              if (alert.isSimulated)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Mô phỏng',
                      style: TextStyle(
                          color: AppTheme.accentPurple, fontSize: 9)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(alert.message,
              style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
          const SizedBox(height: 4),
          Text(_formatTime(alert.createdAt),
              style: const TextStyle(color: AppTheme.subtleGrey, fontSize: 11)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
