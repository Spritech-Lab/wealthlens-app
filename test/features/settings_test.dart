// SettingsScreen: 設定列點開 picker 後選項更新狀態。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/app/anchor_unit_controller.dart';
import 'package:wealthlens/app/format.dart';
import 'package:wealthlens/app/theme_controller.dart';
import 'package:wealthlens/features/settings/settings_screen.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('外觀 picker 選深色更新主題', (tester) async {
    final container = await pump(tester);
    expect(container.read(themeModeControllerProvider), ThemeMode.system);

    await tester.tap(find.text('外觀'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeControllerProvider), ThemeMode.dark);
  });

  testWidgets('金額顯示 picker 選萬更新錨定單位', (tester) async {
    final container = await pump(tester);
    expect(container.read(anchorUnitControllerProvider), AnchorUnit.full);

    await tester.tap(find.text('金額顯示'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('萬'));
    await tester.pumpAndSettle();

    expect(container.read(anchorUnitControllerProvider), AnchorUnit.wan);
  });
}
