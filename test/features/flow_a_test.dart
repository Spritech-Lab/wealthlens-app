// Flow A: 對帳頁驅動 新增帳戶 / 建錢包,驗證寫入(in-memory DB)。
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/data/db/app_database.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/features/assets/reconcile_screen.dart';

void main() {
  Future<void> pumpReconcile(WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ReconcileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('seed loads 3 accounts', (tester) async {
    await pumpReconcile(tester);
    expect(find.text('DAWHO'), findsOneWidget);
    expect(find.text('券商'), findsOneWidget);
  });

  testWidgets('新增帳戶 adds an account', (tester) async {
    await pumpReconcile(tester);

    await tester.tap(find.text('新增帳戶'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '名稱'),
      '測試帳戶',
    );
    await tester.tap(find.widgetWithText(FilledButton, '新增'));
    await tester.pumpAndSettle();

    expect(find.text('測試帳戶'), findsOneWidget);
  });

  testWidgets('在此帳戶建錢包 adds a wallet under the account', (tester) async {
    await pumpReconcile(tester);

    // DAWHO 是第一個帳戶,點它底下的「在此帳戶建錢包」。
    await tester.tap(find.text('在此帳戶建錢包').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '名稱'), '新目標');
    await tester.enterText(
      find.widgetWithText(TextField, '目標金額(元)'),
      '50000',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '每月補額(元)'),
      '5000',
    );
    await tester.tap(find.widgetWithText(FilledButton, '建立'));
    await tester.pumpAndSettle();

    expect(find.text('新目標'), findsOneWidget);
  });
}
