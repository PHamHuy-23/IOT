import 'package:flutter/material.dart';
import 'dart:math' as math;

class HeartRateWavePainter extends CustomPainter {
  final List<int> heartRateValues;
  final Color waveColor;
  final Color fillColor;

  HeartRateWavePainter({
    required this.heartRateValues,
    required this.waveColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (heartRateValues.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path = _buildWavePath(size);
    final filledPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(filledPath, fillPaint);
    canvas.drawPath(path, paint);

    _drawGridLines(canvas, size);
  }

  Path _buildWavePath(Size size) {
    final path = Path();
    final padding = 10.0;
    final graphWidth = size.width - (2 * padding);
    final graphHeight = size.height - (2 * padding);

    final maxValue = heartRateValues.isNotEmpty
        ? heartRateValues.reduce(math.max).toDouble()
        : 100;
    final minValue = heartRateValues.isNotEmpty
        ? heartRateValues.reduce(math.min).toDouble()
        : 0;
    final range = (maxValue - minValue).clamp(1.0, double.infinity);

    final pointSpacing = graphWidth / (heartRateValues.length - 1).clamp(1, double.infinity);

    for (int i = 0; i < heartRateValues.length; i++) {
      final x = padding + (i * pointSpacing);
      final normalizedValue = ((heartRateValues[i] - minValue) / range).clamp(0.0, 1.0);
      final y = padding + graphHeight - (normalizedValue * graphHeight);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = padding + ((i - 1) * pointSpacing);
        final prevValue = ((heartRateValues[i - 1] - minValue) / range).clamp(0.0, 1.0);
        final prevY = padding + graphHeight - (prevValue * graphHeight);

        final controlX = (prevX + x) / 2;
        final controlY = (prevY + y) / 2;

        path.quadraticBezierTo(
          prevX + (x - prevX) / 3,
          prevY,
          controlX,
          controlY,
        );
      }
    }

    return path;
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.5;

    const int gridLines = 4;
    final spacing = size.height / gridLines;

    for (int i = 1; i < gridLines; i++) {
      final y = i * spacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: "Waiting for data...",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(HeartRateWavePainter oldDelegate) {
    return oldDelegate.heartRateValues != heartRateValues;
  }
}
