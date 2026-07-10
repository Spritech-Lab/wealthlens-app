/// Preview / test seed data — a small realistic fixture.
///
/// Used for dev previews and as a known dataset in tests.
library;

import 'package:wealthlens/data/repository/wealth_repository.dart';
import 'package:wealthlens/domain/models/account.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/fixed_cost.dart';
import 'package:wealthlens/domain/models/holding.dart';
import 'package:wealthlens/domain/models/income.dart';
import 'package:wealthlens/domain/models/loan.dart';
import 'package:wealthlens/domain/models/transaction.dart';
import 'package:wealthlens/domain/models/wallet.dart';

/// A self-contained set of seed data (accounts, wallets, holdings, ledger,
/// incomes, loans, living cost).
class SeedData {
  /// Creates a [SeedData] bundle.
  const SeedData({
    required this.accounts,
    required this.wallets,
    required this.holdings,
    required this.transactions,
    required this.incomes,
    required this.loans,
    required this.fixedCost,
  });

  /// Seed accounts (without their wallets eagerly attached).
  final List<Account> accounts;

  /// Seed wallets, each referencing a seed account.
  final List<Wallet> wallets;

  /// Seed investment holdings.
  final List<Holding> holdings;

  /// Seed transaction ledger entries.
  final List<Transaction> transactions;

  /// Seed income sources.
  final List<Income> incomes;

  /// Seed loans.
  final List<Loan> loans;

  /// Seed fixed living cost.
  final FixedCost fixedCost;
}

/// Builds the standard preview fixture.
SeedData buildSeed() {
  const accounts = [
    Account(
      id: 'acc_dawho',
      name: 'DAWHO',
      type: AccountType.cash,
      isInflowHub: true,
      wallets: [],
    ),
    Account(
      id: 'acc_sinopac',
      name: '永豐',
      type: AccountType.cash,
      isInflowHub: false,
      wallets: [],
      institution: '永豐銀行',
    ),
    Account(
      id: 'acc_broker',
      name: '券商',
      type: AccountType.brokerage,
      isInflowHub: false,
      wallets: [],
    ),
  ];

  const wallets = [
    // DAWHO: 財務保障(備用金)+ 生活保障(留存金)
    Wallet(
      id: 'w_emergency',
      name: '備用金',
      accountRef: 'acc_dawho',
      category: WalletCategory.financialSafety,
      targetAmount: 30000000, // 300,000.00
      current: 12000000,
      monthlyContribution: 1000000,
      priorityRank: 1,
      isPrimary: false,
    ),
    Wallet(
      id: 'w_reserve',
      name: '留存金',
      accountRef: 'acc_dawho',
      category: WalletCategory.lifeSafety,
      targetAmount: 6000000, // 60,000.00
      current: 6000000,
      monthlyContribution: 0,
      priorityRank: 2,
      isPrimary: false,
    ),
    // 永豐: 儲蓄目標(出國)+(年度儲蓄)
    Wallet(
      id: 'w_travel',
      name: '出國',
      accountRef: 'acc_sinopac',
      category: WalletCategory.savingGoal,
      targetAmount: 12000000, // 120,000.00
      current: 4000000,
      monthlyContribution: 1500000,
      priorityRank: 3,
      isPrimary: true,
      period: '2027-06',
    ),
    Wallet(
      id: 'w_annual',
      name: '年度儲蓄',
      accountRef: 'acc_sinopac',
      category: WalletCategory.savingGoal,
      targetAmount: 24000000, // 240,000.00
      current: 5000000,
      monthlyContribution: 2000000,
      priorityRank: 4,
      isPrimary: false,
      period: '2027-12',
    ),
  ];

  const holdings = [
    Holding(
      id: 'h_0050',
      accountRef: 'acc_broker',
      kind: HoldingKind.etf,
      symbol: '0050',
      quantity: 100,
      avgCost: 140,
      lastPrice: 155,
      isCapitalGuaranteed: false,
      liquidity: 'high',
    ),
    Holding(
      id: 'h_usd',
      accountRef: 'acc_broker',
      kind: HoldingKind.forex,
      symbol: 'USD',
      quantity: 2000,
      avgCost: 31.5,
      lastPrice: 32.4,
      isCapitalGuaranteed: false,
      liquidity: 'high',
    ),
  ];

  // 出國錢包的交易紀錄(分為單位)。
  final transactions = [
    Transaction(
      id: 't1',
      date: DateTime(2026, 6, 15),
      kind: '存入',
      ref: 'w_travel',
      amount: 1500000,
    ),
    Transaction(
      id: 't2',
      date: DateTime(2026, 5, 15),
      kind: '存入',
      ref: 'w_travel',
      amount: 1500000,
    ),
    Transaction(
      id: 't3',
      date: DateTime(2026, 4, 20),
      kind: '動用',
      ref: 'w_travel',
      amount: -500000,
      reason: '臨時支出',
    ),
    Transaction(
      id: 't4',
      date: DateTime(2026, 4, 15),
      kind: '存入',
      ref: 'w_travel',
      amount: 1500000,
    ),
  ];

  // 現金流來源:月薪 50,000 − 生活費 15,000 − 卡費 3,000 = 可動用 32,000。
  const incomes = [
    Income(
      id: 'inc_salary',
      name: '月薪',
      amount: 5000000,
      type: IncomeType.fixed,
      payday: 5,
    ),
  ];
  const loans = [
    Loan(
      id: 'loan_card',
      type: LoanType.cardRevolving,
      monthlyPayment: 300000,
    ),
  ];
  const fixedCost = FixedCost(livingExpense: 1500000);

  return SeedData(
    accounts: accounts,
    wallets: wallets,
    holdings: holdings,
    transactions: transactions,
    incomes: incomes,
    loans: loans,
    fixedCost: fixedCost,
  );
}

/// Inserts the [seed] into [repo] (accounts first to satisfy foreign keys).
Future<void> populate(WealthRepository repo, SeedData seed) async {
  for (final a in seed.accounts) {
    await repo.upsertAccount(a);
  }
  for (final w in seed.wallets) {
    await repo.insertWallet(w);
  }
  for (final h in seed.holdings) {
    await repo.insertHolding(h);
  }
  for (final t in seed.transactions) {
    await repo.insertTransaction(t);
  }
  for (final i in seed.incomes) {
    await repo.upsertIncome(i);
  }
  for (final l in seed.loans) {
    await repo.upsertLoan(l);
  }
  await repo.setFixedCost(seed.fixedCost);
}
