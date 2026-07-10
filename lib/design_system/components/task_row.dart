/// A check-off task row with a restrained bounce on completion.
library;

import 'package:flutter/material.dart';
import 'package:wealthlens/design_system/motion_policy.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/durations.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';

/// A single monthly task with a tap-to-complete checkbox.
///
/// The checkbox bounces on completion unless reduce-motion is on (routed
/// through [MotionPolicy]).
class TaskRow extends StatelessWidget {
  /// Creates a [TaskRow].
  const TaskRow({
    required this.title,
    required this.isDone,
    required this.onToggle,
    this.onTap,
    this.trailing,
    super.key,
  });

  /// Task label.
  final String title;

  /// Whether the task is complete.
  final bool isDone;

  /// Called when the checkbox is tapped (toggles completion).
  final VoidCallback onToggle;

  /// Called when the row body is tapped (e.g. show transfer destination).
  ///
  /// Falls back to [onToggle] when null, so the whole row toggles.
  final VoidCallback? onTap;

  /// Optional trailing widget (e.g. an amount).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final success = context.semantic.success;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap ?? onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: AnimatedScale(
                scale: isDone ? 1.0 : 0.92,
                duration: MotionPolicy.fast(context),
                curve: AppDurations.easeOutBack,
                child: Icon(
                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isDone ? success : context.semantic.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: onSurface,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: context.semantic.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
