/// 新增錢包 modal — 用途分類 / 名稱 / 歸帳戶(預填)/ 目標 / 期限 / 月補額。
///
/// priorityRank 由系統決定:保障層鎖 1/2,儲蓄目標 = 現有目標最大 rank + 1
/// (modal 不收 rank)。Flow A 第 2 步。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/wallet.dart';

/// Shows the add-wallet sheet bound to an account.
Future<void> showAddWalletSheet(
  BuildContext context, {
  required String accountId,
  required String accountName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _AddWalletSheet(accountId: accountId, accountName: accountName),
  );
}

class _AddWalletSheet extends ConsumerStatefulWidget {
  const _AddWalletSheet({required this.accountId, required this.accountName});

  final String accountId;
  final String accountName;

  @override
  ConsumerState<_AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends ConsumerState<_AddWalletSheet> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _periodCtrl = TextEditingController();
  final _monthlyCtrl = TextEditingController();
  WalletCategory _category = WalletCategory.savingGoal;

  static const Map<WalletCategory, String> _catLabels = {
    WalletCategory.financialSafety: '財務保障',
    WalletCategory.lifeSafety: '生活保障',
    WalletCategory.savingGoal: '儲蓄目標',
  };

  bool get _isSafety => _category != WalletCategory.savingGoal;

  bool get _valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      int.tryParse(_targetCtrl.text) != null &&
      int.tryParse(_monthlyCtrl.text) != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _periodCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  int _rankFor(List<Wallet> existing) => switch (_category) {
        WalletCategory.financialSafety => 1,
        WalletCategory.lifeSafety => 2,
        WalletCategory.savingGoal => existing
                .where((w) => w.category == WalletCategory.savingGoal)
                .map((w) => w.priorityRank)
                .fold(2, math.max) +
            1,
      };

  Future<void> _submit() async {
    final repo = ref.read(wealthRepositoryProvider);
    final existing = await repo.allWallets();
    final period = _periodCtrl.text.trim();
    await repo.insertWallet(
      Wallet(
        id: 'w_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        accountRef: widget.accountId,
        category: _category,
        current: 0,
        targetAmount: int.parse(_targetCtrl.text) * 100,
        monthlyContribution: int.parse(_monthlyCtrl.text) * 100,
        priorityRank: _rankFor(existing),
        isPrimary: false,
        period: period.isEmpty ? null : period,
      ),
    );
    ref
      ..invalidate(homeWalletsProvider)
      ..invalidate(homeAccountsProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('在 ${widget.accountName} 建錢包',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final c in WalletCategory.values)
                ChoiceChip(
                  label: Text(_catLabels[c]!),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          if (_isSafety)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                '保障層:排序鎖 1/2、不算報酬率',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: '名稱'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: '歸到帳戶',
              hintText: widget.accountName,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _targetCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: '目標金額(元)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _monthlyCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: '每月補額(元)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _periodCtrl,
            decoration: const InputDecoration(
              labelText: '期限(選填 YYYY-MM)',
              hintText: '2027-06',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _valid ? _submit : null,
              child: const Text('建立'),
            ),
          ),
        ],
      ),
    );
  }
}
