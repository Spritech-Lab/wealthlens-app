/// Repository over the Drift database, exposing domain models.
///
/// Maps raw Drift rows to/from the pure-Dart domain models. Building an
/// [Account] eagerly loads its wallets so that `Account.balance` (INV-1)
/// holds. INV-2 is enforced by the non-null `accountRef` foreign key: inserting
/// a wallet/holding for a missing account throws.
library;

import 'package:drift/drift.dart';
import 'package:wealthlens/data/db/app_database.dart';
import 'package:wealthlens/domain/cost_basis.dart';
import 'package:wealthlens/domain/models/account.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/fixed_cost.dart';
import 'package:wealthlens/domain/models/holding.dart';
import 'package:wealthlens/domain/models/income.dart';
import 'package:wealthlens/domain/models/loan.dart';
import 'package:wealthlens/domain/models/transaction.dart';
import 'package:wealthlens/domain/models/wallet.dart';

/// Reads and writes accounts, wallets and holdings.
class WealthRepository {
  /// Creates a repository over [_db].
  WealthRepository(this._db);

  final AppDatabase _db;

  // ── Accounts ──────────────────────────────────────────────────────────────

  /// Inserts or replaces an account (its wallets are persisted separately).
  Future<void> upsertAccount(Account account) {
    return _db.into(_db.accounts).insertOnConflictUpdate(
          AccountsCompanion.insert(
            id: account.id,
            name: account.name,
            type: account.type.index,
            isInflowHub: Value(account.isInflowHub),
            institution: Value(account.institution),
          ),
        );
  }

  /// Loads an account with its wallets eagerly, or null if absent.
  ///
  /// The returned [Account.balance] equals Σ `wallet.current` (INV-1).
  Future<Account?> accountWithWallets(String accountId) async {
    final row = await (_db.select(_db.accounts)
          ..where((a) => a.id.equals(accountId)))
        .getSingleOrNull();
    if (row == null) return null;
    final wallets = await walletsOf(accountId);
    return _toAccount(row, wallets);
  }

  /// All accounts, each with its wallets eagerly attached.
  Future<List<Account>> allAccounts() async {
    final rows = await _db.select(_db.accounts).get();
    final result = <Account>[];
    for (final row in rows) {
      result.add(_toAccount(row, await walletsOf(row.id)));
    }
    return result;
  }

  /// Whether the database has no accounts yet (used to seed on first run).
  Future<bool> get isEmpty async {
    final row = await _db.select(_db.accounts).get();
    return row.isEmpty;
  }

  /// Updates a wallet's priority rank.
  Future<void> updateWalletRank(String id, int rank) {
    return (_db.update(_db.wallets)..where((w) => w.id.equals(id)))
        .write(WalletsCompanion(priorityRank: Value(rank)));
  }

  /// All wallets across all accounts, sorted by category then priorityRank.
  Future<List<Wallet>> allWallets() async {
    final rows = await (_db.select(_db.wallets)
          ..orderBy([
            (w) => OrderingTerm(expression: w.category),
            (w) => OrderingTerm(expression: w.priorityRank),
          ]))
        .get();
    return rows.map(_toWallet).toList();
  }

  // ── Wallets ───────────────────────────────────────────────────────────────

  /// Inserts a wallet. Throws if [Wallet.accountRef] points to no account
  /// (INV-2, enforced by the foreign key).
  Future<void> insertWallet(Wallet wallet) {
    return _db.into(_db.wallets).insert(
          WalletsCompanion.insert(
            id: wallet.id,
            name: wallet.name,
            accountRef: wallet.accountRef,
            category: wallet.category.index,
            targetAmount: wallet.targetAmount,
            period: Value(wallet.period),
            current: Value(wallet.current),
            monthlyContribution: wallet.monthlyContribution,
            priorityRank: wallet.priorityRank,
            isPrimary: Value(wallet.isPrimary),
          ),
        );
  }

  /// All wallets of an account, sorted by category then priorityRank.
  Future<List<Wallet>> walletsOf(String accountId) async {
    final rows = await (_db.select(_db.wallets)
          ..where((w) => w.accountRef.equals(accountId))
          ..orderBy([
            (w) => OrderingTerm(expression: w.category),
            (w) => OrderingTerm(expression: w.priorityRank),
          ]))
        .get();
    return rows.map(_toWallet).toList();
  }

  // ── Holdings ──────────────────────────────────────────────────────────────

  /// Inserts a holding. Throws if [Holding.accountRef] points to no account.
  Future<void> insertHolding(Holding holding) {
    return _db.into(_db.holdings).insert(
          HoldingsCompanion.insert(
            id: holding.id,
            accountRef: holding.accountRef,
            kind: holding.kind.index,
            symbol: holding.symbol,
            quantity: holding.quantity,
            avgCost: holding.avgCost,
            lastPrice: holding.lastPrice,
            lastPriceAt: Value(holding.lastPriceAt),
            isCapitalGuaranteed: Value(holding.isCapitalGuaranteed),
            liquidity: holding.liquidity,
          ),
        );
  }

