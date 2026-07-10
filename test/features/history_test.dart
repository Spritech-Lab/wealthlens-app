// 歷史紀錄:recentTransactions 跨 ref 最新在前;HistoryScreen 渲染名稱。
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/data/db/app_database.dart';
import 'package:wealthlens/data/repository/wealth_repository.dart';
import 'package:wealthlens/data/seed.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/features/history/history_screen.dart';

void main() {
  test('recentTransactions 跨所有 ref、最新在前', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = WealthRepository(db);
    await populate(repo, buildSeed());

    final txns = await repo.recentTransactions();
    expect(txns.length, 4); // seed 出國 4 筆
    // 最新一筆是 2026-06-15
    expect(txns.first.date, DateTime(2026, 6, 15));
  });

  testWidgets('HistoryScreen 顯示錢包名稱 + 類型', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const HistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('出國'), findsWidgets);
    expect(find.textContaining('存入'), findsWidgets);
  });
}
