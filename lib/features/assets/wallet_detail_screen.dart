/// 錢包詳情(方案 B):紀錄藏在此頁的「交易紀錄」區。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/format.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/design_system/components/progress_track.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';
import 'package:wealthlens/design_system/tokens/typography.dart';
import 'package:wealthlens/domain/models/wallet.dart';

/// Wallet detail page; transaction history lives here (option B).
class WalletDetailScreen extends ConsumerWidget {
  /// Creates a [WalletDetailScreen].
  const WalletDetailScreen({required this.wallet, super.key});

  /// The wallet to show.
  final Wallet wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final txnsAsync = ref.watch(walletTransactionsProvider(wallet.id));
    return Scaffold(
      appBar: AppBar(title: Text(wallet.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            '目標 ${formatTwd(wallet.targetAmount)}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '已存 ${formatTwd(wallet.current)}',
            style: TextStyle(color: context.semantic.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          ProgressTrack(value: wallet.progress),
          const SizedBox(height: AppSpacing.xl),
          Text('交易紀錄', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          txnsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('載入失敗:$e'),
            data: (txns) {
              if (txns.isEmpty) {
                return Text(
                  '尚無交易紀錄',
                  style: TextStyle(color: context.semantic.textSecondary),
                );
              }
              return Column(
                children: [
                  for (final t in txns)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_date(t.date)} ${t.kind}',
                            style: TextStyle(
                              color: context.semantic.textSecondary,
                            ),
                          ),
                          Text(
                            (t.amount >= 0 ? '+' : '') + formatTwd(t.amount),
                            style: TextStyle(
                              color: t.amount >= 0
                                  ? context.semantic.success
                                  : context.semantic.warning,
                              fontFeatures: AppTypography.tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}';
}
