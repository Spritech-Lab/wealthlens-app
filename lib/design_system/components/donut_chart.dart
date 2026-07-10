/// A simple donut/ring chart drawn with a CustomPainter (no chart dep).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One slice of a [DonutChart].
class DonutSegment {
  /// Creates a [DonutSegment].
  const DonutSegment({required this.value, required this.color});

  /// Non-negative magnitude; slices are sized by value / Σ values.
  final double value;

  /// Slice color.
  final Color color;
}

/// A ring chart sized by each segment's share of the total. Zero-value
/// segments are skipped; an all-zero input renders a plain track ring.
class DonutChart extends StatelessWidget {
  /// Creates a [DonutChart].
  const DonutChart({
    required this.segments,
    this.size = 92,
    this.stroke = 12,
    this.trackColor,
    super.key,
  });

  /// The slices, in draw order (clockwise from 12 o'clock).
  final List<DonutSegment> segments;

  /// Overall diameter.
  final double size;

  /// Ring thickness.
  final double stroke;

  /// Background track color (defaults to a faint divider tint).
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          segments: segments,
          stroke: stroke,
          track: trackColor ?? Theme.of(context).dividerColor,
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.stroke,
    required this.track,
  });

  final List<DonutSegment> segments;
  final double stroke;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, 2 * math.pi, false, base);

    final total =
        segments.fold<double>(0, (s, seg) => s + math.max(0, seg.value));
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweep = seg.value / total * 2 * math.pi;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt
          ..color = seg.color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.stroke != stroke ||
      old.track != track ||
      !_sameSegments(old.segments, segments);

  static bool _sameSegments(List<DonutSegment> a, List<DonutSegment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value || a[i].color != b[i].color) return false;
    }
    return true;
  }
}
