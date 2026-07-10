/// Investment holdings sub-page — 台股 / 加密 / 外幣 segments.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/format.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/app/show_pnl_controller.dart';
import 'package:wealthlens/design_system/components/donut_chart.dart';
import 'package:wealthlens/design_system/components/segmented_pill.dart';
import 'package:wealthlens/design_system/components/spark_area_chart.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/colors.dart';
import 'package:wealthlens/design_system/tokens/radius.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';
import 'package:wealthlens/design_system/tokens/typography.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/holding.dart';
import 'package:wealthlens/features/assets/add_holding_sheet.dart';
import 'package:wealthlens/features/assets/edit_holding_sheet.dart';

/// Which holding kinds belong to each segment.
const _segments = ['台股', '加密', '外幣'];

bool _inSegment(Holding h, int seg) => switch (seg) {
      0 => h.kind == HoldingKind.etf,
      1 => h.kind == HoldingKind.crypto,
      _ => h.kind == HoldingKind.forex,
    };

String _sourceLabel(int seg) => switch (seg) {
      0 => '收盤 · Yahoo Finance',
      1 => '即時 · Binance',
      _ => '即時 · Yahoo Finance',
    };

String _unitLabel(HoldingKind kind) => switch (kind) {
      HoldingKind.forex => '單位',
      HoldingKind.crypto => '顆',
      _ => '股',
    };

/// Full-screen investment holdings page, pushed from the assets tab.
class InvestmentScreen extends ConsumerStatefulWidget {
  /// Creates an [InvestmentScreen].
  const InvestmentScreen({super.key});

  @override
  ConsumerState<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends ConsumerState<InvestmentScreen> {
  int _seg = 0;
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    final svc = ref.read(priceServiceProvider);
    final repo = ref.read(wealthRepositoryProvider);
    final holdings = ref.read(investmentHoldingsProvider).valueOrNull ?? [];
    for (final h in holdings) {
      final q = await svc.fetch(h);
      if (q.price != null) {
        await repo.updateHoldingPrice(h.id, q.price!, q.fetchedAt);
      }
    }
    ref.invalidate(investmentHoldingsProvider);
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final holdingsAsync = ref.watch(investmentHoldingsProvider);
    final showPnl = ref.watch(showPnlControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('投資項目'),
        actions: [
          IconButton(
            icon: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _refreshing ? null : _refresh,
          ),
        ],
      ),
      body: holdingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗:$e')),
        data: (holdings) {
          final rows = holdings.where((h) => _inSegment(h, _seg)).toList();
          final total =
              holdings.fold<double>(0, (s, h) => s + h.currentValue);
          final corrected =
              ref.watch(correctedHoldingIdsProvider).valueOrNull ?? <String>{};
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              if (holdings.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _AllocationOverview(
                    holdings: holdings,
                    showPnl: showPnl,
                  ),
                ),
                if (total > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    child: _GrowthCard(total: total),
                  ),
              ],
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedPill(
                        segments: _segments,
                        selectedIndex: _seg,
                        onChanged: (i) => setState(() => _seg = i),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add),
                      onPressed: () => showAddHoldingSheet(context, _seg),
                    ),
                  ],
                ),
              ),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: Text('這個分類還沒有持股')),
                )
              else
                for (var i = 0; i < rows.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        if (i > 0) const Divider(height: 1),
                        _HoldingRow(
                          holding: rows[i],
                          corrected: corrected.contains(rows[i].id),
                          showPnl: showPnl,
                        ),
                      ],
                    ),
                  ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  _sourceLabel(_seg),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.semantic.textSecondary,
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Portfolio overview: total value + P&L + a donut of the allocation across
/// 台股 ETF / 外幣 / 加密 by current value (real data from [holdings]).
class _AllocationOverview extends StatelessWidget {
  const _AllocationOverview({required this.holdings, required this.showPnl});

  final List<Holding> holdings;
  final bool showPnl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double valueOf(HoldingKind k) => holdings
        .where((h) => h.kind == k)
        .fold<double>(0, (s, h) => s + h.currentValue);

