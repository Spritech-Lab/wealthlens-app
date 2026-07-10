/// Home screen — dashboard digital card + goal chips + this month's tasks.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/format.dart';
import 'package:wealthlens/app/home_layout_controller.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/app/show_pnl_controller.dart';
import 'package:wealthlens/design_system/components/contour_background.dart';
import 'package:wealthlens/design_system/components/goal_chip.dart';
import 'package:wealthlens/design_system/components/hero_card.dart';
import 'package:wealthlens/design_system/components/progress_track.dart';
import 'package:wealthlens/design_system/components/swipe_card.dart';
import 'package:wealthlens/design_system/components/task_row.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/radius.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';
import 'package:wealthlens/design_system/tokens/typography.dart';
import 'package:wealthlens/domain/models/account.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/wallet.dart';
import 'package:wealthlens/features/allocation/allocate_screen.dart';
import 'package:wealthlens/features/assets/investment_screen.dart';
import 'package:wealthlens/features/assets/reconcile_screen.dart';
import 'package:wealthlens/features/goals/priority_screen.dart';

/// The single-page home view.
class HomeScreen extends ConsumerWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(homeWalletsProvider);
    return walletsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('載入失敗:$e')),
      data: (wallets) => _HomeBody(wallets: wallets),
    );
  }
}

class _HomeBody extends ConsumerStatefulWidget {
  const _HomeBody({required this.wallets});

  final List<Wallet> wallets;

  @override
  ConsumerState<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<_HomeBody> {
  final _doneTasks = <String>{};

  @override
  Widget build(BuildContext context) {
    final wallets = widget.wallets;
    final holdings = ref.watch(investmentHoldingsProvider).valueOrNull ?? [];
    final investable = ref.watch(monthlyInvestableProvider).valueOrNull ?? 0;
    final accounts = ref.watch(homeAccountsProvider).valueOrNull ?? [];
    final accountOf = {for (final a in accounts) a.id: a};
    final showPnl = ref.watch(showPnlControllerProvider);
    final layout = ref.watch(homeLayoutControllerProvider);

    final invTotal = holdings.fold<double>(0, (s, h) => s + h.currentValue);
    final invPnl = holdings.fold<double>(0, (s, h) => s + h.unrealizedPnL);
    final cashTotal = wallets.fold<int>(0, (s, w) => s + w.current);
    final assetTotal = cashTotal + (invTotal * 100).round();

    bool achieved(Wallet w) =>
        w.targetAmount > 0 && w.current >= w.targetAmount;

    final goalsAll = wallets.where((w) => w.targetAmount > 0).toList();
    // 保障層(維持性,達標也保留並標記),照 rank 排。
    final safetyGoals = goalsAll
        .where((w) => w.category != WalletCategory.savingGoal)
        .toList()
      ..sort((a, b) => a.priorityRank.compareTo(b.priorityRank));
    // 進行中的儲蓄目標(達標的移到「已達成」)。
    final activeSaving = goalsAll
        .where((w) => w.category == WalletCategory.savingGoal && !achieved(w))
        .toList()
      ..sort((a, b) => a.priorityRank.compareTo(b.priorityRank));
    // 已達成:儲蓄目標達標(§3 達標歸位)→ 收合區。
    final achievedGoals = goalsAll
        .where((w) => w.category == WalletCategory.savingGoal && achieved(w))
        .toList();
    // 達標的目標不再需要轉帳,從本月任務移除。
    final tasks = wallets
        .where((w) => w.monthlyContribution > 0 && !achieved(w))
        .toList();

    final pnlPill = SwipePill(
      _pnlText(invPnl),
      invPnl >= 0 ? SwipeTone.up : SwipeTone.down,
    );

    return Stack(
      children: [
        const ContourBackground(),
        ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            HeroCard(
              label: '資產',
              amount: formatTwd(assetTotal),
              // 資產卡不顯示投資盈虧(投資組合卡已顯示)。
              onTap: () => _push(context, const ReconcileScreen()),
            ),
            const SizedBox(height: AppSpacing.md),
            SwipeCard(
              faces: [
                SwipeFace(
                  label: '投資組合',
                  amount: formatTwdDouble(invTotal),
                  pill: showPnl ? pnlPill : null,
                  onTap: () => _push(context, const InvestmentScreen()),
                ),
                SwipeFace(
                  label: '本月可動用',
                  amount: formatTwd(investable),
                  pill: const SwipePill('尚未分配', SwipeTone.flat),
                  onTap: () => _push(context, const AllocateScreen()),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('保障與目標', style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              onPressed: () => _push(context, const PriorityScreen()),
              child: const Text('排序'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (safetyGoals.isNotEmpty)
          _goalGroup(context, '保障', safetyGoals, layout),
        if (safetyGoals.isNotEmpty && activeSaving.isNotEmpty)
          const SizedBox(height: AppSpacing.lg),
        if (activeSaving.isNotEmpty)
          _goalGroup(context, '目標', activeSaving, layout),
        const SizedBox(height: AppSpacing.xl),
        Text('本月任務', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final w in tasks)
          if (layout == HomeLayout.cards)
            _taskRow(context, w, accountOf)
          else
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                children: [
                  _taskRow(context, w, accountOf),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 34,
                      right: AppSpacing.xs,
                      bottom: AppSpacing.xs,
                    ),
                    child: ProgressTrack(value: w.progress, height: 6),
                  ),
                ],
              ),
            ),
          if (achievedGoals.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _AchievedGoals(goals: achievedGoals),
          ],
          ],
        ),
      ],
    );
  }

