import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/ble_constants.dart';
import '../models/ble_device_model.dart';
import '../services/ble_service.dart';
import '../themes/app_theme.dart';

// ══════════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════════════
class ConnectScreen extends StatefulWidget {
  final BleDeviceModel device;
  final BleService bleService;

  const ConnectScreen({
    super.key,
    required this.device,
    required this.bleService,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with TickerProviderStateMixin {
  // ── Data ──────────────────────────────────────────────────
  int heartRate = 0;
  int spo2 = 0;
  DateTime? lastUpdateTime;
  bool isListening = false;
  String statusMessage = 'Đang kết nối...';
  List<_HealthSnap> history = [];

  // ── Wave history cho mini chart ───────────────────────────
  final List<double> _hrWave = List.filled(30, 0);

  // ── Animation: pulse ring ─────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── Animation: SpO2 ring ──────────────────────────────────
  late AnimationController _spo2Ctrl;
  late Animation<double> _spo2Anim;
  double _spo2AnimTarget = 0;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _spo2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _spo2Anim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _spo2Ctrl, curve: Curves.easeOutCubic),
    );

    _startListening();
  }

  // ── BLE logic ────────────────────────────────────────────
  void _startListening() async {
    setState(() => statusMessage = 'Đang khám phá services...');
    try {
      if (widget.bleService.getDiscoveredServices() == null) {
        await widget.bleService.discoverServices();
      }
      _subscribeHeartRate();
      _subscribeSpO2();
      setState(() {
        isListening = true;
        statusMessage = 'Đang nhận dữ liệu...';
      });
    } catch (e) {
      setState(() => statusMessage = 'Lỗi: $e');
    }
  }

  void _subscribeHeartRate() async {
    try {
      final stream = await widget.bleService.subscribeToCharacteristic(
        HEART_RATE_SERVICE_UUID,
        HEART_RATE_MEASUREMENT_UUID,
      );
      stream?.listen(
        (v) { print('RAW HR: $v'); _processHR(v); },
        onError: (e) => print('HR error: $e'),
        cancelOnError: false,
      );
    } catch (e) {
      print('Cannot subscribe HR: $e');
    }
  }

  void _subscribeSpO2() async {
    try {
      final stream = await widget.bleService.subscribeToCharacteristic(
        SPO2_SERVICE_UUID,
        SPO2_MEASUREMENT_UUID,
      );
      stream?.listen(
        (v) { print('RAW SpO2: $v'); _processSpO2(v); },
        onError: (e) => print('SpO2 error: $e'),
        cancelOnError: false,
      );
    } catch (e) {
      print('Cannot subscribe SpO2: $e');
    }
  }

  void _processHR(List<int> data) {
    if (data.isEmpty) return;
    int hr;
    if (data.length >= 2 && (data[0] & 0x01) == 0) {
      hr = data[1];
    } else if (data.length >= 3 && (data[0] & 0x01) == 1) {
      hr = data[1] | (data[2] << 8);
    } else {
      hr = data[0];
    }
    if (hr < MIN_HEART_RATE || hr > MAX_HEART_RATE) return;

    setState(() {
      heartRate = hr;
      lastUpdateTime = DateTime.now();
      _hrWave.removeAt(0);
      _hrWave.add(hr.toDouble());
    });
    _triggerPulse();
    _tryAddHistory();
  }

  void _processSpO2(List<int> data) {
    if (data.isEmpty) return;
    final s = data[0];
    if (s < MIN_SPO2 || s > MAX_SPO2) return;

    final newPct = s / 100.0;
    _spo2Anim = Tween<double>(
      begin: _spo2AnimTarget,
      end: newPct,
    ).animate(CurvedAnimation(parent: _spo2Ctrl, curve: Curves.easeOutCubic));
    _spo2AnimTarget = newPct;
    _spo2Ctrl..reset()..forward();

    setState(() {
      spo2 = s;
      lastUpdateTime = DateTime.now();
    });
    _tryAddHistory();
  }

