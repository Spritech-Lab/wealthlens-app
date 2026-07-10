/// Edit an existing holding — correct quantity / buy price, or delete it.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/holding.dart';

/// Opens the edit sheet for [holding].
Future<void> showEditHoldingSheet(BuildContext context, Holding holding) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditHoldingSheet(holding: holding),
    );

String _trim(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

class _EditHoldingSheet extends ConsumerStatefulWidget {
  const _EditHoldingSheet({required this.holding});

  final Holding holding;

  @override
  ConsumerState<_EditHoldingSheet> createState() => _EditHoldingSheetState();
}

class _EditHoldingSheetState extends ConsumerState<_EditHoldingSheet> {
  late final _qty = TextEditingController(text: _trim(widget.holding.quantity));
  late final _price =
      TextEditingController(text: _trim(widget.holding.avgCost));
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  void _invalidate() => ref
    ..invalidate(investmentHoldingsProvider)
    ..invalidate(correctedHoldingIdsProvider)
    ..invalidate(recentTransactionsProvider);

  Future<void> _save() async {
    final qty = double.tryParse(_qty.text);
    final price = double.tryParse(_price.text);
    if (qty == null || qty <= 0 || price == null || price <= 0) {
      setState(() => _error = '數量與價格需為大於 0 的數字');
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(wealthRepositoryProvider)
        .correctHolding(widget.holding.id, quantity: qty, avgCost: price);
    _invalidate();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('刪除 ${widget.holding.symbol}?'),
        content: const Text('此持股與其交易紀錄將一併移除,無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    await ref.read(wealthRepositoryProvider).deleteHolding(widget.holding.id);
    _invalidate();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isForex = widget.holding.kind == HoldingKind.forex;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '更正 ${widget.holding.symbol}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: '數量',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: isForex ? '買入匯率' : '買入價',
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '處理中…' : '儲存更正'),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: TextButton.icon(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('刪除持股', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}