  void _push(BuildContext context, Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => screen));

  void _toggle(String id) => setState(() {
        _doneTasks.contains(id) ? _doneTasks.remove(id) : _doneTasks.add(id);
      });

  /// A labelled goal group (保障 / 目標), rendered as chips or a progress list.
  Widget _goalGroup(
    BuildContext context,
    String label,
    List<Wallet> goals,
    HomeLayout layout,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.semantic.textSecondary,
            ),
          ),
        ),
        if (layout == HomeLayout.cards)
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: goals.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) {
                final w = goals[i];
                final done =
                    w.targetAmount > 0 && w.current >= w.targetAmount;
                return GoalChip(
                  name: w.name,
                  progress: w.progress,
                  caption: done ? '已達標 ✓' : '已存 ${formatTwd(w.current)}',
                );
              },
            ),
          )
        else
          _GoalProgressList(chips: goals),
      ],
    );
  }

  /// The shared task row, used by both card and list layouts.
  Widget _taskRow(
    BuildContext context,
    Wallet w,
    Map<String, Account> accountOf,
  ) {
    return TaskRow(
      title: '轉 ${formatTwd(w.monthlyContribution)} 到 ${w.name}',
      isDone: _doneTasks.contains(w.id),
      onToggle: () => _toggle(w.id),
      onTap: () => _showTransfer(context, w, accountOf[w.accountRef]),
      trailing: Text(
        formatTwd(w.monthlyContribution),
        style: const TextStyle(fontFeatures: AppTypography.tabularFigures),
      ),
    );
  }

  /// Shows where this month's task transfer should go: the wallet's owning
  /// account (the bank/exchange to move money to).
  void _showTransfer(BuildContext context, Wallet w, Account? account) {
    final done = _doneTasks.contains(w.id);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final secondary = sheetContext.semantic.textSecondary;
        final dest = account == null
            ? w.name
            : (account.institution == null
                ? account.name
                : '${account.name}(${account.institution})');
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('本月任務', style: TextStyle(fontSize: 12, color: secondary)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '轉 ${formatTwd(w.monthlyContribution)} 到「${w.name}」',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: sheetContext.semantic.info.withValues(alpha: 0.08),
                    borderRadius: AppRadius.cardLg,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        color: sheetContext.semantic.info,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '轉帳到',
                              style: TextStyle(fontSize: 11, color: secondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dest,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      _toggle(w.id);
                      Navigator.of(sheetContext).pop();
                    },
                    child: Text(done ? '取消完成' : '標記完成'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _pnlText(double pnl) {
    final up = pnl >= 0;
    final amount = formatTwdDouble(pnl.abs()).replaceFirst(r'NT$ ', '');
    return '${up ? '▲' : '▼'} $amount';
  }
}

/// 保障與目標的列表模式:每個目標一列,名稱 + 已存/百分比 + 進度條。
class _GoalProgressList extends StatelessWidget {
  const _GoalProgressList({required this.chips});

  final List<Wallet> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.cardLg,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chips[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        chips[i].targetAmount > 0 &&
                                chips[i].current >= chips[i].targetAmount
                            ? '已達標 ✓'
                            : '已存 ${formatTwd(chips[i].current)} · '
                                '${(chips[i].progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.semantic.textSecondary,
                          fontFeatures: AppTypography.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ProgressTrack(value: chips[i].progress, height: 8),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 已達成的儲蓄目標(§3 達標歸位)—— 收合區塊,預設收起。
class _AchievedGoals extends StatelessWidget {
  const _AchievedGoals({required this.goals});

  final List<Wallet> goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = context.semantic.success;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.cardLg,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.emoji_events_outlined, color: success),
          title: Text(
            '已達成 (${goals.length})',
            style: theme.textTheme.titleMedium,
          ),
          childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
          children: [
            for (final w in goals)
              ListTile(
                dense: true,
                leading: Icon(Icons.check_circle, color: success, size: 20),
                title: Text(w.name),
                trailing: Text(
                  formatTwd(w.current),
                  style: const TextStyle(
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
