import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

// ══════════════════════════════════════════════════════════════
// MODEL
// ══════════════════════════════════════════════════════════════
class MetricData {
  final String title;
  final String unit;
  final IconData icon;
  final Color color;
  final double current;
  final double target;
  final Map<String, List<double>> history; // 'D','W','M','Y'

  const MetricData({
    required this.title,
    required this.unit,
    required this.icon,
    required this.color,
    required this.current,
    required this.target,
    required this.history,
  });
}

// ── Mock data factory (thay bằng data thật từ provider sau) ──
MetricData mockHeartRate(int current) => MetricData(
      title: 'Nhịp tim',
      unit: 'BPM',
      icon: Icons.favorite_rounded,
      color: AppTheme.accentRed,
      current: current.toDouble(),
      target: 80,
      history: {
        'D': [62, 58, 65, 78, 85, 92, 74, 68],
        'W': [68, 72, 70, 75, 74, 81, 69],
        'M': [67,68,70,72,65,68,71,74,72,69,70,71,75,73,68,66,69,72,74,71,70,73,76,74,74,72,70,69,71,72],
        'Y': [70, 71, 69, 72, 73, 70, 72, 71, 69, 70, 72, 71],
      },
    );

MetricData mockSpO2(int current) => MetricData(
      title: 'Oxy trong máu',
      unit: '%',
      icon: Icons.bloodtype_rounded,
      color: AppTheme.accentTeal,
      current: current.toDouble(),
      target: 98,
      history: {
        'D': [97, 96, 98, 99, 98, 97, 98, 99],
        'W': [97, 98, 96, 99, 98, 97, 98],
        'M': [97,98,98,99,97,96,98,99,98,97,98,99,96,97,98,99,98,97,98,99,97,98,98,99,98,97,98,99,98,97],
        'Y': [97, 98, 97, 98, 99, 98, 97, 98, 99, 98, 97, 98],
      },
    );

MetricData mockSteps(bool connected) => MetricData(
      title: 'Bước chân',
      unit: 'bước',
      icon: Icons.directions_walk_rounded,
      color: AppTheme.accentGreen,
      current: connected ? 4320 : 0,
      target: 10000,
      history: {
        'D': [120, 0, 450, 1200, 2400, 1850, 1400, 0],
        'W': [6200, 8100, 5400, 9300, 7420, 8500, 6900],
        'M': [5800,6200,7100,5400,8100,9200,10500,8800,6400,7200,8300,9000,11200,7500,6100,5900,8200,9500,7400,6800,7100,8900,9400,10200,7420,8100,7900,6300,8500,9000],
        'Y': [240, 260, 280, 220, 250, 270, 290, 310, 285, 295, 275, 250],
      },
    );

MetricData mockCalories(bool connected) => MetricData(
      title: 'Năng lượng',
      unit: 'kcal',
      icon: Icons.local_fire_department_rounded,
      color: AppTheme.accentOrange,
      current: connected ? 185 : 0,
      target: 2200,
      history: {
        'D': [180, 190, 210, 170, 200, 185, 195, 0],
        'W': [1750, 1820, 1690, 1900, 1860, 1780, 1830],
        'M': [1840,1825,1890,1750,1900,1850,1800,1820,1880,1920,1840,1810,1790,1860,1875,1800,1830,1850,1910,1780,1805,1895,1845,1830,1870,1810,1795,1885,1900,1820],
        'Y': [1800, 1820, 1790, 1810, 1830, 1850, 1805, 1825, 1840, 1795, 1815, 1835],
      },
    );

MetricData mockSleep(bool connected) => MetricData(
      title: 'Giấc ngủ',
      unit: 'h',
      icon: Icons.bedtime_rounded,
      color: AppTheme.accentPurple,
      current: connected ? 6.75 : 0,
      target: 8,
      history: {
        'D': [5.8, 6.3, 7.0, 6.8, 6.75, 7.1, 6.4, 0],
        'W': [6.7, 6.9, 6.3, 7.2, 7.0, 6.5, 6.8],
        'M': [6.8,6.9,7.1,6.6,6.75,7.0,6.4,6.8,7.2,6.9,7.0,6.7,6.6,6.8,7.1,6.9,6.5,6.6,6.8,6.7,6.9,6.4,6.8,7.0,6.6,6.9,6.7,6.8,6.6,6.9],
        'Y': [6.7, 6.8, 6.9, 6.5, 6.8, 6.9, 6.6, 6.7, 6.8, 7.0, 6.9, 6.8],
      },
    );

// ══════════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════
class MetricDetailScreen extends StatefulWidget {
  final MetricData metric;

  const MetricDetailScreen({super.key, required this.metric});

  @override
  State<MetricDetailScreen> createState() => _MetricDetailScreenState();
}

class _MetricDetailScreenState extends State<MetricDetailScreen> {
  String _timeframe = 'W';

