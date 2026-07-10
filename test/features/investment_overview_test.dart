// 投資頁總覽:顯示「投資組合總值」+ 配置甜甜圈(DonutChart)。
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/app/providers.dart';
import 'package:wealthlens/data/db/app_database.dart';
import 'package:wealthlens/design_system/components/donut_chart.dart';
import 'package:wealthlens/design_system/components/spark_area_chart.dart';
import 'package:wealthlens/design_system/theme.dart';
import 'package:wealthlens/features/assets/investment_screen.dart';

void main() {
  testWidgets('總覽顯示投資組合總值 + 甜甜圈', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const InvestmentScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('投資組合總值'), findsOneWidget);
    expect(find.byType(DonutChart), findsOneWidget);
    // 走勢卡(實驗資料)。
    expect(find.text('投資組合走勢'), findsOneWidget);
    expect(find.byType(SparkAreaChart), findsOneWidget);
  });
}
