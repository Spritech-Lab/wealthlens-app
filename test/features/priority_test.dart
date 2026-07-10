// 優先序:render 保障+目標;repo.updateWalletRank 改 rank。
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/data/db/app_database.dart';
import 'package:wealthlens/data/repository/wealth_repository.dart';
import 'package:wealthlens/data/seed.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/features/goals/priority_screen.dart';

void main() {
  testWidgets('優先序頁渲染保障與目標', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const PriorityScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('備用金'), findsOneWidget); // 保障(釘鎖)
    expect(find.text('出國'), findsOneWidget); // 目標(可拖)
    expect(find.text('年度儲蓄'), findsOneWidget);
    expect(find.byType(ReorderableListView), findsOneWidget);
  });

  test('updateWalletRank 改變 priorityRank', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = WealthRepository(db);
    await populate(repo, buildSeed());

    await repo.updateWalletRank('w_travel', 9);
    final w = (await repo.allWallets()).firstWhere((x) => x.id == 'w_travel');
    expect(w.priorityRank, 9);
  });
}
