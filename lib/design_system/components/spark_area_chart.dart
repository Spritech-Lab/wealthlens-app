/// A small area+line "sparkline" chart drawn with a CustomPainter (no dep).
library;

import 'package:flutter/material.dart';

/// Plots [values] left→right as a filled area with a line on top and a dot on
/// the last point. Y is normalised over the value range; a flat series renders
/// a centred line.
class SparkAreaChart extends StatelessWidget {
  /// Creates a [SparkAreaChart].
  const SparkAreaChart({
    required this.values,
    required this.color,
    this.height = 86,
    super.key,
  });

  /// Data points in chronological order (need at least 2 to draw a line).
  final List<double> values;

  /// Line / fill color.
  final Color color;

  /// Chart height.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(painter: _SparkPainter(values: values, color: color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs();
    const padV = 8.0; // top/bottom breathing room
    final h = size.height;
    final w = size.width;

    double y(double v) {
      if (span == 0) return h / 2;
      final t = (v - minV) / span; // 0..1
      return padV + (1 - t) * (h - 2 * padV);
    }

    final dx = w / (values.length - 1);
    final points = [
      for (var i = 0; i < values.length; i++) Offset(i * dx, y(values[i])),
    ];

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }

    final area = Path.from(line)
      ..lineTo(points.last.dx, h)
      ..lineTo(points.first.dx, h)
      ..close();
    canvas
      ..drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.25),
              color.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      )
      ..drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      )
      ..drawCircle(points.last, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.color != color || !_sameValues(old.values, values);

  static bool _sameValues(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
