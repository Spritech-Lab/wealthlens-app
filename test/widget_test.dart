// Smoke tests for formatting and a design-system component.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/app/format.dart';
import 'package:wealthlens/design_system/components/goal_chip.dart';
import 'package:wealthlens/design_system/theme.dart';

void main() {
  test('formatTwd groups thousands', () {
    expect(formatTwd(8030000), r'NT$ 80,300');
  });

  testWidgets('GoalChip renders name and caption', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: GoalChip(name: '出國', progress: 0.3, caption: '再存 8 萬'),
        ),
      ),
    );
    expect(find.text('出國'), findsOneWidget);
    expect(find.text('再存 8 萬'), findsOneWidget);
  });
}
