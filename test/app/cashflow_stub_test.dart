// monthlyInvestable = Σ income − 生活費 − Σ 貸款月付(簡化,不扣已分配)。
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/data/db/app_database.dart';
import 'package:wealthlens/data/repository/wealth_repository.dart';
import 'package:wealthlens/data/seed.dart';

void main() {
  late AppDatabase db;
  late WealthRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WealthRepository(db);
  });

  tearDown(() async => db.close());

  test('seed 後可動用 = 月薪 50,000 − 生活費 15,000 − 卡費 3,000 = 32,000', () async {
    await populate(repo, buildSeed());
    expect(await repo.monthlyInvestable(), 3200000);
  });

  test('無資料時可動用為 0', () async {
    expect(await repo.monthlyInvestable(), 0);
  });
}
