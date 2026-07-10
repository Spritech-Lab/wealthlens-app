/// A single allocation line with its transfer hint.
library;

import 'package:flutter/material.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';

/// One wallet's allocated amount plus the "請轉帳 X 元到 {帳戶}" hint.
class AllocationRow extends StatelessWidget {
  /// Creates an [AllocationRow].
  const AllocationRow({
    required this.walletName,
    required this.amountLabel,
    required this.transferHint,
    super.key,
  });

  /// Destination wallet name.
  final String walletName;

  /// Pre-formatted amount (e.g. "NT$ 15,000").
  final String amountLabel;

  /// Transfer instruction string.
  final String transferHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(walletName, style: theme.textTheme.titleSmall),
              Text(
                amountLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.swap_horiz,
                size: 14,
                color: context.semantic.info,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  transferHint,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: context.semantic.info),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
