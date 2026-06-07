import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

// ══════════════════════════════════════════════════════════════
// PAINTER — vẽ 3 vòng tròn đồng tâm
// ══════════════════════════════════════════════════════════════
class ActivityRingsPainter extends CustomPainter {
  final double stepsPct;    // 0.0 – 1.0+  (bước chân / mục tiêu)
  final double mindfulPct;  // 0.0 – 1.0+  (chánh niệm / mục tiêu)
  final double waterPct;    // 0.0 – 1.0+  (nước / mục tiêu)

  const ActivityRingsPainter({
    required this.stepsPct,
    required this.mindfulPct,
    required this.waterPct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    const strokeWidth = 11.0;
    const gap = 7.0; // khoảng cách giữa các vòng

    // Bán kính 3 vòng (ngoài → trong)
    final r1 = maxRadius - strokeWidth / 2;           // Bước chân
    final r2 = r1 - strokeWidth - gap;                // Chánh niệm
    final r3 = r2 - strokeWidth - gap;                // Nước uống

    _drawRing(canvas, center, r1, stepsPct,   AppTheme.accentRed,    strokeWidth);
    _drawRing(canvas, center, r2, mindfulPct, AppTheme.accentTeal,   strokeWidth);
    _drawRing(canvas, center, r3, waterPct,   AppTheme.accentBlue,   strokeWidth);
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double pct,
    Color color,
    double strokeWidth,
  ) {
    // Track (nền mờ)
    final trackPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Arc tiến trình — clamp tối đa 2 vòng (200%) để tránh overlap kỳ lạ
    final clampedPct = pct.clamp(0.0, 2.0);
    if (clampedPct == 0) return;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = clampedPct * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,   // bắt đầu từ 12 giờ
      sweepAngle,
      false,
      progressPaint,
    );

    // Nếu > 100%: vẽ vòng thứ 2 với màu sáng hơn (overlay)
    if (pct > 1.0) {
      final overflowPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = strokeWidth * 0.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final overflowSweep = (pct - 1.0).clamp(0.0, 1.0) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        overflowSweep,
        false,
        overflowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ActivityRingsPainter old) =>
      old.stepsPct != stepsPct ||
      old.mindfulPct != mindfulPct ||
      old.waterPct != waterPct;
}

// ══════════════════════════════════════════════════════════════
// WIDGET — rings + legend cạnh bên
// ══════════════════════════════════════════════════════════════
class ActivityRingsWidget extends StatelessWidget {
  /// Dữ liệu thực — truyền vào từ provider
  final int steps;
  final int stepsTarget;
  final int mindfulMinutes;
  final int mindfulTarget;
  final int waterMl;
  final int waterTarget;

  const ActivityRingsWidget({
    super.key,
    this.steps = 0,
    this.stepsTarget = 10000,
    this.mindfulMinutes = 0,
    this.mindfulTarget = 15,
    this.waterMl = 0,
    this.waterTarget = 2000,
  });

  @override
  Widget build(BuildContext context) {
    final stepsPct   = stepsTarget > 0 ? steps / stepsTarget : 0.0;
    final mindfulPct = mindfulTarget > 0 ? mindfulMinutes / mindfulTarget : 0.0;
    final waterPct   = waterTarget > 0 ? waterMl / waterTarget : 0.0;

    final overallPct =
        (((stepsPct + mindfulPct + waterPct) / 3) * 100).round().clamp(0, 200);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // ── Vòng tròn ──
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(130, 130),
                  painter: ActivityRingsPainter(
                    stepsPct: stepsPct,
                    mindfulPct: mindfulPct,
                    waterPct: waterPct,
                  ),
                ),
                // Số % ở giữa
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$overallPct%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const Text(
                      'hoàn thành',
                      style: TextStyle(
                        color: AppTheme.mutedGrey,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // ── Legend ──
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RingLegendRow(
                  color: AppTheme.accentRed,
                  label: 'Bước chân',
                  current: steps.toString(),
                  target: stepsTarget.toString(),
                  unit: '',
                  pct: stepsPct,
                ),
                const SizedBox(height: 12),
                _RingLegendRow(
                  color: AppTheme.accentTeal,
                  label: 'Chánh niệm',
                  current: mindfulMinutes.toString(),
                  target: mindfulTarget.toString(),
                  unit: 'p',
                  pct: mindfulPct,
                ),
                const SizedBox(height: 12),
                _RingLegendRow(
                  color: AppTheme.accentBlue,
                  label: 'Nước uống',
                  current: waterMl.toString(),
                  target: waterTarget.toString(),
                  unit: 'ml',
                  pct: waterPct,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Row legend nhỏ ─────────────────────────────────────────
class _RingLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String current;
  final String target;
  final String unit;
  final double pct;

  const _RingLegendRow({
    required this.color,
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 7),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.mutedGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              Text(
                current,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                ' / $target$unit',
                style: const TextStyle(
                    color: AppTheme.mutedGrey, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Mini progress bar
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
