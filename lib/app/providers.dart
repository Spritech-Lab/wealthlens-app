/// App-wide Riverpod providers wiring the database, repository and data.
library;

import 'package:drift_flutter/drift_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wealthlens/data/db/app_database.dart';
import 'package:wealthlens/data/price/binance_crypto_price_service.dart';
import 'package:wealthlens/data/price/composite_price_service.dart';
import 'package:wealthlens/data/price/fx_rate_service.dart';
import 'package:wealthlens/data/price/price_service.dart';
import 'package:wealthlens/data/price/yahoo_stock_price_service.dart';
import 'package:wealthlens/data/repository/wealth_repository.dart';
import 'package:wealthlens/data/seed.dart';
import 'package:wealthlens/domain/models/account.dart';
import 'package:wealthlens/domain/models/holding.dart';
import 'package:wealthlens/domain/models/loan.dart';
import 'package:wealthlens/domain/models/transaction.dart';
import 'package:wealthlens/domain/models/wallet.dart';

part 'providers.g.dart';

/// The Drift database, opened against the app documents directory.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final db = AppDatabase(driftDatabase(name: 'wealthlens'));
  ref.onDispose(db.close);
  return db;
}

/// The repository over [appDatabase].
@Riverpod(keepAlive: true)
WealthRepository wealthRepository(WealthRepositoryRef ref) =>
    WealthRepository(ref.watch(appDatabaseProvider));

/// The composite price service (Yahoo stocks / Binance crypto / Yahoo FX).
@Riverpod(keepAlive: true)
PriceService priceService(PriceServiceRef ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return CompositePriceService(
    yahoo: YahooStockPriceService(client),
    binance: BinanceCryptoPriceService(client),
    fx: FxRateService(client),
  );
}

/// Seeds the preview dataset once on first run. All data providers await this
/// so seeding is serialized (no concurrent populate / duplicate inserts).
@Riverpod(keepAlive: true)
Future<void> ensureSeeded(EnsureSeededRef ref) async {
  final repo = ref.watch(wealthRepositoryProvider);
  if (await repo.isEmpty) {
    await populate(repo, buildSeed());
  }
}

/// All wallets, seeding the preview dataset on first run.
@riverpod
Future<List<Wallet>> homeWallets(HomeWalletsRef ref) async {
  final repo = ref.watch(wealthRepositoryProvider);
  await ref.watch(ensureSeededProvider.future);
  return repo.allWallets();
}

/// All investment holdings, seeding the preview dataset on first run.
@riverpod
Future<List<Holding>> investmentHoldings(InvestmentHoldingsRef ref) async {
  final repo = ref.watch(wealthRepositoryProvider);
  await ref.watch(ensureSeededProvider.future);
  return repo.allHoldings();
}

/// Ids of holdings the user has manually corrected (for the 「已修改」 hint).
@riverpod
Future<Set<String>> correctedHoldingIds(CorrectedHoldingIdsRef ref) async {
  final repo = ref.watch(wealthRepositoryProvider);
  await ref.watch(ensureSeededProvider.future);
  return repo.correctedHoldingIds();
}

/// All accounts with wallets eagerly attached, seeding on first run.
@riverpod
Future<List<Account>> homeAccounts(HomeAccountsRef ref) async {
  final repo = ref.watch(wealthRepositoryProvider);
  await ref.watch(ensureSeededProvider.future);
  return repo.allAccounts();
}

/// 本月可動用(可理財金額,單位:分)= 收入 − 固定支出 − 繳費。
///
/// 簡化版:**不扣「已分配」**(那需要 payday 分配-commit 迴圈,另案處理)。
@riverpod
Future<int> monthlyInvestable(MonthlyInvestableRef ref) async {
  final repo = ref.watch(wealthRepositoryProvider);
  await ref.watch(ensureSeededProvider.future);
  return repo.monthlyInvestable();
}

/// 可動用的組成(收入 / 生活費 / 貸款·繳費),供本月分配頁顯示算式。
@riverpod
Future<({int income, int living, int loans})> investableBreakdown(
  InvestableBreakdownRef ref,
) async {
  final repo = ref.watch(wealthRepositoryProvider);
  await ref.watch(ensureSeededProvider.future);
  return repo.investableBreakdown();
}

/// All loans / recurring payments (for the 貸款/繳費 management screen).
@riverpod
Future<List<Loan>> loans(LoansRef ref) async {
  final repo = ref.watch(wealthRepositoryProvider);
  await ref.watch(ensureSeededProvider.future);
  return repo.allLoans();
}

/// Transactions for a wallet/holding [ref], newest first.
@riverpod
Future<List<Transaction>> walletTransactions(
  WalletTransactionsRef ref,
  String refId,
) async {
  final repo = ref.watch(wealthRepositoryProvider);
  return repo.transactionsOf(refId);
}

/// Recent transactions across all wallets/holdings (newest first).
@riverpod
Future<List<Transaction>> recentTransactions(RecentTransactionsRef ref) async {
  final repo = ref.watch(wealthRepositoryProvider);
  await ref.watch(ensureSeededProvider.future);
  return repo.recentTransactions();
}
