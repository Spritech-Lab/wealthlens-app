/// 固定支出 / 繳費 管理 — 使用者自訂名稱 + 金額(不預設類別)。
///
/// 每月固定月支出(§8「有標籤的固定月支出」),名稱與金額都由使用者自填。
/// 舊 seed 資料沒有名稱時,退回顯示類別標籤。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/format.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';
import 'package:wealthlens/design_system/tokens/typography.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/loan.dart';

/// Fallback label for legacy seed rows that have no user-defined name.
String _legacyLabel(LoanType t) => switch (t) {
      LoanType.mortgage => '房貸',
      LoanType.car => '車貸',
      LoanType.personal => '信貸',
      LoanType.cardRevolving => '卡費 / 卡循',
      LoanType.student => '學貸',
    };

String _display(Loan l) => l.name?.isNotEmpty ?? false
    ? l.name!
    : _legacyLabel(l.type);

/// Lists fixed payments with add / edit / delete.
class LoansScreen extends ConsumerWidget {
  /// Creates a [LoansScreen].
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loansProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('固定支出 / 繳費'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新增',
            onPressed: () => showLoanSheet(context, null),
          ),
        ],
      ),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗:$e')),
        data: (loans) {
          if (loans.isEmpty) {
            return const Center(child: Text('尚無固定支出項目,右上角新增'));
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              for (final l in loans) _LoanRow(loan: l),
            ],
          );
        },
      ),
    );
  }
}

class _LoanRow extends ConsumerWidget {
  const _LoanRow({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        onTap: () => showLoanSheet(context, loan),
        leading: Icon(
          Icons.receipt_long_outlined,
          color: context.semantic.info,
        ),
        title: Text(_display(loan)),
        subtitle: Text(
          '每月 ${formatTwd(loan.monthlyPayment)}',
          style: const TextStyle(fontFeatures: AppTypography.tabularFigures),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: context.semantic.warning),
          tooltip: '刪除',
          onPressed: () async {
            await ref.read(wealthRepositoryProvider).deleteLoan(loan.id);
            ref
              ..invalidate(loansProvider)
              ..invalidate(monthlyInvestableProvider)
              ..invalidate(investableBreakdownProvider);
          },
        ),
      ),
    );
  }
}

/// Add ([existing] == null) or edit a fixed payment.
Future<void> showLoanSheet(BuildContext context, Loan? existing) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LoanSheet(existing: existing),
    );

class _LoanSheet extends ConsumerStatefulWidget {
  const _LoanSheet({required this.existing});

  final Loan? existing;

  @override
  ConsumerState<_LoanSheet> createState() => _LoanSheetState();
}

class _LoanSheetState extends ConsumerState<_LoanSheet> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!.monthlyPayment ~/ 100).toString(),
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final digits = _amount.text.replaceAll(RegExp('[^0-9]'), '');
    if (name.isEmpty) {
      setState(() => _error = '請輸入名稱');
      return;
    }
    if (digits.isEmpty) {
      setState(() => _error = '請輸入每月金額');
      return;
    }
    setState(() => _saving = true);
    final existing = widget.existing;
    final id = existing?.id ?? 'loan_${DateTime.now().microsecondsSinceEpoch}';
    await ref.read(wealthRepositoryProvider).upsertLoan(
          Loan(
            id: id,
            // 新項目不預設類別;沿用舊列的 type,新列給中性預設。
            type: existing?.type ?? LoanType.personal,
            name: name,
            monthlyPayment: int.parse(digits) * 100,
          ),
        );
    ref
      ..invalidate(loansProvider)
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
          Text(
            widget.existing == null ? '新增固定支出' : '編輯固定支出',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _name,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '名稱',
              hintText: '例:房租、保險、訂閱',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '每月金額',
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
