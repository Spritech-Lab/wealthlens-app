/// The fixed asset Hero card — blue gradient, white figures.
library;

import 'package:flutter/material.dart';
import 'package:wealthlens/design_system/components/swipe_card.dart';
import 'package:wealthlens/design_system/tokens/radius.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';
import 'package:wealthlens/design_system/tokens/typography.dart';

/// The top-of-home asset card: blue gradient surface, big white amount, a
/// translucent P&L pill, and a decorative corner circle. Tapping opens the
/// reconcile (按帳戶看) screen.
class HeroCard extends StatelessWidget {
  /// Creates a [HeroCard].
  const HeroCard({
    required this.label,
    required this.amount,
    required this.onTap,
    this.pill,
    super.key,
  });

  /// Card label (e.g. 資產).
  final String label;

  /// Pre-formatted main amount.
  final String amount;

  /// Top-right P&L pill; omitted when null.
  final SwipePill? pill;

  /// Tap handler.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? const [Color(0xFF23628F), Color(0xFF163B57)]
          : const [Color(0xFF2A7AC0), Color(0xFF155291)],
    );
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF155291)
                  .withValues(alpha: dark ? 0.5 : 0.4),
              blurRadius: 30,
              spreadRadius: -8,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
          child: Stack(
            children: [
              // Decorative corner circle.
              Positioned(
                right: -30,
                top: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (pill != null) _HeroPill(pill!),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(amount, style: AppTypography.amount(Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill(this.pill);

  final SwipePill pill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        pill.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFeatures: AppTypography.tabularFigures,
        ),
      ),
    );
  }
}
