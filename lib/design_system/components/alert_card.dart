/// A dismissible, in-app alert card (never a system notification).
library;

import 'package:flutter/material.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/radius.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';

/// A collapsible home alert card with a neutral, non-judgmental tone.
class AlertCard extends StatelessWidget {
  /// Creates an [AlertCard].
  const AlertCard({
    required this.icon,
    required this.title,
    required this.message,
    this.onDismiss,
    this.accent,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// Short title.
  final String title;

  /// Body message (states facts, never scolds).
  final String message;

  /// Called when the card is collapsed/dismissed.
  final VoidCallback? onDismiss;

  /// Optional accent color; defaults to the info color.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? context.semantic.info;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.cardMd,
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
