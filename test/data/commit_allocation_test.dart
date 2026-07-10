// commitAllocations: 錢包 current 增加 + 寫入存入交易。
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

  test('commit 增加錢包 current 並記入存入交易', () async {
    await populate(repo, buildSeed());
    final before = (await repo.allWallets())
        .firstWhere((w) => w.id == 'w_emergency')
        .current;

    await repo.commitAllocations({'w_emergency': 100000});

    final after = (await repo.allWallets())
        .firstWhere((w) => w.id == 'w_emergency')
        .current;
    expect(after, before + 100000);

    final txns = await repo.transactionsOf('w_emergency');
    expect(txns.any((t) => t.kind == '存入' && t.amount == 100000), isTrue);
  });

  test('零或負分配不寫入', () async {
    await populate(repo, buildSeed());
    await repo.commitAllocations({'w_emergency': 0});
    expect(await repo.transactionsOf('w_emergency'), isEmpty);
  });
}
