/// A small goal / safety card showing name and progress.
library;

import 'package:flutter/material.dart';
import 'package:wealthlens/design_system/components/progress_track.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/radius.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';

/// A compact card for a secondary goal or safety bucket.
class GoalChip extends StatelessWidget {
  /// Creates a [GoalChip].
  const GoalChip({
    required this.name,
    required this.progress,
    this.caption,
    this.color,
    super.key,
  });

  /// Goal / wallet name.
  final String name;

  /// Progress ratio 0–1.
  final double progress;

  /// Optional supporting caption (e.g. "再存 2 萬").
  final String? caption;

  /// Optional accent color for the progress fill.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.cardMd,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgressTrack(value: progress, color: color),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: context.semantic.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
