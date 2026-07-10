/// 歷史紀錄 — 最近的資產變化(跨所有錢包/持股的交易)。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/format.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/typography.dart';

/// Global recent-activity feed.
class HistoryScreen extends ConsumerWidget {
  /// Creates a [HistoryScreen].
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(recentTransactionsProvider);
    final wallets = ref.watch(homeWalletsProvider).valueOrNull ?? [];
    final holdings = ref.watch(investmentHoldingsProvider).valueOrNull ?? [];
    final nameOf = <String, String>{
      for (final w in wallets) w.id: w.name,
      for (final h in holdings) h.id: h.symbol,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('歷史紀錄')),
      body: txnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗:$e')),
        data: (txns) {
          if (txns.isEmpty) {
            return const Center(child: Text('還沒有任何紀錄'));
          }
          return ListView.separated(
            itemCount: txns.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = txns[i];
              final gain = t.amount >= 0;
              return ListTile(
                title: Text('${nameOf[t.ref] ?? t.ref} · ${t.kind}'),
                subtitle: Text(_date(t.date)),
                trailing: Text(
                  (gain ? '+' : '') + formatTwd(t.amount),
                  style: TextStyle(
                    color: gain
                        ? context.semantic.success
                        : context.semantic.warning,
                    fontFeatures: AppTypography.tabularFigures,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}';
}
