/// 資產面 → 按帳戶看(對帳)。account.balance == Σ wallet.current (INV-1)。
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
import 'package:wealthlens/domain/models/account.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/wallet.dart';
import 'package:wealthlens/features/assets/add_account_sheet.dart';
import 'package:wealthlens/features/assets/add_wallet_sheet.dart';
import 'package:wealthlens/features/assets/wallet_detail_screen.dart';

/// Lists accounts and their wallets; account balance reconciles to Σ wallet
/// current (INV-1). Tapping a wallet opens its detail (with 交易紀錄).
class ReconcileScreen extends ConsumerWidget {
  /// Creates a [ReconcileScreen].
  const ReconcileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(homeAccountsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('按帳戶看(對帳)'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新增帳戶'),
            onPressed: () => showAddAccountSheet(context),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗:$e')),
        data: (accounts) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            for (final a in accounts) _AccountBlock(account: a),
          ],
        ),
      ),
    );
  }
}

/// One account card: header (icon + name + type + total) over its wallet rows
/// and a dashed "在此帳戶建錢包" row. Account total reconciles to Σ wallet
/// current (INV-1).
class _AccountBlock extends StatelessWidget {
  const _AccountBlock({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.cardLg,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: context.semantic.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                    ),
                    child: Icon(
                      _iconFor(account.type),
                      size: 20,
                      color: context.semantic.info,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Builder(
                    builder: (context) {
                      final caption =
                          account.institution ?? _typeLabel(account.type);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          // Hide a caption that merely repeats the name
                          // (e.g. an account literally named "券商").
                          if (caption != account.name)
                            Text(
                              caption,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.semantic.textSecondary,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const Spacer(),
                  Text(
                    formatTwd(account.balance),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    icon: const Icon(Icons.published_with_changes, size: 16),
                    label: const Text('對帳'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.semantic.info,
                      backgroundColor:
                          context.semantic.info.withValues(alpha: 0.1),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: account.wallets.isEmpty
                        ? null
                        : () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (_) => _ReconcileSheet(account: account),
                            ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── Wallet rows ──
            for (final w in account.wallets)
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WalletDetailScreen(wallet: w),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: _dotFor(w.category),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Text(
                        w.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatTwd(w.current),
                        style: const TextStyle(
                          fontFeatures: AppTypography.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // ── Dashed "build wallet" row ──
            InkWell(
              onTap: () => showAddWalletSheet(
                context,
                accountId: account.id,
                accountName: account.name,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 17, color: context.semantic.info),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      '在此帳戶建錢包',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.semantic.info,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(AccountType t) => switch (t) {
        AccountType.cash => Icons.account_balance,
        AccountType.brokerage => Icons.show_chart,
        AccountType.exchange => Icons.currency_exchange,
        AccountType.physical => Icons.savings,
      };

  static String _typeLabel(AccountType t) => switch (t) {
        AccountType.cash => '銀行 / 現金',
        AccountType.brokerage => '券商',
        AccountType.exchange => '交易所',
        AccountType.physical => '實體資產',
      };

  static Color _dotFor(WalletCategory c) => switch (c) {
        WalletCategory.financialSafety => AppPalette.lightWarning,
        WalletCategory.lifeSafety => AppPalette.lightInfo,
        WalletCategory.savingGoal => AppPalette.lightSuccess,
      };
}

/// Bottom sheet to reconcile an account: the user types the real balance, sees
/// whether the record is too low/high, and confirms. The difference lands in a
/// chosen wallet (account.balance is derived — INV-1).
class _ReconcileSheet extends ConsumerStatefulWidget {
  const _ReconcileSheet({required this.account});

  final Account account;

  @override
  ConsumerState<_ReconcileSheet> createState() => _ReconcileSheetState();
}

class _ReconcileSheetState extends ConsumerState<_ReconcileSheet> {
  final _controller = TextEditingController();

  /// User-chosen wallet. Null until picked; surplus (補入) falls back to a
  /// default, but a deduction (扣除) must be chosen explicitly (the 守則).
  String? _targetWalletId;
  bool _saving = false;

  Wallet _defaultTarget() {
    final ws = widget.account.wallets;
    return ws.firstWhere(
      (w) => RegExp('留存|備用|未分配').hasMatch(w.name),
      orElse: () => ws.firstWhere(
        (w) => w.category == WalletCategory.financialSafety,
        orElse: () => ws.first,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Parsed actual balance in cents, or null when the field is blank/invalid.
  int? get _actualCents {
    final digits = _controller.text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.parse(digits) * 100;
  }

  /// The wallet that absorbs the adjustment for [delta], or null when the user
  /// must still choose. 守則:扣除(實際 < 帳面)一定要使用者明選來源,不自動帶;
  /// 補入或單一錢包帳戶可帶預設。
  String? _effectiveTarget(int delta) {
    final ws = widget.account.wallets;
    if (ws.length == 1) return ws.first.id;
    if (_targetWalletId != null) return _targetWalletId;
    if (delta < 0) return null;
    return _defaultTarget().id;
  }

  Future<void> _confirm(String target) async {
    final actual = _actualCents;
    if (actual == null) return;
    setState(() => _saving = true);
    final repo = ref.read(wealthRepositoryProvider);
    final delta =
        await repo.reconcileAccount(widget.account.id, actual, target);
    ref
      ..invalidate(homeAccountsProvider)
      ..invalidate(homeWalletsProvider);
    if (!mounted) return;
    Navigator.of(context).pop();
    final targetName =
        widget.account.wallets.firstWhere((w) => w.id == target).name;
    final sign = delta > 0 ? '+' : '';
    final verb = delta > 0 ? '記入' : '扣自';
    final msg = delta == 0
        ? '餘額與記錄相符,未變動'
        : '已對帳:差額 $sign${formatBare(delta)} $verb「$targetName」';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final recorded = account.balance;
    final actual = _actualCents;
    final delta = actual == null ? null : actual - recorded;
    final secondary = context.semantic.textSecondary;
    final isDeduction = delta != null && delta < 0;

    final (String diffText, Color diffColor) = switch (delta) {
      null => ('輸入實際餘額以比對', secondary),
      0 => ('與記錄相符', secondary),
      final d when d > 0 => (
          '比記錄多 ${formatBare(d)}(記錄過低,將補入)',
          context.semantic.success,
        ),
      final d => (
          '比記錄少 ${formatBare(-d)}(記錄過高,請選擇要扣哪個錢包)',
          context.semantic.warning,
        ),
    };

    final target = delta == null ? null : _effectiveTarget(delta);
    final targetWallet = target == null
        ? null
        : account.wallets.firstWhere((w) => w.id == target);
    // 扣除金額大於來源錢包餘額 → 會變負,擋下。
    final overdraw =
        isDeduction && targetWallet != null && targetWallet.current < -delta;
    final canConfirm = !_saving &&
        delta != null &&
        delta != 0 &&
        target != null &&
        !overdraw;

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
            '${account.name} · 對帳',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '記錄餘額 ${formatTwd(recorded)}',
            style: TextStyle(fontSize: 12, color: secondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: '實際餘額',
              prefixText: r'NT$ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(diffText, style: TextStyle(fontSize: 12, color: diffColor)),
          if (account.wallets.length > 1 && delta != null && delta != 0) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              isDeduction ? '從哪個錢包扣?(請選擇)' : '差額記入',
              style: TextStyle(fontSize: 12, color: secondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<String>(
              initialValue: target,
              isExpanded: true,
              hint: const Text('請選擇錢包'),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                for (final w in account.wallets)
                  DropdownMenuItem(
                    value: w.id,
                    child: Text('${w.name} · 餘 ${formatBare(w.current)}'),
                  ),
              ],
              onChanged: (v) => setState(() => _targetWalletId = v),
            ),
            if (overdraw)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '此錢包餘額不足,無法扣除這麼多,請改選其他錢包',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.semantic.warning,
                  ),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canConfirm ? () => _confirm(target) : null,
              child: Text(_saving ? '處理中…' : '確認對帳'),
            ),
          ),
        ],
      ),
    );
  }
}
