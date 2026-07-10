// 對帳守則:實際餘額低於帳面(扣除)時,未選來源錢包前「確認對帳」停用。
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/data/db/app_database.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/features/assets/reconcile_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
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

  ButtonStyleButton confirmButton(WidgetTester tester) =>
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '確認對帳'),
      );

  testWidgets('扣除時未選錢包 → 確認停用;補入時預設可確認', (tester) async {
    await pump(tester);

    // DAWHO(記錄 18 萬,兩個錢包)開啟對帳。
    await tester.tap(find.text('對帳').first);
    await tester.pumpAndSettle();

    // 補入:實際 19 萬 > 18 萬 → 有預設來源,確認可按。
    await tester.enterText(find.byType(TextField).last, '190000');
    await tester.pumpAndSettle();
    expect(confirmButton(tester).onPressed, isNotNull);

    // 扣除:實際 17 萬 < 18 萬 → 守則要求明選來源,未選前確認停用。
    await tester.enterText(find.byType(TextField).last, '170000');
    await tester.pumpAndSettle();
    expect(confirmButton(tester).onPressed, isNull);
  });
}
