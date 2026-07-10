/// Design-system gallery — run with `flutter run -t lib/gallery.dart`.
///
/// A standalone preview of tokens and components in light and dark modes.
library;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:wealthlens/design_system/components/alert_card.dart';
import 'package:wealthlens/design_system/components/allocation_row.dart';
import 'package:wealthlens/design_system/components/category_icon.dart';
import 'package:wealthlens/design_system/components/goal_chip.dart';
import 'package:wealthlens/design_system/components/goal_hero_card.dart';
import 'package:wealthlens/design_system/components/priority_row.dart';
import 'package:wealthlens/design_system/components/progress_track.dart';
import 'package:wealthlens/design_system/components/segmented_pill.dart';
import 'package:wealthlens/design_system/components/task_row.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/design_system/tokens/colors.dart';
import 'package:wealthlens/design_system/tokens/spacing.dart';
import 'package:wealthlens/design_system/tokens/typography.dart';

void main() => runApp(const GalleryApp());

/// Root of the gallery preview app.
class GalleryApp extends StatefulWidget {
  /// Creates the gallery app.
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _mode,
      home: _GalleryHome(
        mode: _mode,
        onToggle: () => setState(
          () => _mode =
              _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
        ),
      ),
    );
  }
}

class _GalleryHome extends StatefulWidget {
  const _GalleryHome({required this.mode, required this.onToggle});

  final ThemeMode mode;
  final VoidCallback onToggle;

  @override
  State<_GalleryHome> createState() => _GalleryHomeState();
}

class _GalleryHomeState extends State<_GalleryHome> {
  int _segment = 0;
  bool _taskDone = false;
  bool _primary = true;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.mode == ThemeMode.dark;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('WealthLens — Design System'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggle,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _section(context, '色票'),
          _swatches(context, const [
            ('ETF', AppPalette.etf),
            ('基金', AppPalette.fund),
            ('加密', AppPalette.crypto),
            ('外幣', AppPalette.forex),
            ('黃金', AppPalette.gold),
          ]),
          const SizedBox(height: AppSpacing.xl),

          _section(context, 'SegmentedPill'),
          SegmentedPill(
            segments: const ['任務', '資產', '紀錄'],
            selectedIndex: _segment,
            onChanged: (i) => setState(() => _segment = i),
          ),
          const SizedBox(height: AppSpacing.xl),

          _section(context, 'GoalHeroCard'),
          GoalHeroCard(
            name: '出國',
            progress: 0.34,
            narrative: '再存 8 萬就能出發',
            isPrimary: _primary,
            icon: Symbols.flight_takeoff,
            onToggleStar: () => setState(() => _primary = !_primary),
          ),
          const SizedBox(height: AppSpacing.xl),

          _section(context, 'GoalChip + ProgressTrack'),
          Row(
            children: [
              const GoalChip(name: '備用金', progress: 0.4, caption: '已存 12 萬'),
              const SizedBox(width: AppSpacing.md),
              GoalChip(
                name: '年度儲蓄',
                progress: 0.21,
                caption: '本月應存 2 萬',
                color: context.semantic.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const ProgressTrack(value: 0.5, overlay: 0.7),
          const SizedBox(height: AppSpacing.xl),

          _section(context, 'TaskRow'),
          TaskRow(
            title: '轉 1 萬到備用金',
            isDone: _taskDone,
            onToggle: () => setState(() => _taskDone = !_taskDone),
            trailing: const Text(
              r'NT$ 10,000',
              style: TextStyle(fontFeatures: AppTypography.tabularFigures),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _section(context, 'AllocationRow'),
          const AllocationRow(
            walletName: '出國',
            amountLabel: r'NT$ 15,000',
            transferHint: '請轉帳 15,000 元到 永豐',
          ),
          const SizedBox(height: AppSpacing.lg),

          _section(context, 'PriorityRow'),
          const PriorityRow(name: '備用金', rank: 1, pinned: true),
          const PriorityRow(
            name: '出國',
            rank: 3,
            pinned: false,
            subtitle: '進度偏慢 · 要往前排嗎?',
          ),
          const SizedBox(height: AppSpacing.lg),

          _section(context, 'CategoryIcon'),
          const Row(
            children: [
              CategoryIcon(icon: Symbols.savings, color: AppPalette.etf),
              SizedBox(width: AppSpacing.md),
              CategoryIcon(
                icon: Symbols.currency_bitcoin,
                color: AppPalette.crypto,
              ),
              SizedBox(width: AppSpacing.md),
              CategoryIcon(
                icon: Symbols.currency_exchange,
                color: AppPalette.forex,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          _section(context, 'AlertCard'),
          AlertCard(
            icon: Symbols.event,
            title: '薪水日到了',
            message: '今天是發薪日,要分配這個月的理財嗎?',
            onDismiss: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            r'NT$ 1,234,567',
            style: AppTypography.amount(theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _swatches(BuildContext context, List<(String, Color)> items) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final (label, color) in items)
            Container(
              width: 88,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      );
}
