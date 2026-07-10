/// 新增持股 modal — 台股輸代碼 / 加密 5-chip / 外幣 4-chip + 數量 + 買入價。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';
import 'package:wealthlens/domain/models/account.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/holding.dart';

/// Shows the add-holding sheet for the given [segment] (0 台股 / 1 加密 / 2 外幣).
Future<void> showAddHoldingSheet(BuildContext context, int segment) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddHoldingSheet(segment: segment),
  );
}

class _AddHoldingSheet extends ConsumerStatefulWidget {
  const _AddHoldingSheet({required this.segment});

  final int segment;

  @override
  ConsumerState<_AddHoldingSheet> createState() => _AddHoldingSheetState();
}

class _AddHoldingSheetState extends ConsumerState<_AddHoldingSheet> {
  final _symbolCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String? _chip;
  String? _accountId;

  static const _cryptoChips = ['BTC', 'ETH', 'USDT', 'BNB', 'SOL'];
  static const _forexChips = ['USD', 'JPY', 'EUR', 'CNY'];

  bool get _isStock => widget.segment == 0;
  bool get _isCrypto => widget.segment == 1;

  String get _title => switch (widget.segment) {
        0 => '新增台股',
        1 => '新增加密',
        _ => '新增外幣',
      };

  HoldingKind get _kind => switch (widget.segment) {
        0 => HoldingKind.etf,
        1 => HoldingKind.crypto,
        _ => HoldingKind.forex,
      };

  String? get _symbol => _isStock ? _symbolCtrl.text.trim() : _chip;

  bool get _valid {
    final sym = _symbol;
    if (sym == null || sym.isEmpty) return false;
    if (_accountId == null) return false;
    return double.tryParse(_qtyCtrl.text) != null &&
        double.tryParse(_priceCtrl.text) != null;
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repo = ref.read(wealthRepositoryProvider);
    final price = double.parse(_priceCtrl.text);
    await repo.addHoldingWithBuy(
      Holding(
        id: 'h_${DateTime.now().millisecondsSinceEpoch}',
        accountRef: _accountId!,
        kind: _kind,
        symbol: _symbol!,
        quantity: double.parse(_qtyCtrl.text),
        avgCost: price,
        lastPrice: price,
        isCapitalGuaranteed: false,
        liquidity: 'high',
      ),
    );
    ref
      ..invalidate(investmentHoldingsProvider)
      ..invalidate(recentTransactionsProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(homeAccountsProvider).valueOrNull ?? <Account>[];
    _accountId ??= accounts
        .where((a) =>
            a.type == AccountType.brokerage || a.type == AccountType.exchange)
        .map((a) => a.id)
        .firstOrNull ??
        accounts.map((a) => a.id).firstOrNull;

    final priceLabel = widget.segment == 2 ? '買入匯率' : '買入價';
    final qtyLabel = widget.segment == 2 ? '數量(單位)' : '數量(股)';

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
          Text(_title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          if (_isStock)
            TextField(
              controller: _symbolCtrl,
              decoration: const InputDecoration(
                labelText: '代碼(例 0050)',
                helperText: '只支援代碼精確匹配,不做名稱模糊搜尋',
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final c in _isCrypto ? _cryptoChips : _forexChips)
                  ChoiceChip(
                    label: Text(c),
                    selected: _chip == c,
                    onSelected: (_) => setState(() => _chip = c),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                  ],
                  decoration: InputDecoration(labelText: qtyLabel),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                  ],
                  decoration: InputDecoration(labelText: priceLabel),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _accountId,
            decoration: const InputDecoration(labelText: '歸到帳戶'),
            items: [
              for (final a in accounts)
                DropdownMenuItem(value: a.id, child: Text(a.name)),
            ],
            onChanged: (v) => setState(() => _accountId = v),
          ),
          const SizedBox(height: AppSpacing.xl),
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
