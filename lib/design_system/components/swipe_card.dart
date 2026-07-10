/// The home digital card — a horizontally swipeable carousel with dots.
library;

import 'package:flutter/material.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/radius.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';
import 'package:wealthlens/design_system/tokens/typography.dart';

/// Tone of the corner pill.
enum SwipeTone {
  /// Gain — success green.
  up,

  /// Loss — warning amber.
  down,

  /// Neutral / no P&L — muted.
  flat,
}

/// The corner pill (gain / loss / neutral).
class SwipePill {
  /// Creates a [SwipePill].
  const SwipePill(this.text, this.tone);

  /// Pill text (e.g. "▲ +3,300").
  final String text;

  /// Visual tone.
  final SwipeTone tone;
}

/// One swipeable face of the home digital card.
class SwipeFace {
  /// Creates a [SwipeFace].
  const SwipeFace({
    required this.label,
    required this.amount,
    required this.onTap,
    this.pill,
  });

  /// Face label (資產 / 投資組合 / 本月可動用).
  final String label;

  /// Pre-formatted main amount.
  final String amount;

  /// Top-right pill; omitted when null.
  final SwipePill? pill;

  /// Called when the active face is tapped.
  final VoidCallback onTap;
}

/// A horizontally swipeable card with a synced dot indicator.
class SwipeCard extends StatefulWidget {
  /// Creates a [SwipeCard].
  const SwipeCard({required this.faces, super.key});

  /// The faces to page through.
  final List<SwipeFace> faces;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            children: [for (final f in widget.faces) _Face(face: f)],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.faces.length; i++)
              Container(
                key: ValueKey('swipe-dot-$i'),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _index
                      ? context.semantic.info
                      : Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.face});

  final SwipeFace face;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pill = face.pill;
    final pillColor = switch (pill?.tone) {
      SwipeTone.up => context.semantic.success,
      SwipeTone.down => context.semantic.warning,
      SwipeTone.flat || null => context.semantic.textSecondary,
    };
    return GestureDetector(
      onTap: face.onTap,
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  face.label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
                if (pill != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: pillColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      pill.text,
                      style: TextStyle(
                        color: pillColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  face.amount,
                  style: AppTypography.amount(theme.colorScheme.onSurface),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: context.semantic.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