  void _triggerPulse() {
    if (heartRate > 0) {
      _pulseCtrl
        ..reset()
        ..forward().then((_) => _pulseCtrl.reverse());
    }
  }

  void _tryAddHistory() {
    if (heartRate > 0 && spo2 > 0) {
      setState(() {
        history.add(_HealthSnap(hr: heartRate, spo2: spo2, time: DateTime.now()));
        if (history.length > 60) history.removeAt(0);
      });
    }
  }

  void _disconnect() async {
    try {
      await widget.bleService.disconnectDevice();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _spo2Ctrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildStatusRow(),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildHRCard()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSpO2Card()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (heartRate > 0) _buildWaveCard(),
                    const SizedBox(height: 12),
                    if (history.isNotEmpty) _buildHistoryCard(),
                    const SizedBox(height: 24),
                    _buildDisconnectButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: AppTheme.black,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: AppTheme.accentRed, size: 28),
            onPressed: _disconnect,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.getDisplayName(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.device.deviceId,
                  style: const TextStyle(
                      color: AppTheme.mutedGrey, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _SignalBars(rssi: widget.device.rssi),
        ],
      ),
    );
  }

  // ── Status row ───────────────────────────────────────────
  Widget _buildStatusRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isListening ? AppTheme.neonGreen : Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Text(statusMessage,
            style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
        if (lastUpdateTime != null) ...[
          const SizedBox(width: 8),
          Text(
            '• ${_fmt(lastUpdateTime!)}',
            style: const TextStyle(color: AppTheme.mutedGrey, fontSize: 11),
          ),
        ],
      ],
    );
  }

  // ── Heart Rate card ──────────────────────────────────────
  Widget _buildHRCard() {
    final color = AppTheme.getHeartRateColor(heartRate);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nhịp tim',
                  style: TextStyle(
                      color: AppTheme.mutedGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              ScaleTransition(
                scale: _pulseAnim,
                child: Icon(Icons.favorite_rounded, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ScaleTransition(
            scale: _pulseAnim,
            child: Text(
              heartRate > 0 ? '$heartRate' : '--',
              style: TextStyle(
                  color: color,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -2),
            ),
          ),
          Text('BPM',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(_hrStatus(heartRate),
              style: const TextStyle(
                  color: AppTheme.mutedGrey, fontSize: 11)),
        ],
      ),
    );
  }

  // ── SpO2 card ────────────────────────────────────────────
  Widget _buildSpO2Card() {
    final color = AppTheme.getSpO2Color(spo2);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Oxy máu',
                  style: TextStyle(
                      color: AppTheme.mutedGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              Icon(Icons.bloodtype_rounded, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: AnimatedBuilder(
              animation: _spo2Anim,
              builder: (_, __) => SizedBox(
                width: 80, height: 80,
                child: CustomPaint(
                  painter: _SpO2RingPainter(pct: _spo2Anim.value, color: color),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          spo2 > 0 ? '$spo2' : '--',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        Text('%', style: TextStyle(color: color, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _spo2Status(spo2),
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Wave chart ───────────────────────────────────────────
  Widget _buildWaveCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sóng nhịp tim',
              style: TextStyle(
                  color: AppTheme.mutedGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: CustomPaint(
              painter: _WavePainter(
                values: List.from(_hrWave),
                color: AppTheme.getHeartRateColor(heartRate),
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  // ── History card ─────────────────────────────────────────
  Widget _buildHistoryCard() {
    final recent = history.reversed.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text('Lịch sử gần đây',
                style: TextStyle(
                    color: AppTheme.mutedGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          ...recent.asMap().entries.map((e) {
            final snap = e.value;
            final isLast = e.key == recent.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom:
                            BorderSide(color: Color(0xFF2C2C2E), width: 0.5)),
              ),
              child: Row(
                children: [
                  Text(_fmt(snap.time),
                      style: const TextStyle(
                          color: AppTheme.mutedGrey, fontSize: 12)),
                  const Spacer(),
                  const Icon(Icons.favorite_rounded,
                      color: AppTheme.accentRed, size: 13),
                  const SizedBox(width: 4),
                  Text('${snap.hr} BPM',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 16),
                  const Icon(Icons.bloodtype_rounded,
                      color: AppTheme.accentTeal, size: 13),
                  const SizedBox(width: 4),
                  Text('${snap.spo2}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Disconnect button ────────────────────────────────────
  Widget _buildDisconnectButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _disconnect,
        icon: const Icon(Icons.power_settings_new_rounded,
            color: Colors.redAccent, size: 18),
        label: const Text('Ngắt kết nối',
            style: TextStyle(color: Colors.redAccent)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Colors.redAccent, width: 0.8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────
  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  String _hrStatus(int hr) {
    if (hr == 0) return 'Chờ dữ liệu...';
    if (hr < 60) return 'Nhịp chậm';
    if (hr <= 100) return 'Bình thường';
    return 'Nhịp nhanh';
  }

  String _spo2Status(int s) {
    if (s == 0) return 'Chờ dữ liệu...';
    if (s >= 95) return 'Bình thường';
    if (s >= 90) return 'Cần theo dõi';
    return '⚠ Thấp';
  }
}

// ══════════════════════════════════════════════════════════════
// PAINTERS & WIDGETS
// ══════════════════════════════════════════════════════════════

class _SpO2RingPainter extends CustomPainter {
  final double pct;
  final Color color;
  const _SpO2RingPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const sw = 5.0;

    canvas.drawCircle(center, radius,
        Paint()
          ..color = color.withOpacity(0.15)
          ..strokeWidth = sw
          ..style = PaintingStyle.stroke);

    if (pct > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        pct.clamp(0.0, 1.0) * 2 * math.pi,
        false,
        Paint()
          ..color = color
          ..strokeWidth = sw
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_SpO2RingPainter old) => old.pct != pct;
}

class _WavePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  const _WavePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final nonZero = values.where((v) => v > 0).toList();
    if (nonZero.isEmpty) return;

    final maxV = nonZero.reduce(math.max);
    final minV = nonZero.reduce(math.min);
    final range = (maxV - minV).clamp(10.0, double.infinity);

    final pts = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final norm = values[i] == 0
          ? 0.5
          : ((values[i] - minV) / range).clamp(0.0, 1.0);
      final y = size.height - norm * size.height * 0.85 - size.height * 0.07;
      pts.add(Offset(x, y));
    }

    // Area
    final areaPath = Path()..moveTo(pts.first.dx, size.height);
    for (final p in pts) areaPath.lineTo(p.dx, p.dy);
    areaPath..lineTo(pts.last.dx, size.height)..close();
    canvas.drawPath(areaPath, Paint()..color = color.withOpacity(0.1));

    // Smooth line
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final curr = pts[i];
      final cp1 = Offset((prev.dx + curr.dx) / 2, prev.dy);
      final cp2 = Offset((prev.dx + curr.dx) / 2, curr.dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    // Dot cuối
    canvas.drawCircle(pts.last, 4, Paint()..color = Colors.white);
    canvas.drawCircle(pts.last, 2.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.values != values;
}

class _SignalBars extends StatelessWidget {
  final int rssi;
  const _SignalBars({required this.rssi});

  @override
  Widget build(BuildContext context) {
    final bars = rssi >= -60 ? 4 : rssi >= -75 ? 3 : rssi >= -85 ? 2 : 1;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (i) {
          final active = i < bars;
          return Container(
            width: 4,
            height: 6.0 + i * 3.5,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: active ? AppTheme.neonGreen : AppTheme.subtleGrey,
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
}

class _HealthSnap {
  final int hr;
  final int spo2;
  final DateTime time;
  const _HealthSnap({required this.hr, required this.spo2, required this.time});
}
