// WealthRepository tests — INV-1 (balance reconciliation through the DB) and
// INV-2 (foreign key rejects a wallet with no owning account).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/data/db/app_database.dart';
import 'package:wealthlens/data/repository/wealth_repository.dart';
import 'package:wealthlens/domain/models/account.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/wallet.dart';

void main() {
  late AppDatabase db;
  late WealthRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WealthRepository(db);
  });

  tearDown(() async => db.close());

  Account account(String id) => Account(
        id: id,
        name: 'DAWHO',
        type: AccountType.cash,
        isInflowHub: true,
        wallets: const [],
      );

  Wallet wallet(String id, String accountRef, int current) => Wallet(
        id: id,
        name: 'W',
        accountRef: accountRef,
        category: WalletCategory.savingGoal,
        targetAmount: 1000000,
        current: current,
        monthlyContribution: 50000,
        priorityRank: 3,
        isPrimary: false,
      );

  test('INV-1: account balance equals sum of its wallet.current via DB',
      () async {
    await repo.upsertAccount(account('a1'));
    await repo.insertWallet(wallet('w1', 'a1', 300000));
    await repo.insertWallet(wallet('w2', 'a1', 200000));

    final loaded = await repo.accountWithWallets('a1');
    expect(loaded, isNotNull);
    expect(loaded!.wallets.length, 2);
    expect(loaded.balance, 500000);
  });

  test('INV-2: inserting a wallet for a missing account throws (FK)', () async {
    expect(
      () => repo.insertWallet(wallet('w1', 'ghost', 100)),
      throwsA(isA<Exception>()),
    );
  });

  test('walletsOf returns empty for unknown account', () async {
    expect(await repo.walletsOf('nope'), isEmpty);
  });
}
