/// The top navigation segmented pill (任務 / 資產 / 紀錄).
library;

import 'package:flutter/material.dart';
import 'package:wealthlens/design_system/motion_policy.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/durations.dart';
import 'package:wealthlens/design_system/tokens/radius.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';

/// A pill-shaped segmented control with an animated selection thumb.
class SegmentedPill extends StatelessWidget {
  /// Creates a [SegmentedPill].
  const SegmentedPill({
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  /// Segment labels.
  final List<String> segments;

  /// Index of the active segment.
  final int selectedIndex;

  /// Called with the tapped segment index.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final segW = (c.maxWidth - AppSpacing.xs * 2) / segments.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: MotionPolicy.fast(context),
                curve: AppDurations.standard,
                left: segW * selectedIndex,
                child: Container(
                  width: segW,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.semantic.info,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: context.semantic.info.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: -2,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < segments.length; i++)
                    SizedBox(
                      width: segW,
                      height: 36,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: () => onChanged(i),
                        child: Center(
                          child: Text(
                            segments[i],
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: i == selectedIndex
                                  ? Colors.white
                                  : context.semantic.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
