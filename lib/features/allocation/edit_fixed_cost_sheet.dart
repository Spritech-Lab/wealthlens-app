/// Edit the monthly living expense (fixed cost) that reduces 可動用.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';
import 'package:wealthlens/domain/models/fixed_cost.dart';

/// Opens the living-expense editor, pre-filled with [currentCents].
Future<void> showEditLivingCostSheet(BuildContext context, int currentCents) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditFixedCostSheet(currentCents: currentCents),
    );

class _EditFixedCostSheet extends ConsumerStatefulWidget {
  const _EditFixedCostSheet({required this.currentCents});

  final int currentCents;

  @override
  ConsumerState<_EditFixedCostSheet> createState() =>
      _EditFixedCostSheetState();
}

class _EditFixedCostSheetState extends ConsumerState<_EditFixedCostSheet> {
  late final _ctrl =
      TextEditingController(text: (widget.currentCents ~/ 100).toString());
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final digits = _ctrl.text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) {
      setState(() => _error = '請輸入金額');
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(wealthRepositoryProvider)
        .setFixedCost(FixedCost(livingExpense: int.parse(digits) * 100));
    ref
      ..invalidate(monthlyInvestableProvider)
      ..invalidate(investableBreakdownProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
          const Text(
            '每月生活費',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            '整筆固定生活支出,會從收入先扣得出可動用',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '金額',
              prefixText: r'NT$ ',
              border: OutlineInputBorder(),
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
              child: Text(_saving ? '處理中…' : '儲存'),
            ),
          ),
        ],
      ),
    );
  }
}
