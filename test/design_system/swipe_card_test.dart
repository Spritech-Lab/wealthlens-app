import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/design_system/components/swipe_card.dart';
import 'package:wealthlens/design_system/theme.dart';

void main() {
  SwipeFace face(String l, String a, VoidCallback onTap) => SwipeFace(
        label: l,
        amount: a,
        pill: const SwipePill('▲ +3,300', SwipeTone.up),
        onTap: onTap,
      );

  testWidgets('shows first face and 3 dots', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SwipeCard(
            faces: [
              face('資產', r'NT$ 35 萬', () {}),
              face('投資組合', r'NT$ 80,300', () {}),
              face('本月可動用', r'NT$ 32,000', () {}),
            ],
          ),
        ),
      ),
    );
    expect(find.text('資產'), findsOneWidget);
    expect(find.text(r'NT$ 35 萬'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey &&
            '${(w.key! as ValueKey).value}'.startsWith('swipe-dot'),
      ),
      findsNWidgets(3),
    );
  });

  testWidgets('tapping the active face fires its onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SwipeCard(
            faces: [
              face('資產', r'NT$ 35 萬', () => tapped = true),
              face('投資組合', r'NT$ 80,300', () {}),
              face('本月可動用', r'NT$ 32,000', () {}),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('資產'));
    expect(tapped, isTrue);
  });
}
