// reconcileAccount: 輸入實際餘額,差額記入指定錢包,帳戶總額對齊(INV-1)。
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

  Future<int> balanceOf(String accountId) async {
    final a = await repo.accountWithWallets(accountId);
    return a!.balance;
  }

  test('實際餘額較高:差額補入目標錢包,帳戶總額對齊', () async {
    await populate(repo, buildSeed());
    final recorded = await balanceOf('acc_dawho');
    final target = (await repo.walletsOf('acc_dawho'))
        .firstWhere((w) => w.id == 'w_emergency');

    final delta = await repo.reconcileAccount(
      'acc_dawho',
      recorded + 50000,
      'w_emergency',
    );

    expect(delta, 50000);
    expect(await balanceOf('acc_dawho'), recorded + 50000); // INV-1
    final after = (await repo.walletsOf('acc_dawho'))
        .firstWhere((w) => w.id == 'w_emergency');
    expect(after.current, target.current + 50000);
    final txns = await repo.transactionsOf('w_emergency');
    expect(txns.any((t) => t.kind == '調整' && t.amount == 50000), isTrue);
  });

  test('實際餘額較低:差額為負,扣除目標錢包', () async {
    await populate(repo, buildSeed());
    final recorded = await balanceOf('acc_dawho');

    final delta = await repo.reconcileAccount(
      'acc_dawho',
      recorded - 30000,
      'w_emergency',
    );

    expect(delta, -30000);
    expect(await balanceOf('acc_dawho'), recorded - 30000);
  });

  test('餘額相符:不寫入交易', () async {
    await populate(repo, buildSeed());
    final recorded = await balanceOf('acc_dawho');

    final delta =
        await repo.reconcileAccount('acc_dawho', recorded, 'w_emergency');

    expect(delta, 0);
    final txns = await repo.transactionsOf('w_emergency');
    expect(txns.any((t) => t.kind == '調整'), isFalse);
  });
}
