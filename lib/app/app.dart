/// Root app widget and the single-page home shell.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wealthlens/app/anchor_unit_controller.dart';
import 'package:wealthlens/app/font_scale_controller.dart';
import 'package:wealthlens/app/format.dart';
import 'package:wealthlens/app/theme_controller.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/features/history/history_screen.dart';
import 'package:wealthlens/features/home/home_screen.dart';
import 'package:wealthlens/features/lock/lock_screen.dart';
import 'package:wealthlens/features/settings/settings_screen.dart';

/// The WealthLens application root.
class WealthLensApp extends ConsumerWidget {
  /// Creates the app.
  const WealthLensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeControllerProvider);
    // Mirror the anchor setting into the global default and rebuild the whole
    // tree when it changes, so every formatTwd call reflects the new unit.
    defaultAnchorUnit = ref.watch(anchorUnitControllerProvider);
    final fontScale = ref.watch(fontScaleControllerProvider);
    return MaterialApp(
      title: 'WealthLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(fontScale.factor),
        ),
        child: child!,
      ),
      home: const LockGate(child: _Shell()),
    );
  }
}

/// Single-page home: dashboard digital card + goal chips + tasks.
class _Shell extends ConsumerWidget {
  const _Shell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secondary = Theme.of(context).textTheme.bodySmall?.color;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        toolbarHeight: 64,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '嗨,Sprite',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              '來看看今天的理財',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: secondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '歷史紀錄',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: const SafeArea(child: HomeScreen()),
    );
  }
}
