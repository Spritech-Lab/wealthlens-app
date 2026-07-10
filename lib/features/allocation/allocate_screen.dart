/// 現金流面 → 本月分配(保障優先,帶轉帳提示,剩餘不指派)。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/format.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/colors.dart';
import 'package:wealthlens/design_system/tokens/radius.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';
import 'package:wealthlens/design_system/tokens/typography.dart';
import 'package:wealthlens/domain/allocation/allocation_engine.dart';
import 'package:wealthlens/domain/models/account.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/wallet.dart';
import 'package:wealthlens/features/allocation/edit_fixed_cost_sheet.dart';
import 'package:wealthlens/features/allocation/loans_screen.dart';

/// Runs the allocation engine over this month's investable amount.
class AllocateScreen extends ConsumerWidget {
  /// Creates an [AllocateScreen].
  const AllocateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investable = ref.watch(monthlyInvestableProvider);
    final wallets = ref.watch(homeWalletsProvider);
    final accounts = ref.watch(homeAccountsProvider);
    final breakdown = ref.watch(investableBreakdownProvider);
    final ready = investable.hasValue &&
        wallets.hasValue &&
        accounts.hasValue &&
        breakdown.hasValue;
    return Scaffold(
      appBar: AppBar(title: const Text('本月分配')),
      body: ready
          ? _body(
              context,
              investable.value!,
              wallets.value!,
              accounts.value!,
              breakdown.value!,
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _body(
    BuildContext context,
    int investable,
    List<Wallet> wallets,
    List<Account> accounts,
    ({int income, int living, int loans}) breakdown,
  ) {
    final accountName = {for (final a in accounts) a.id: a.name};
    final walletById = {for (final w in wallets) w.id: w};
    final snaps = [
      for (final w in wallets)
        WalletSnapshot(
          id: w.id,
          category: w.category,
          priorityRank: w.priorityRank,
          current: w.current,
          targetAmount: w.targetAmount,
          monthlyContribution: w.monthlyContribution,
          hasPeriod: w.period != null,
        ),
    ];
    final result = AllocationEngine.allocate(
      AllocationInput(
        investableAmount: investable,
        wallets: snaps,
        remainingMonthsThisYear: 6,
      ),
    );
    final rows = result.allocations.entries.where((e) => e.value > 0).toList();

    final theme = Theme.of(context);
    final cardBorder = Border.all(
      color: theme.dividerColor.withValues(alpha: 0.4),
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── 收入 − 本月固定支出 = 可動用(固定支出為顯著項目)──
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.cardLg,
            border: cardBorder,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FlowLine(label: '收入', amount: breakdown.income),
              _FlowLine(
                label: '生活費',
                amount: breakdown.living,
                minus: true,
                onEdit: () =>
                    showEditLivingCostSheet(context, breakdown.living),
              ),
              _FlowLine(
                label: '固定支出/繳費',
                amount: breakdown.loans,
                minus: true,
                icon: Icons.chevron_right,
                onEdit: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const LoansScreen()),
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '本月可動用',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      formatTwd(investable),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.semantic.success,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('分配建議', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '依「保障優先」排序,每包補到月補額或目標差額(取小)',
          style: TextStyle(
            fontSize: 11,
            color: context.semantic.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.cardLg,
            border: cardBorder,
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                _AllocRow(
                  wallet: walletById[rows[i].key],
                  fallbackName: rows[i].key,
                  amount: rows[i].value,
                  accountName: walletById[rows[i].key] == null
                      ? null
                      : accountName[walletById[rows[i].key]!.accountRef],
                  showDivider: i > 0,
                ),
              if (result.surplus > 0)
                _SurplusRow(
                  amount: result.surplus,
                  showDivider: rows.isNotEmpty,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '以上為分配建議,依你的判斷自行轉帳;此頁不會自動異動錢包。',
          style: TextStyle(
            fontSize: 11,
            color: context.semantic.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// A cash-flow line in the 可動用 breakdown: label (optionally editable) and an
/// amount, shown as a deduction when [minus] is true.
class _FlowLine extends StatelessWidget {
  const _FlowLine({
    required this.label,
    required this.amount,
    this.minus = false,
    this.onEdit,
    this.icon = Icons.edit_outlined,
  });

  final String label;
  final int amount;
  final bool minus;
  final VoidCallback? onEdit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label),
              if (onEdit != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(icon, size: 16, color: context.semantic.info),
              ],
            ],
          ),
          Text(
            '${minus ? '− ' : ''}${formatBare(amount)}',
            style: TextStyle(
              color: minus ? context.semantic.textSecondary : null,
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
        ],
      ),
    );
    if (onEdit == null) return row;
    return InkWell(onTap: onEdit, child: row);
  }
}

/// One suggestion row: rank badge + name + basis line + transfer destination,
/// with the allocated amount on the right.
class _AllocRow extends StatelessWidget {
  const _AllocRow({
    required this.wallet,
    required this.fallbackName,
    required this.amount,
    required this.accountName,
    required this.showDivider,
  });

  final Wallet? wallet;
  final String fallbackName;
  final int amount;
  final String? accountName;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final w = wallet;
    final isSafety = w != null &&
        (w.category == WalletCategory.financialSafety ||
            w.category == WalletCategory.lifeSafety);
    final rankColor =
        isSafety ? AppPalette.lightWarning : AppPalette.lightSuccess;
    final gap = w == null ? 0 : (w.targetAmount - w.current).clamp(0, 1 << 62);

    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(top: BorderSide(color: Theme.of(context).dividerColor))
            : null,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (w != null) ...[
                      Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rankColor,
                          borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                        ),
                        child: Text(
                          '${w.priorityRank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      w?.name ?? fallbackName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (w != null) ...[
                  const SizedBox(height: AppSpacing.xs + 1),
                  Text(
                    '月補 ${formatBare(w.monthlyContribution)} · '
                    '距目標還差 ${formatBare(gap)} → 取 ${formatBare(amount)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.semantic.textSecondary,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                ],
                if (accountName != null) ...[
                  const SizedBox(height: AppSpacing.xs + 1),
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: context.semantic.info,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '轉 ${formatBare(amount)} 到 $accountName',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.semantic.info,
                          fontFeatures: AppTypography.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            formatBare(amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

/// The "剩餘(可運用)" row — released, not auto-assigned.
class _SurplusRow extends StatelessWidget {
  const _SurplusRow({required this.amount, required this.showDivider});

  final int amount;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textSecondary;
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(top: BorderSide(color: Theme.of(context).dividerColor))
            : null,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '剩餘(可運用)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs + 1),
                Text(
                  '月補額已補滿,釋出不自動指派,由你決定去向',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            formatBare(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: muted,
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