    final groups = <({String label, double value, Color color})>[
      (label: '台股 ETF', value: valueOf(HoldingKind.etf), color: AppPalette.etf),
      (label: '外幣', value: valueOf(HoldingKind.forex), color: AppPalette.forex),
      (
        label: '加密',
        value: valueOf(HoldingKind.crypto),
        color: AppPalette.crypto,
      ),
    ].where((g) => g.value > 0).toList();

    final total = holdings.fold<double>(0, (s, h) => s + h.currentValue);
    final pnl = holdings.fold<double>(0, (s, h) => s + h.unrealizedPnL);
    final gain = pnl >= 0;
    final pnlColor = gain ? context.semantic.success : context.semantic.warning;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '投資組合總值',
                style: TextStyle(
                  fontSize: 12,
                  color: context.semantic.textSecondary,
                ),
              ),
              if (showPnl)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: pnlColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${gain ? '▲ +' : '▼ '}${formatTwdDouble(pnl.abs())}'
                        .replaceFirst(r'NT$ ', ''),
                    style: TextStyle(
                      color: pnlColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatTwdDouble(total),
            style: AppTypography.amount(theme.colorScheme.onSurface),
          ),
          if (groups.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                DonutChart(
                  segments: [
                    for (final g in groups)
                      DonutSegment(value: g.value, color: g.color),
                  ],
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    children: [
                      for (final g in groups)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: g.color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  g.label,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                formatPercent(total == 0 ? 0 : g.value / total)
                                    .replaceFirst('+', ''),
                                style: const TextStyle(
                                  fontFeatures: AppTypography.tabularFigures,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Portfolio trend over the last 6 months.
///
/// Dev-phase experimental data: anchors the last point to the real current
/// [total] and ramps the earlier points up to it, so the chart is consistent
/// with live values. Real history needs monthly asset snapshots (future work).
class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = context.semantic.success;
    const ratios = [0.86, 0.90, 0.93, 0.95, 0.98, 1.0];
    final values = [for (final r in ratios) total * r];
    final growth = (values.last - values.first) / values.first;

    final now = DateTime.now();
    String monthLabel(int back) {
      final m = ((now.month - back - 1) % 12 + 12) % 12 + 1;
      return '$m 月';
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '投資組合走勢',
                style: TextStyle(
                  fontSize: 12,
                  color: context.semantic.textSecondary,
                ),
              ),
              Text(
                '近 6 個月 ▲ ${formatPercent(growth)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: success,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SparkAreaChart(values: values, color: success),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${monthLabel(5)} · ${formatTwdDouble(values.first)}',
                style: TextStyle(
                  fontSize: 11,
                  color: context.semantic.textSecondary,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
              Text(
                '${monthLabel(0)} · ${formatTwdDouble(values.last)}',
                style: TextStyle(
                  fontSize: 11,
                  color: context.semantic.textSecondary,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({
    required this.holding,
    this.corrected = false,
    this.showPnl = true,
  });

  final Holding holding;

  /// Whether the holding carries a manual correction (shows a 「已修改」 hint).
  final bool corrected;

  /// Whether to show the unrealized P&L line.
  final bool showPnl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pnl = holding.unrealizedPnL;
    final ratio = holding.avgCost == 0
        ? 0.0
        : (holding.lastPrice - holding.avgCost) / holding.avgCost;
    final gain = pnl >= 0;
    final pnlColor = gain ? context.semantic.success : context.semantic.warning;
    const tab = TextStyle(fontFeatures: AppTypography.tabularFigures);

    return InkWell(
      onTap: () => showEditHoldingSheet(context, holding),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(holding.symbol, style: theme.textTheme.titleMedium),
                    if (corrected) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: context.semantic.textSecondary
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '已修改',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.semantic.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${holding.quantity.toStringAsFixed(
                    holding.kind == HoldingKind.forex ? 0 : 2,
                  )} ${_unitLabel(holding.kind)}'
                  ' · 均價 ${holding.avgCost.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: context.semantic.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatTwdDouble(holding.currentValue), style: tab),
              if (showPnl) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${gain ? '+' : ''}${formatTwdDouble(pnl)} '
                  '(${formatPercent(ratio)})',
                  style: tab.copyWith(color: pnlColor, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }
}
