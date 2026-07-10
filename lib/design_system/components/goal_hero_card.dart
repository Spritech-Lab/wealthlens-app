/// The home hero card for the single primary goal.
library;

import 'package:flutter/material.dart';
import 'package:wealthlens/design_system/components/progress_track.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/radius.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';

/// The prominent card for the app-wide primary goal.
///
/// Leads with the goal, frames progress as accumulation, and shows an
/// encouraging narrative. The star toggles which goal is primary.
class GoalHeroCard extends StatelessWidget {
  /// Creates a [GoalHeroCard].
  const GoalHeroCard({
    required this.name,
    required this.progress,
    required this.narrative,
    required this.isPrimary,
    required this.onToggleStar,
    this.icon = Icons.flag,
    super.key,
  });

  /// Goal name.
  final String name;

  /// Progress ratio 0–1.
  final double progress;

  /// Encouraging line, e.g. "再存 2 萬就能出發".
  final String narrative;

  /// Whether this goal is the primary one (filled star).
  final bool isPrimary;

  /// Called when the star is tapped.
  final VoidCallback onToggleStar;

  /// Leading goal icon.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.cardLg,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: context.semantic.info),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(name, style: theme.textTheme.titleLarge),
              ),
              IconButton(
                icon: Icon(isPrimary ? Icons.star : Icons.star_border),
                color: context.semantic.warning,
                onPressed: onToggleStar,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ProgressTrack(value: progress, height: 14),
          const SizedBox(height: AppSpacing.md),
          Text(
            narrative,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: context.semantic.success),
          ),
        ],
      ),
    );
  }
}