  /// Adds a new [holding] and records its opening 買入 transaction, so the buy
  /// shows in history and the average cost has a traceable basis (INV-8).
  ///
  /// The passed `holding.avgCost` is taken as this buy's price; the stored
  /// avgCost is derived via [CostBasisCalculator] (no fee → equals the price).
  Future<void> addHoldingWithBuy(Holding holding) async {
    final basis = CostBasisCalculator.compute([
      CostTxn(
        kind: CostTxnKind.buy,
        quantity: holding.quantity,
        price: holding.avgCost,
      ),
    ]);
    await insertHolding(holding.copyWith(avgCost: basis.avgCost));
    await insertTransaction(
      Transaction(
        id: 't_${DateTime.now().microsecondsSinceEpoch}_${holding.id}',
        date: DateTime.now(),
        kind: '買入',
        ref: holding.id,
        amount: (holding.quantity * holding.avgCost * 100).round(),
        quantity: holding.quantity,
        price: holding.avgCost,
      ),
    );
  }

  /// All holdings of an account.
  Future<List<Holding>> holdingsOf(String accountId) async {
    final rows = await (_db.select(_db.holdings)
          ..where((h) => h.accountRef.equals(accountId)))
        .get();
    return rows.map(_toHolding).toList();
  }

  /// All holdings across every account.
  Future<List<Holding>> allHoldings() async {
    final rows = await _db.select(_db.holdings).get();
    return rows.map(_toHolding).toList();
  }

  /// Updates a holding's last fetched price + timestamp.
  Future<void> updateHoldingPrice(String id, double price, DateTime? at) {
    return (_db.update(_db.holdings)..where((h) => h.id.equals(id))).write(
      HoldingsCompanion(lastPrice: Value(price), lastPriceAt: Value(at)),
    );
  }

  /// Manually corrects a holding's [quantity] / [avgCost] (buy price) and
  /// records a 更正 transaction as a trail. Used to fix mistaken entries; the
  /// UI marks corrected holdings with a 「已修改」 hint.
  Future<void> correctHolding(
    String id, {
    required double quantity,
    required double avgCost,
  }) async {
    await (_db.update(_db.holdings)..where((h) => h.id.equals(id))).write(
      HoldingsCompanion(quantity: Value(quantity), avgCost: Value(avgCost)),
    );
    await insertTransaction(
      Transaction(
        id: 't_${DateTime.now().microsecondsSinceEpoch}_$id',
        date: DateTime.now(),
        kind: '更正',
        ref: id,
        amount: 0,
        quantity: quantity,
        price: avgCost,
        reason: '手動更正',
      ),
    );
  }

  /// Removes a holding and its transactions.
  Future<void> deleteHolding(String id) async {
    await (_db.delete(_db.transactions)..where((t) => t.ref.equals(id))).go();
    await (_db.delete(_db.holdings)..where((h) => h.id.equals(id))).go();
  }

  /// Ids of holdings that carry a 更正 (manual correction) transaction.
  Future<Set<String>> correctedHoldingIds() async {
    final rows = await (_db.select(_db.transactions)
          ..where((t) => t.kind.equals('更正')))
        .get();
    return rows.map((r) => r.ref).toSet();
  }

  // ── Transactions ────────────────────────────────────────────────────────

