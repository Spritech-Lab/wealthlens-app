/// Contour-wave background texture.
///
/// Four subtle bezier "contour lines" plus a soft green glow near the bottom,
/// drawn behind page content. Light = blue lines @ .045, dark = white @ .05.
library;

import 'package:flutter/material.dart';
import 'package:wealthlens/design_system/tokens/colors.dart';

/// Paints the contour-wave texture to fill its parent. Place at the bottom of
/// a [Stack] behind the scrollable content.
class ContourBackground extends StatelessWidget {
  /// Creates a [ContourBackground].
  const ContourBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ContourPainter(
            line: dark ? Colors.white : AppPalette.lightInfo,
            lineOpacity: dark ? 0.05 : 0.045,
            glow: AppPalette.lightSuccess,
          ),
        ),
      ),
    );
  }
}

class _ContourPainter extends CustomPainter {
  _ContourPainter({
    required this.line,
    required this.lineOpacity,
    required this.glow,
  });

  final Color line;
  final double lineOpacity;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bottom green glow.
    final glowCenter = Offset(w / 2, h * 1.12);
    final glowRadius = w * 1.2;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [glow.withValues(alpha: 0.05), glow.withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(center: glowCenter, radius: glowRadius),
        ),
    );

    // Four contour lines, anchored to the top portion of the view
    // (reference viewBox 330×180).
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = line.withValues(alpha: lineOpacity);

    const baseYs = [150.0, 120.0, 90.0, 60.0];
    final sx = w / 330.0;
    for (final by in baseYs) {
      final y = by * (h / 180.0).clamp(0.0, 1.0) * 1.0;
      final path = Path()
        ..moveTo(-20 * sx, y)
        ..quadraticBezierTo(80 * sx, y - 30, 170 * sx, y - 10)
        ..quadraticBezierTo(260 * sx, y + 10, w + 20, y - 20);
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(_ContourPainter oldDelegate) =>
      oldDelegate.line != line ||
      oldDelegate.lineOpacity != lineOpacity ||
      oldDelegate.glow != glow;
}
