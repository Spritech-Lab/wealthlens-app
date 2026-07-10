/// A water-level progress bar with an optional overlay layer.
library;

import 'package:flutter/material.dart';
import 'package:wealthlens/design_system/motion_policy.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/durations.dart';
import 'package:wealthlens/design_system/tokens/radius.dart';

/// Shows accumulation as a rising water level.
///
/// [value] is the base fill ratio (0–1). [overlay] optionally draws a lighter
/// second layer on top for a temporary / pending amount.
class ProgressTrack extends StatelessWidget {
  /// Creates a [ProgressTrack].
  const ProgressTrack({
    required this.value,
    this.overlay,
    this.color,
    this.height = 10,
    super.key,
  });

  /// Base fill ratio, clamped to 0–1.
  final double value;

  /// Optional overlay ratio drawn above the base, clamped to 0–1.
  final double? overlay;

  /// Base fill color; defaults to the success color.
  final Color? color;

  /// Track thickness.
  final double height;

  @override
  Widget build(BuildContext context) {
    final base = value.clamp(0.0, 1.0);
    final over = (overlay ?? 0).clamp(0.0, 1.0);
    final fill = color ?? context.semantic.success;
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: LayoutBuilder(
        builder: (context, c) {
          return Stack(
            children: [
              Container(width: c.maxWidth, height: height, color: track),
              if (over > 0)
                AnimatedContainer(
                  duration: MotionPolicy.normal(context),
                  curve: AppDurations.standard,
                  width: c.maxWidth * over,
                  height: height,
                  color: context.semantic.overlayTemp,
                ),
              AnimatedContainer(
                duration: MotionPolicy.normal(context),
                curve: AppDurations.standard,
                width: c.maxWidth * base,
                height: height,
                color: fill,
              ),
            ],
          );
        },
      ),
    );
  }
}
