// Transaction ledger: insert + query newest-first; seed loads 出國 history.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wealthlens/data/db/app_database.dart';
import 'package:wealthlens/data/repository/wealth_repository.dart';
import 'package:wealthlens/data/seed.dart';
import 'package:wealthlens/domain/models/transaction.dart';

void main() {
  late AppDatabase db;
  late WealthRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WealthRepository(db);
  });

  tearDown(() async => db.close());

  test('insert + transactionsOf returns newest first', () async {
    await repo.insertTransaction(
      Transaction(
        id: 'a',
        date: DateTime(2026),
        kind: '存入',
        ref: 'w1',
        amount: 1000,
      ),
    );
    await repo.insertTransaction(
      Transaction(
        id: 'b',
        date: DateTime(2026, 3),
        kind: '存入',
        ref: 'w1',
        amount: 2000,
      ),
    );

    final txns = await repo.transactionsOf('w1');
    expect(txns.map((t) => t.id), ['b', 'a']); // newest first
  });

  test('seed loads 出國 (w_travel) ledger with a 動用 entry', () async {
    await populate(repo, buildSeed());
    final txns = await repo.transactionsOf('w_travel');
    expect(txns.length, 4);
    expect(txns.any((t) => t.kind == '動用' && t.amount < 0), isTrue);
  });
}