  /// Inserts a transaction into the ledger.
  Future<void> insertTransaction(Transaction txn) {
    return _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            id: txn.id,
            date: txn.date,
            kind: txn.kind,
            ref: txn.ref,
            amount: txn.amount,
            quantity: Value(txn.quantity),
            price: Value(txn.price),
            fee: Value(txn.fee),
            reason: Value(txn.reason),
            note: Value(txn.note),
          ),
        );
  }

  /// Commits an allocation: for each wallet with a positive amount, writes a
  /// 存入 transaction and increases the wallet's `current` by that amount.
  Future<void> commitAllocations(Map<String, int> allocations) async {
    for (final e in allocations.entries) {
      if (e.value <= 0) continue;
      await insertTransaction(
        Transaction(
          id: 't_${DateTime.now().microsecondsSinceEpoch}_${e.key}',
          date: DateTime.now(),
          kind: '存入',
          ref: e.key,
          amount: e.value,
        ),
      );
      await _db.customStatement(
        'UPDATE wallets SET current = current + ? WHERE id = ?',
        [e.value, e.key],
      );
    }
  }

  /// Reconciles an account to an externally-observed [actualBalance].
  ///
  /// Because `account.balance` is derived from Σ wallet.current (INV-1), the
  /// difference between the recorded balance and [actualBalance] is applied to
  /// [targetWalletId] (the wallet that absorbs the adjustment), recorded as a
  /// 調整 transaction. A zero difference is a no-op. Returns the applied delta
  /// (positive = balance was too low, negative = too high).
  Future<int> reconcileAccount(
    String accountId,
    int actualBalance,
    String targetWalletId,
  ) async {
    final account = await accountWithWallets(accountId);
    if (account == null) return 0;
    final delta = actualBalance - account.balance;
    if (delta == 0) return 0;
    await insertTransaction(
      Transaction(
        id: 't_${DateTime.now().microsecondsSinceEpoch}_$targetWalletId',
        date: DateTime.now(),
        kind: '調整',
        ref: targetWalletId,
        amount: delta,
        reason: '帳戶對帳',
      ),
    );
    await _db.customStatement(
      'UPDATE wallets SET current = current + ? WHERE id = ?',
      [delta, targetWalletId],
    );
    return delta;
  }

  /// The most recent transactions across all wallets/holdings, newest first.
  Future<List<Transaction>> recentTransactions({int limit = 50}) async {
    final rows = await (_db.select(_db.transactions)
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();
    return rows.map(_toTransaction).toList();
  }

  /// All transactions for a wallet/holding [ref], newest first.
  Future<List<Transaction>> transactionsOf(String ref) async {
    final rows = await (_db.select(_db.transactions)
          ..where((t) => t.ref.equals(ref))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.date,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    return rows.map(_toTransaction).toList();
  }

  // ── Income / Loan / FixedCost ─────────────────────────────────────────────

  /// Inserts or replaces an income source.
  Future<void> upsertIncome(Income income) {
    return _db.into(_db.incomes).insertOnConflictUpdate(
          IncomesCompanion.insert(
            id: income.id,
            name: income.name,
            amount: income.amount,
            type: income.type.index,
            payday: Value(income.payday),
            quickEntryOnHome: Value(income.quickEntryOnHome),
          ),
        );
  }

  /// Inserts or replaces a loan.
  Future<void> upsertLoan(Loan loan) {
    return _db.into(_db.loans).insertOnConflictUpdate(
          LoansCompanion.insert(
            id: loan.id,
            type: loan.type.index,
            name: Value(loan.name),
            monthlyPayment: loan.monthlyPayment,
            terms: Value(loan.terms),
          ),
        );
  }

  /// All loans / recurring payments.
  Future<List<Loan>> allLoans() async {
    final rows = await _db.select(_db.loans).get();
    return [
      for (final r in rows)
        Loan(
          id: r.id,
          type: LoanType.values[r.type],
          name: r.name,
          monthlyPayment: r.monthlyPayment,
          terms: r.terms,
        ),
    ];
  }

  /// Removes a loan / payment.
  Future<void> deleteLoan(String id) =>
      (_db.delete(_db.loans)..where((l) => l.id.equals(id))).go();

  /// Sets the single fixed living cost.
  Future<void> setFixedCost(FixedCost cost) {
    return _db.into(_db.fixedCosts).insertOnConflictUpdate(
          FixedCostsCompanion.insert(
            id: 'default',
            livingExpense: cost.livingExpense,
          ),
        );
  }

  /// Whether income/cost data has been seeded.
  Future<bool> get hasCashflowData async =>
      (await _db.select(_db.incomes).get()).isNotEmpty;

  /// Investable amount this month (cents): Σ income − 生活費 − Σ 貸款月付.
  ///
  /// Simplified (does not subtract already-allocated; that needs the payday
  /// allocation-commit flow). See spec.
  Future<int> monthlyInvestable() async {
    final b = await investableBreakdown();
    return b.income - b.living - b.loans;
  }

  /// The components behind [monthlyInvestable], for explanatory UI captions
  /// (本月分配頁:可動用 = 收入 − 生活費 − 貸款/繳費).
  Future<({int income, int living, int loans})> investableBreakdown() async {
    final incomes = await _db.select(_db.incomes).get();
    final loans = await _db.select(_db.loans).get();
    final costs = await _db.select(_db.fixedCosts).get();
    final income = incomes.fold<int>(0, (s, r) => s + r.amount);
    final living = costs.fold<int>(0, (s, r) => s + r.livingExpense);
    final loanPay = loans.fold<int>(0, (s, r) => s + r.monthlyPayment);
    return (income: income, living: living, loans: loanPay);
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  Account _toAccount(AccountRow row, List<Wallet> wallets) => Account(
        id: row.id,
        name: row.name,
        type: AccountType.values[row.type],
        isInflowHub: row.isInflowHub,
        institution: row.institution,
        wallets: wallets,
      );

  Wallet _toWallet(WalletRow row) => Wallet(
        id: row.id,
        name: row.name,
        accountRef: row.accountRef,
        category: WalletCategory.values[row.category],
        targetAmount: row.targetAmount,
        period: row.period,
        current: row.current,
        monthlyContribution: row.monthlyContribution,
        priorityRank: row.priorityRank,
        isPrimary: row.isPrimary,
      );

  Holding _toHolding(HoldingRow row) => Holding(
        id: row.id,
        accountRef: row.accountRef,
        kind: HoldingKind.values[row.kind],
        symbol: row.symbol,
        quantity: row.quantity,
        avgCost: row.avgCost,
        lastPrice: row.lastPrice,
        lastPriceAt: row.lastPriceAt,
        isCapitalGuaranteed: row.isCapitalGuaranteed,
        liquidity: row.liquidity,
      );

  Transaction _toTransaction(TransactionRow row) => Transaction(
        id: row.id,
        date: row.date,
        kind: row.kind,
        ref: row.ref,
        amount: row.amount,
        quantity: row.quantity,
        price: row.price,
        fee: row.fee,
        reason: row.reason,
        note: row.note,
      );
}
