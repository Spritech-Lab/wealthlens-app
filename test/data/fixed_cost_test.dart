// setFixedCost:改生活費 → investableBreakdown / monthlyInvestable 同步。
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/data/db/app_database.dart';
import 'package:wealthlens/data/repository/wealth_repository.dart';
import 'package:wealthlens/data/seed.dart';
import 'package:wealthlens/domain/models/fixed_cost.dart';

void main() {
  late AppDatabase db;
  late WealthRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WealthRepository(db);
  });

  tearDown(() async => db.close());

  test('改生活費後可動用同步(收入 − 生活費 − 貸款)', () async {
    await populate(repo, buildSeed());

    await repo.setFixedCost(const FixedCost(livingExpense: 2000000)); // 20,000

    final b = await repo.investableBreakdown();
    expect(b.living, 2000000);
    expect(await repo.monthlyInvestable(), b.income - b.living - b.loans);
  });
}
