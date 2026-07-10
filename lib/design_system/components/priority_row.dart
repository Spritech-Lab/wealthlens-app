/// A priority-list row: pinned (safety) or draggable (goal).
library;

import 'package:flutter/material.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';

/// One row in the priority list.
///
/// Safety wallets are pinned (lock icon, ranks 1/2, not draggable); goals show
/// a drag handle that starts a reorder when [dragIndex] is supplied.
class PriorityRow extends StatelessWidget {
  /// Creates a [PriorityRow].
  const PriorityRow({
    required this.name,
    required this.rank,
    required this.pinned,
    this.subtitle,
    this.dragIndex,
    super.key,
  });

  /// Wallet name.
  final String name;

  /// Display rank.
  final int rank;

  /// Whether this row is pinned (safety) vs draggable (goal).
  final bool pinned;

  /// Optional secondary line (e.g. "保障優先,順序固定" or a neutral
  /// deadline note "要往前排嗎?").
  final String? subtitle;

  /// Reorder index for the drag handle. When non-null and not [pinned], the
  /// handle becomes a [ReorderableDragStartListener] so the user can drag it
  /// directly (no long-press on the whole row).
  final int? dragIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handle = Icon(
      pinned ? Icons.push_pin : Icons.drag_handle,
      size: 20,
      color: pinned
          ? context.semantic.textSecondary
          : theme.colorScheme.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xs,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('$rank', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyLarge),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: context.semantic.textSecondary),
                  ),
              ],
            ),
          ),
          if (!pinned && dragIndex != null)
            ReorderableDragStartListener(index: dragIndex!, child: handle)
          else
            handle,
        ],
      ),
    );
  }
}