  List<double> get _data => widget.metric.history[_timeframe] ?? [];

  double get _avg {
    final pos = _data.where((v) => v > 0).toList();
    if (pos.isEmpty) return 0;
    return pos.reduce((a, b) => a + b) / pos.length;
  }

  double get _max => _data.isEmpty ? 0 : _data.reduce(math.max);
  double get _min {
    final pos = _data.where((v) => v > 0).toList();
    return pos.isEmpty ? 0 : pos.reduce(math.min);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metric;

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverAppBar(
              backgroundColor: AppTheme.black,
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.chevron_left_rounded,
                    color: AppTheme.accentRed, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Row(
                children: [
                  Icon(m.icon, color: m.color, size: 20),
                  const SizedBox(width: 8),
                  Text(m.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Giá trị hiện tại ──
                  _buildCurrentValue(m),
                  const SizedBox(height: 16),

                  // ── Timeframe picker ──
                  _buildTimeframePicker(),
                  const SizedBox(height: 16),

                  // ── Biểu đồ ──
                  _buildChartCard(m),
                  const SizedBox(height: 16),

                  // ── Thống kê ──
                  _buildStatsGrid(m),
                  const SizedBox(height: 16),

                  // ── Lời khuyên ──
                  _buildTip(m),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Giá trị hiện tại ──────────────────────────────────────
  Widget _buildCurrentValue(MetricData m) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hôm nay',
                style: TextStyle(color: AppTheme.mutedGrey, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  m.current > 0 ? m.current.toStringAsFixed(0) : '--',
                  style: TextStyle(
                      color: m.color,
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -2),
                ),
                const SizedBox(width: 6),
                Text(m.unit,
                    style: TextStyle(color: m.color, fontSize: 16)),
              ],
            ),
          ],
        ),
        // Badge mục tiêu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: m.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.flag_rounded, color: m.color, size: 14),
              const SizedBox(width: 5),
              Text(
                'Mục tiêu: ${m.target.toStringAsFixed(0)} ${m.unit}',
                style: TextStyle(
                    color: m.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Timeframe picker ──────────────────────────────────────
  Widget _buildTimeframePicker() {
    const tabs = ['D', 'W', 'M', 'Y'];
    const labels = ['Ngày', 'Tuần', 'Tháng', 'Năm'];

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(4, (i) {
          final selected = _timeframe == tabs[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _timeframe = tabs[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.accentRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: selected ? Colors.white : AppTheme.mutedGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Chart card ────────────────────────────────────────────
  Widget _buildChartCard(MetricData m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_chartTitle(),
              style: const TextStyle(
                  color: AppTheme.mutedGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: _MetricChart(
              data: _data,
              color: m.color,
              target: m.target,
              timeframe: _timeframe,
              isBar: ['steps', 'bước'].contains(m.unit.toLowerCase()) ||
                  m.title == 'Bước chân',
            ),
          ),
        ],
      ),
    );
  }

  String _chartTitle() {
    switch (_timeframe) {
      case 'D': return 'Theo giờ hôm nay';
      case 'W': return 'Thứ 2 – Chủ nhật tuần này';
      case 'M': return '30 ngày qua';
      case 'Y': return '12 tháng qua';
      default:  return '';
    }
  }

  // ── Stats grid ────────────────────────────────────────────
  Widget _buildStatsGrid(MetricData m) {
    final stats = [
      ('Trung bình', _avg.toStringAsFixed(1), m.color),
      ('Cao nhất',   _max.toStringAsFixed(0), AppTheme.neonGreen),
      ('Thấp nhất',  _min.toStringAsFixed(0), AppTheme.accentOrange),
      ('Mục tiêu',   m.target.toStringAsFixed(0), AppTheme.mutedGrey),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: stats.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(s.$1,
                  style: const TextStyle(
                      color: AppTheme.mutedGrey, fontSize: 10)),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(s.$2,
                      style: TextStyle(
                          color: s.$3,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 3),
                  Text(m.unit,
                      style: const TextStyle(
                          color: AppTheme.mutedGrey, fontSize: 10)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Tip card ─────────────────────────────────────────────
  Widget _buildTip(MetricData m) {
    final tips = {
      'Nhịp tim':       'Nhịp tim nghỉ ngơi lý tưởng là 60–100 BPM. Luyện tập cardio đều đặn giúp giảm nhịp tim khi nghỉ theo thời gian.',
      'Oxy trong máu':  'SpO2 bình thường từ 95–100%. Nếu dưới 90%, hãy liên hệ bác sĩ ngay.',
      'Bước chân':      '10,000 bước/ngày là mục tiêu phổ biến. Đi bộ 30 phút mỗi ngày cải thiện sức khoẻ tim mạch đáng kể.',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: m.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: m.color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: m.color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tips[m.title] ??
                  'Theo dõi đều đặn giúp phát hiện sớm các thay đổi sức khoẻ.',
              style: TextStyle(
                  color: Colors.grey[300], fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CHART PAINTER
// ══════════════════════════════════════════════════════════════
class _MetricChart extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double target;
  final String timeframe;
  final bool isBar;

  const _MetricChart({
    required this.data,
    required this.color,
    required this.target,
    required this.timeframe,
    this.isBar = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('Chưa có dữ liệu',
            style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13)),
      );
    }

    return CustomPaint(
      painter: _ChartPainter(
        data: data,
        color: color,
        target: target,
        timeframe: timeframe,
        isBar: isBar,
      ),
      size: Size.infinite,
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double target;
  final String timeframe;
  final bool isBar;

  static const _labelStyle = TextStyle(
    color: AppTheme.mutedGrey,
    fontSize: 9,
    fontWeight: FontWeight.w500,
  );

  const _ChartPainter({
    required this.data,
    required this.color,
    required this.target,
    required this.timeframe,
    required this.isBar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pL = 8.0, pR = 8.0, pT = 8.0, pB = 22.0;
    final w = size.width - pL - pR;
    final h = size.height - pT - pB;

    final maxVal = [
      ...data,
      target,
    ].reduce(math.max) * 1.12;
    const minVal = 0.0;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(pL, pT), Offset(pL + w, pT), gridPaint);
    canvas.drawLine(
        Offset(pL, pT + h / 2), Offset(pL + w, pT + h / 2), gridPaint);
    canvas.drawLine(
        Offset(pL, pT + h), Offset(pL + w, pT + h), gridPaint);

    // Target line
    if (target > 0 && target < maxVal) {
      final ty = pT + h - ((target - minVal) / (maxVal - minVal)) * h;
      final targetPaint = Paint()
        ..color = AppTheme.neonGreen.withOpacity(0.6)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (double x = pL; x < pL + w; x += 6) {
        path.moveTo(x, ty);
        path.lineTo(x + 3, ty);
      }
      canvas.drawPath(path, targetPaint);
    }

    // Points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = pL + (data.length == 1 ? w / 2 : i / (data.length - 1) * w);
      final y = pT + h - ((data[i] - minVal) / (maxVal - minVal)) * h;
      points.add(Offset(x, y));
    }

    if (isBar) {
      _drawBars(canvas, points, h, pT, color);
    } else {
      _drawLine(canvas, points, h, pT, color);
    }

    // X labels
    _drawLabels(canvas, size, pL, w, pT + h + 6);
  }

  void _drawBars(Canvas canvas, List<Offset> points, double h, double pT, Color color) {
    final barW = (points.length > 1
            ? (points[1].dx - points[0].dx) * 0.55
            : 20.0)
        .clamp(4.0, 24.0);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final barH = (pT + h - pt.dy).clamp(2.0, double.infinity);
      paint.color = i == points.length - 1
          ? color
          : color.withOpacity(0.65);
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(pt.dx - barW / 2, pt.dy, barW, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(rr, paint);
    }
  }

  void _drawLine(Canvas canvas, List<Offset> points, double h, double pT, Color color) {
    if (points.length < 2) return;

    // Area fill
    final areaPath = Path()..moveTo(points.first.dx, pT + h);
    for (final p in points) areaPath.lineTo(p.dx, p.dy);
    areaPath
      ..lineTo(points.last.dx, pT + h)
      ..close();
    canvas.drawPath(
        areaPath, Paint()..color = color.withOpacity(0.12));

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dot on last point
    canvas.drawCircle(
        points.last,
        5,
        Paint()..color = Colors.white);
    canvas.drawCircle(
        points.last,
        3.5,
        Paint()..color = color);
  }

  void _drawLabels(Canvas canvas, Size size, double pL, double w, double y) {
    List<String> labels;
    List<int> indices;

    switch (timeframe) {
      case 'D':
        labels = ['12SA','3SA','6SA','9SA','12CH','3CH','6CH','9CH'];
        indices = List.generate(data.length, (i) => i);
        break;
      case 'W':
        labels = ['T2','T3','T4','T5','T6','T7','CN'];
        indices = List.generate(data.length, (i) => i);
        break;
      case 'M':
        labels = ['1','8','15','22','30'];
        indices = [0, 7, 14, 21, 29];
        break;
      case 'Y':
        labels = ['T1','T2','T3','T4','T5','T6','T7','T8','T9','T10','T11','T12'];
        indices = List.generate(data.length, (i) => i);
        break;
      default:
        return;
    }

    for (int li = 0; li < labels.length; li++) {
      final di = indices.length > li ? indices[li] : -1;
      if (di < 0 || di >= data.length) continue;

      final x = pL + (data.length == 1 ? w / 2 : di / (data.length - 1) * w);
      final tp = TextPainter(
        text: TextSpan(text: labels[li], style: _labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y));
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.data != data || old.timeframe != timeframe;
}
