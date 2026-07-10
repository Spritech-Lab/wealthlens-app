/// The WealthLens Drift database.
library;

import 'package:drift/drift.dart';
import 'package:wealthlens/data/db/tables.dart';

part 'app_database.g.dart';

/// Local SQLite database holding accounts, wallets and holdings.
///
/// Derived values are never persisted; only raw rows live here. INV-2 is
/// enforced by the non-null `accountRef` foreign keys on [Wallets] and
/// [Holdings].
@DriftDatabase(
  tables: [Accounts, Wallets, Holdings, Transactions, Incomes, Loans,
    FixedCosts],
)
class AppDatabase extends _$AppDatabase {
  /// Creates a database over the given [executor] (inject in-memory in tests).
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(transactions);
          if (from < 3) {
            await m.createTable(incomes);
            await m.createTable(loans);
            await m.createTable(fixedCosts);
          }
          if (from < 4) await m.addColumn(loans, loans.name);
        },
        beforeOpen: (details) async {
          // Enforce foreign keys (INV-2) at the SQLite level.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
