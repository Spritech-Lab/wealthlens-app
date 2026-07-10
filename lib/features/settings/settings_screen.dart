/// Settings — theme mode + amount anchoring, persisted.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/anchor_unit_controller.dart';
import 'package:wealthlens/app/font_scale_controller.dart';
import 'package:wealthlens/app/format.dart';
import 'package:wealthlens/app/home_layout_controller.dart';
import 'package:wealthlens/app/lock_controller.dart';
import 'package:wealthlens/app/show_pnl_controller.dart';
import 'package:wealthlens/app/theme_controller.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/features/assets/reconcile_screen.dart';
import 'package:wealthlens/features/lock/pin_sheet.dart';

/// A selectable option for a settings picker.
typedef _Option<T> = ({T value, String label, String? sub});

/// The settings screen. Each preference is a row showing its current value;
/// tapping opens a picker (standard settings pattern).
class SettingsScreen extends ConsumerWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  static const _themeOptions = <_Option<ThemeMode>>[
    (value: ThemeMode.system, label: '跟隨系統', sub: null),
    (value: ThemeMode.light, label: '淺色', sub: null),
    (value: ThemeMode.dark, label: '深色', sub: null),
  ];

  static const _unitOptions = <_Option<AnchorUnit>>[
    (value: AnchorUnit.full, label: '完整數字', sub: '例:15,000'),
    (value: AnchorUnit.thousand, label: '千 (K)', sub: '例:15K'),
    (value: AnchorUnit.wan, label: '萬', sub: '例:1.5 萬'),
  ];

  static const _layoutOptions = <_Option<HomeLayout>>[
    (value: HomeLayout.cards, label: '資訊卡', sub: '目標橫向卡片'),
    (value: HomeLayout.list, label: '列表', sub: '目標/任務直式列表 + 進度條'),
  ];

  static const _fontOptions = <_Option<FontScale>>[
    (value: FontScale.small, label: '小', sub: null),
    (value: FontScale.standard, label: '標準', sub: null),
    (value: FontScale.large, label: '大', sub: null),
    (value: FontScale.xlarge, label: '特大', sub: null),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeControllerProvider);
    final unit = ref.watch(anchorUnitControllerProvider);
    final fontScale = ref.watch(fontScaleControllerProvider);
    final homeLayout = ref.watch(homeLayoutControllerProvider);
    final showPnl = ref.watch(showPnlControllerProvider);
    final lockEnabled = ref.watch(lockControllerProvider).enabled;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          _SettingRow(
            icon: Icons.brightness_6_outlined,
            title: '外觀',
            value: _labelOf(_themeOptions, mode),
            onTap: () async {
              final picked = await _pick(
                context,
                title: '外觀',
                options: _themeOptions,
                current: mode,
              );
              if (picked != null) {
                await ref
                    .read(themeModeControllerProvider.notifier)
                    .set(picked);
              }
            },
          ),
          _SettingRow(
            icon: Icons.dashboard_outlined,
            title: '首頁樣式',
            value: _labelOf(_layoutOptions, homeLayout),
            onTap: () async {
              final picked = await _pick(
                context,
                title: '首頁樣式',
                options: _layoutOptions,
                current: homeLayout,
              );
              if (picked != null) {
                await ref
                    .read(homeLayoutControllerProvider.notifier)
                    .set(picked);
              }
            },
          ),
          _SettingRow(
            icon: Icons.tag,
            title: '金額顯示',
            value: _labelOf(_unitOptions, unit),
            onTap: () async {
              final picked = await _pick(
                context,
                title: '金額顯示',
                options: _unitOptions,
                current: unit,
              );
              if (picked != null) {
                await ref
                    .read(anchorUnitControllerProvider.notifier)
                    .set(picked);
              }
            },
          ),
          _SettingRow(
            icon: Icons.format_size,
            title: '字體大小',
            value: _labelOf(_fontOptions, fontScale),
            onTap: () async {
              final picked = await _pick(
                context,
                title: '字體大小',
                options: _fontOptions,
                current: fontScale,
              );
              if (picked != null) {
                await ref
                    .read(fontScaleControllerProvider.notifier)
                    .set(picked);
              }
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.trending_up),
            title: const Text('顯示盈虧'),
            subtitle: const Text('關閉後不顯示投資盈虧數字'),
            value: showPnl,
            onChanged: (v) =>
                ref.read(showPnlControllerProvider.notifier).set(show: v),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('App 鎖定'),
            subtitle: const Text('開啟後需生物辨識或 PIN 解鎖(背景逾 2 分鐘）'),
            value: lockEnabled,
            onChanged: (v) async {
              final ctl = ref.read(lockControllerProvider.notifier);
              if (v) {
                final pin = await showSetPinSheet(context);
                if (pin != null) await ctl.enable(pin);
              } else {
                final ok = await showVerifyPinSheet(context);
                if (ok ?? false) await ctl.disable();
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('帳戶管理'),
            subtitle: const Text('新增/查看帳戶與錢包(對帳)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReconcileScreen()),
            ),
          ),
        ],
      ),
    );
  }

  static String _labelOf<T>(List<_Option<T>> options, T value) =>
      options.firstWhere((o) => o.value == value).label;

  /// Shows a bottom-sheet picker and returns the chosen value (or null).
  Future<T?> _pick<T>(
    BuildContext context, {
    required String title,
    required List<_Option<T>> options,
    required T current,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  title,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              for (final o in options)
                ListTile(
                  title: Text(o.label),
                  subtitle: o.sub == null ? null : Text(o.sub!),
                  trailing: o.value == current
                      ? Icon(Icons.check, color: sheetContext.semantic.info)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(o.value),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// A settings row: leading icon, title, the current value, and a chevron.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: context.semantic.textSecondary)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
