/// 新增帳戶 modal — 類型 / 名稱 / 機構 / 主要入帳帳戶(Flow A 第 1 步)。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';
import 'package:wealthlens/domain/models/account.dart';
import 'package:wealthlens/domain/models/enums.dart';

/// Shows the add-account sheet.
Future<void> showAddAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AddAccountSheet(),
  );
}

class _AddAccountSheet extends ConsumerStatefulWidget {
  const _AddAccountSheet();

  @override
  ConsumerState<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<_AddAccountSheet> {
  final _nameCtrl = TextEditingController();
  final _instCtrl = TextEditingController();
  AccountType _type = AccountType.cash;
  bool _isInflowHub = false;

  static const Map<AccountType, String> _typeLabels = {
    AccountType.cash: '現金/銀行',
    AccountType.brokerage: '券商',
    AccountType.exchange: '交易所',
    AccountType.physical: '實體',
  };

  bool get _valid => _nameCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _instCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repo = ref.read(wealthRepositoryProvider);
    await repo.upsertAccount(
      Account(
        id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        type: _type,
        isInflowHub: _isInflowHub,
        institution:
            _instCtrl.text.trim().isEmpty ? null : _instCtrl.text.trim(),
        wallets: const [],
      ),
    );
    ref.invalidate(homeAccountsProvider);
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
          Text('新增帳戶', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final t in AccountType.values)
                ChoiceChip(
                  label: Text(_typeLabels[t]!),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: '名稱'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _instCtrl,
            decoration: const InputDecoration(labelText: '機構(選填)'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('主要入帳帳戶'),
            subtitle: const Text('薪水/收入預設入這個帳戶'),
            value: _isInflowHub,
            onChanged: (v) => setState(() => _isInflowHub = v),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _valid ? _submit : null,
              child: const Text('新增'),
            ),
          ),
        ],
      ),
    );
  }
}
