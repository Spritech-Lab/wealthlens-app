/// 優先序(WF-05)— 保障層釘鎖 1/2,儲蓄目標可拖拉排序(rank 3+)。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/design_system/components/contour_background.dart';
import 'package:wealthlens/design_system/components/priority_row.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/radius.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/wallet.dart';

/// Priority list: safety pinned, goals reorderable.
class PriorityScreen extends ConsumerStatefulWidget {
  /// Creates a [PriorityScreen].
  const PriorityScreen({super.key});

  @override
  ConsumerState<PriorityScreen> createState() => _PriorityScreenState();
}

class _PriorityScreenState extends ConsumerState<PriorityScreen> {
  List<Wallet>? _goals;

  Future<void> _persist() async {
    final repo = ref.read(wealthRepositoryProvider);
    for (var i = 0; i < _goals!.length; i++) {
      await repo.updateWalletRank(_goals![i].id, 3 + i);
    }
    ref.invalidate(homeWalletsProvider);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _goals!.removeAt(oldIndex);
      _goals!.insert(newIndex, item);
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(homeWalletsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('優先序')),
      body: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗:$e')),
        data: (wallets) {
          final safety = wallets
              .where((w) => w.category != WalletCategory.savingGoal)
              .toList()
            ..sort((a, b) => a.priorityRank.compareTo(b.priorityRank));
          _goals ??= wallets
              .where((w) => w.category == WalletCategory.savingGoal)
              .toList()
            ..sort((a, b) => a.priorityRank.compareTo(b.priorityRank));

          final goals = _goals!;
          return Stack(
            children: [
              const ContourBackground(),
              ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const _SectionTitle(
                    '保障層',
                    caption: '保障優先,順序固定(不可調)',
                  ),
                  _CardWrap(
                    child: Column(
                      children: [
                        for (var i = 0; i < safety.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          PriorityRow(
                            name: safety[i].name,
                            rank: safety[i].priorityRank,
                            pinned: true,
                            subtitle: safety[i].category ==
                                    WalletCategory.financialSafety
                                ? '財務保障'
                                : '生活保障',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionTitle(
                    '儲蓄目標',
                    caption: '按住右側手柄上下拖曳排序',
                  ),
                  _CardWrap(
                    child: ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorderItem: _onReorder,
                      children: [
                        for (var i = 0; i < goals.length; i++)
                          Column(
                            key: ValueKey(goals[i].id),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (i > 0) const Divider(height: 1),
                              PriorityRow(
                                name: goals[i].name,
                                rank: 3 + i,
                                pinned: false,
                                dragIndex: i,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A section header with a title and a muted explanatory caption.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.caption});

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            caption,
            style: TextStyle(
              fontSize: 11,
              color: context.semantic.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A surface card wrapper matching the app's card styling.
class _CardWrap extends StatelessWidget {
  const _CardWrap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.cardLg,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}
