import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../painters/heart_rate_wave_painter.dart';
import '../providers/health_provider.dart';
import '../themes/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthProvider>().autoConnectToWatch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Monitor'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Consumer<HealthProvider>(
                builder: (context, provider, _) {
                  final isConnected = provider.isConnected;
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: isConnected
                          ? AppTheme.neonGreen
                          : AppTheme.mutedGrey,
                      radius: 4,
                    ),
                    label: Text(
                      isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isConnected
                            ? AppTheme.neonGreen
                            : AppTheme.mutedGrey,
                      ),
                    ),
                    backgroundColor: isConnected
                        ? AppTheme.neonGreen.withValues(alpha: 0.1)
                        : AppTheme.mutedGrey.withValues(alpha: 0.1),
                    side: BorderSide(
                      color: isConnected
                          ? AppTheme.neonGreen.withValues(alpha: 0.3)
                          : AppTheme.mutedGrey.withValues(alpha: 0.3),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Consumer<HealthProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () => provider.autoConnectToWatch(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildConnectionStatusCard(context, provider),
                    const SizedBox(height: 24),
                    _buildHeartRateCard(context, provider),
                    const SizedBox(height: 24),
                    _buildSpO2Card(context, provider),
                    const SizedBox(height: 24),
                    _buildSyncTimeButton(context, provider),
                    if (provider.errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(provider),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatusCard(
    BuildContext context,
    HealthProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: provider.isConnected
                        ? AppTheme.neonGreen
                        : (provider.isConnecting
                            ? Colors.orange
                            : AppTheme.mutedGrey),
                    boxShadow: provider.isConnected
                        ? [
                            BoxShadow(
                              color: AppTheme.neonGreen.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connection Status',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.connectionStatus,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (provider.isConnected && provider.connectedDevice != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(
                    context: context,
                    label: 'Disconnect',
                    onPressed: () => provider.disconnectDevice(),
                    color: AppTheme.electricRed,
                  ),
                  _buildActionButton(
                    context: context,
                    label: 'Reconnect',
                    onPressed: () => provider.autoConnectToWatch(),
                    color: AppTheme.accentPurple,
                  ),
                ],
              ),
            ] else if (!provider.isConnecting) ...[
              if (Platform.isAndroid) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'Android: không ghép đôi ESP32 trong Cài đặt Bluetooth '
                    '(sẽ báo "không thể giao tiếp"). Chỉ nhấn nút bên dưới. '
                    'Bật GPS/Vị trí nếu không quét được.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => provider.autoConnectToWatch(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPurple,
                    ),
                    child: const Text('Kết nối đồng hồ'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateCard(
    BuildContext context,
    HealthProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heart Rate',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${provider.heartRate}',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getHeartRateColor(provider.heartRate),
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'bpm',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.getHeartRateColor(provider.heartRate)
                        .withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppTheme.getHeartRateColor(provider.heartRate)
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: AppTheme.getHeartRateColor(provider.heartRate),
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: HeartRateWavePainter(
                  heartRateValues: provider.heartRateHistory.values,
                  waveColor: AppTheme.electricPink,
                  fillColor: AppTheme.electricPink,
                ),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatChip(
                  label: 'Samples',
                  value: '${provider.heartRateHistory.length}',
                  context: context,
                ),
                _buildStatChip(
                  label: 'Status',
                  value: provider.heartRate > 0 ? 'Active' : 'Idle',
                  context: context,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpO2Card(BuildContext context, HealthProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blood Oxygen',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${provider.spO2}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getSpO2Color(provider.spO2),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.getSpO2Color(provider.spO2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getSpO2Status(provider.spO2),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: AppTheme.getSpO2Color(provider.spO2),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildCircularProgressRing(
                    provider.spO2.toDouble(),
                    100,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        color: AppTheme.getSpO2Color(provider.spO2),
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SpO₂',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgressRing(double value, double maxValue) {
    return CustomPaint(
      painter: _CircularProgressPainter(
        value: value,
        maxValue: maxValue,
        color: AppTheme.getSpO2Color(value.toInt()),
      ),
      size: const Size(120, 120),
    );
  }

  Widget _buildSyncTimeButton(
    BuildContext context,
    HealthProvider provider,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: provider.isConnected
            ? () async {
                await provider.syncTimeToWatch();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Time synced to watch'),
                      duration: Duration(seconds: 2),
                      backgroundColor: AppTheme.neonGreen,
                    ),
                  );
                }
              }
            : null,
        icon: const Icon(Icons.schedule),
        label: const Text('Sync Time to Watch'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: provider.isConnected
              ? AppTheme.accentPurple
              : AppTheme.mutedGrey.withValues(alpha: 0.3),
          foregroundColor: provider.isConnected
              ? AppTheme.softWhite
              : AppTheme.mutedGrey,
        ),
      ),
    );
  }

  Widget _buildErrorBanner(HealthProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.electricRed.withValues(alpha: 0.1),
        border: Border.all(
          color: AppTheme.electricRed.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: AppTheme.electricRed,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider.errorMessage,
              style: TextStyle(
                color: AppTheme.electricRed,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      {required String label,
      required String value,
      required BuildContext context}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSlate.withValues(alpha: 0.5),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.2),
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  String _getSpO2Status(int spo2) {
    if (spo2 == 0) return 'No data';
    if (spo2 >= 95) return 'Excellent';
    if (spo2 >= 90) return 'Good';
    if (spo2 >= 85) return 'Fair';
    return 'Low';
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color color;

  _CircularProgressPainter({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final backgroundPaint = Paint()
      ..color = AppTheme.darkSlate.withValues(alpha: 0.5)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final foregroundPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final percentage = (value / maxValue).clamp(0, 1);
    final sweepAngle = (percentage * 360 * (3.14159 / 180)) * 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}
