/// Drift table definitions for the WealthLens local database.
///
/// Tables mirror the domain models. Derived values (Account.balance,
/// Wallet.progress, Holding.currentValue, ...) are NOT stored — they are
/// computed in the domain layer. Money columns are integers (cents).
library;

import 'package:drift/drift.dart';
import 'package:wealthlens/domain/models/enums.dart'
    show AccountType, HoldingKind, IncomeType, LoanType, WalletCategory;

/// Physical accounts (where money is held).
@DataClassName('AccountRow')
class Accounts extends Table {
  /// Stable account id.
  TextColumn get id => text()();

  /// User-visible name.
  TextColumn get name => text()();

  /// [AccountType] index.
  IntColumn get type => integer()();

  /// Optional institution label.
  TextColumn get institution => text().nullable()();

  /// At most one account is the income hub (enforced in the repository).
  BoolColumn get isInflowHub => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Wallets (purpose buckets) — each belongs to exactly one account (INV-2).
@DataClassName('WalletRow')
class Wallets extends Table {
  /// Stable wallet id.
  TextColumn get id => text()();

  /// User-visible name.
  TextColumn get name => text()();

  /// Owning account. Non-null FK enforces INV-2 (wallet belongs to one
  /// account, never crosses accounts).
  TextColumn get accountRef =>
      text().references(Accounts, #id, onDelete: KeyAction.cascade)();

  /// [WalletCategory] index.
  IntColumn get category => integer()();

  /// Target amount in cents.
  IntColumn get targetAmount => integer()();

  /// Optional deadline as "YYYY-MM"; null = no deadline.
  TextColumn get period => text().nullable()();

  /// Current saved amount in cents.
  IntColumn get current => integer().withDefault(const Constant(0))();

  /// User-set monthly contribution in cents.
  IntColumn get monthlyContribution => integer()();

  /// Ordering rank; safety layers are fixed 1/2, goals are 3+.
  IntColumn get priorityRank => integer()();

  /// Whether this is the app-wide primary goal (home hero).
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Investment holdings (stocks / crypto / forex / manual assets).
@DataClassName('HoldingRow')
class Holdings extends Table {
  /// Stable holding id.
  TextColumn get id => text()();

  /// Owning account.
  TextColumn get accountRef =>
      text().references(Accounts, #id, onDelete: KeyAction.cascade)();

  /// [HoldingKind] index.
  IntColumn get kind => integer()();

  /// Symbol / currency code (e.g. "0050", "BTC", "USD").
  TextColumn get symbol => text()();

  /// Units held.
  RealColumn get quantity => real()();

  /// Weighted-average cost (TWD/unit; for forex = buy rate).
  RealColumn get avgCost => real()();

  /// Last fetched price/rate (TWD/unit).
  RealColumn get lastPrice => real()();

  /// When [lastPrice] was fetched; null for manual kinds.
  DateTimeColumn get lastPriceAt => dateTime().nullable()();

  /// Whether principal is guaranteed (no price risk).
  BoolColumn get isCapitalGuaranteed =>
      boolean().withDefault(const Constant(false))();

  /// Liquidity label.
  TextColumn get liquidity => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Transaction ledger — deposits / withdrawals / buys / sells / dividends.
///
/// [ref] points to the owning wallet or holding id (not a hard FK because it
/// may reference either table). Money columns are integer cents.
@DataClassName('TransactionRow')
class Transactions extends Table {
  /// Stable transaction id.
  TextColumn get id => text()();

  /// When the transaction happened.
  DateTimeColumn get date => dateTime()();

  /// Kind label (存入 / 動用 / 買入 / 賣出 / 配息).
  TextColumn get kind => text()();

  /// Owning wallet or holding id.
  TextColumn get ref => text()();

  /// Signed amount in cents (+存入 / −動用).
  IntColumn get amount => integer()();

  /// Units (holdings only).
  RealColumn get quantity => real().nullable()();

  /// Per-unit price (holdings only).
  RealColumn get price => real().nullable()();

  /// Fee in cents.
  IntColumn get fee => integer().nullable()();

  /// Optional reason (e.g. 動用 reason).
  TextColumn get reason => text().nullable()();

  /// Free note.
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Income sources (fixed salary / dynamic gigs).
@DataClassName('IncomeRow')
class Incomes extends Table {
  /// Stable id.
  TextColumn get id => text()();

  /// Display name.
  TextColumn get name => text()();

  /// Amount in cents.
  IntColumn get amount => integer()();

  /// [IncomeType] index.
  IntColumn get type => integer()();

  /// Payday day-of-month (1–31); null for dynamic.
  IntColumn get payday => integer().nullable()();

  /// Whether home shows a quick-entry FAB for this income.
  BoolColumn get quickEntryOnHome =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Lightweight loans — labelled fixed monthly outflows (not liabilities).
@DataClassName('LoanRow')
class Loans extends Table {
  /// Stable id.
  TextColumn get id => text()();

  /// [LoanType] index (legacy seed rows; new items are free-form named).
  IntColumn get type => integer()();

  /// User-defined name for the fixed payment (e.g. 房租、保險). Null on legacy
  /// seed rows, which fall back to the type label.
  TextColumn get name => text().nullable()();

  /// Monthly payment in cents.
  IntColumn get monthlyPayment => integer()();

  /// Remaining terms (months); optional.
  IntColumn get terms => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Fixed living cost (single row).
@DataClassName('FixedCostRow')
class FixedCosts extends Table {
  /// Stable id (single "default" row).
  TextColumn get id => text()();

  /// Monthly living expense in cents.
  IntColumn get livingExpense => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
