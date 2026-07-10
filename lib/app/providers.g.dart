// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'03aca7258d94991d7a140389745ea2bfcc1c56f9';

/// The Drift database, opened against the app documents directory.
///
/// Copied from [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = Provider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = ProviderRef<AppDatabase>;
String _$wealthRepositoryHash() => r'1f91dea69a3bd8f3480dde64609b96ef8e4faab2';

/// The repository over [appDatabase].
///
/// Copied from [wealthRepository].
@ProviderFor(wealthRepository)
final wealthRepositoryProvider = Provider<WealthRepository>.internal(
  wealthRepository,
  name: r'wealthRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$wealthRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef WealthRepositoryRef = ProviderRef<WealthRepository>;
String _$priceServiceHash() => r'9906ee019f5a9a4717a89cfc81a3848f7ae9dc4a';

/// The composite price service (Yahoo stocks / Binance crypto / Yahoo FX).
///
/// Copied from [priceService].
@ProviderFor(priceService)
final priceServiceProvider = Provider<PriceService>.internal(
  priceService,
  name: r'priceServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$priceServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PriceServiceRef = ProviderRef<PriceService>;
String _$ensureSeededHash() => r'ab9136184ebb6d66584583582655222592c92344';

/// Seeds the preview dataset once on first run. All data providers await this
/// so seeding is serialized (no concurrent populate / duplicate inserts).
///
/// Copied from [ensureSeeded].
@ProviderFor(ensureSeeded)
final ensureSeededProvider = FutureProvider<void>.internal(
  ensureSeeded,
  name: r'ensureSeededProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ensureSeededHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EnsureSeededRef = FutureProviderRef<void>;
String _$homeWalletsHash() => r'b6732bd20d1497ef2b027b5a830f523b88da81d9';

/// All wallets, seeding the preview dataset on first run.
///
/// Copied from [homeWallets].
@ProviderFor(homeWallets)
final homeWalletsProvider = AutoDisposeFutureProvider<List<Wallet>>.internal(
  homeWallets,
  name: r'homeWalletsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeWalletsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeWalletsRef = AutoDisposeFutureProviderRef<List<Wallet>>;
String _$investmentHoldingsHash() =>
    r'09c858af10dce9dbb5f8fb2e6642d42ad776bc79';

/// All investment holdings, seeding the preview dataset on first run.
///
/// Copied from [investmentHoldings].
@ProviderFor(investmentHoldings)
final investmentHoldingsProvider =
    AutoDisposeFutureProvider<List<Holding>>.internal(
      investmentHoldings,
      name: r'investmentHoldingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$investmentHoldingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InvestmentHoldingsRef = AutoDisposeFutureProviderRef<List<Holding>>;
String _$correctedHoldingIdsHash() =>
    r'926aa2d8fc61d8feb7797ff2421d645bf76d9234';

/// Ids of holdings the user has manually corrected (for the 「已修改」 hint).
///
/// Copied from [correctedHoldingIds].
@ProviderFor(correctedHoldingIds)
final correctedHoldingIdsProvider =
    AutoDisposeFutureProvider<Set<String>>.internal(
      correctedHoldingIds,
      name: r'correctedHoldingIdsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$correctedHoldingIdsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CorrectedHoldingIdsRef = AutoDisposeFutureProviderRef<Set<String>>;
String _$homeAccountsHash() => r'de630a623aa5912e9b35470340be04a8e710f49d';

/// All accounts with wallets eagerly attached, seeding on first run.
///
/// Copied from [homeAccounts].
@ProviderFor(homeAccounts)
final homeAccountsProvider = AutoDisposeFutureProvider<List<Account>>.internal(
  homeAccounts,
  name: r'homeAccountsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeAccountsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeAccountsRef = AutoDisposeFutureProviderRef<List<Account>>;
String _$monthlyInvestableHash() => r'a25202e0b0533aca80ccdab598ead66144cb200e';

/// 本月可動用(可理財金額,單位:分)= 收入 − 固定支出 − 繳費。
///
/// 簡化版:**不扣「已分配」**(那需要 payday 分配-commit 迴圈,另案處理)。
///
/// Copied from [monthlyInvestable].
@ProviderFor(monthlyInvestable)
final monthlyInvestableProvider = AutoDisposeFutureProvider<int>.internal(
  monthlyInvestable,
  name: r'monthlyInvestableProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$monthlyInvestableHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MonthlyInvestableRef = AutoDisposeFutureProviderRef<int>;
String _$investableBreakdownHash() =>
    r'82e811205842280dcad4b1c9f307600dabd99742';

/// 可動用的組成(收入 / 生活費 / 貸款·繳費),供本月分配頁顯示算式。
///
/// Copied from [investableBreakdown].
@ProviderFor(investableBreakdown)
final investableBreakdownProvider =
    AutoDisposeFutureProvider<({int income, int living, int loans})>.internal(
      investableBreakdown,
      name: r'investableBreakdownProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$investableBreakdownHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InvestableBreakdownRef =
    AutoDisposeFutureProviderRef<({int income, int living, int loans})>;
String _$loansHash() => r'9cfa2d693136c23c63c733d1de30a6950f2f278a';

/// All loans / recurring payments (for the 貸款/繳費 management screen).
///
/// Copied from [loans].
@ProviderFor(loans)
final loansProvider = AutoDisposeFutureProvider<List<Loan>>.internal(
  loans,
  name: r'loansProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$loansHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LoansRef = AutoDisposeFutureProviderRef<List<Loan>>;
String _$walletTransactionsHash() =>
    r'aea8c8974573636e267d84b6899108d21ddbe6e8';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Transactions for a wallet/holding [ref], newest first.
///
/// Copied from [walletTransactions].
@ProviderFor(walletTransactions)
const walletTransactionsProvider = WalletTransactionsFamily();

/// Transactions for a wallet/holding [ref], newest first.
///
/// Copied from [walletTransactions].
class WalletTransactionsFamily extends Family<AsyncValue<List<Transaction>>> {
  /// Transactions for a wallet/holding [ref], newest first.
  ///
  /// Copied from [walletTransactions].
  const WalletTransactionsFamily();

  /// Transactions for a wallet/holding [ref], newest first.
  ///
  /// Copied from [walletTransactions].
  WalletTransactionsProvider call(String refId) {
    return WalletTransactionsProvider(refId);
  }

  @override
  WalletTransactionsProvider getProviderOverride(
    covariant WalletTransactionsProvider provider,
  ) {
    return call(provider.refId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'walletTransactionsProvider';
}

/// Transactions for a wallet/holding [ref], newest first.
///
/// Copied from [walletTransactions].
class WalletTransactionsProvider
    extends AutoDisposeFutureProvider<List<Transaction>> {
  /// Transactions for a wallet/holding [ref], newest first.
  ///
  /// Copied from [walletTransactions].
  WalletTransactionsProvider(String refId)
    : this._internal(
        (ref) => walletTransactions(ref as WalletTransactionsRef, refId),
        from: walletTransactionsProvider,
        name: r'walletTransactionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$walletTransactionsHash,
        dependencies: WalletTransactionsFamily._dependencies,
        allTransitiveDependencies:
            WalletTransactionsFamily._allTransitiveDependencies,
        refId: refId,
      );

  WalletTransactionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.refId,
  }) : super.internal();

  final String refId;

  @override
  Override overrideWith(
    FutureOr<List<Transaction>> Function(WalletTransactionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WalletTransactionsProvider._internal(
        (ref) => create(ref as WalletTransactionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        refId: refId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Transaction>> createElement() {
    return _WalletTransactionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WalletTransactionsProvider && other.refId == refId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, refId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WalletTransactionsRef on AutoDisposeFutureProviderRef<List<Transaction>> {
  /// The parameter `refId` of this provider.
  String get refId;
}

class _WalletTransactionsProviderElement
    extends AutoDisposeFutureProviderElement<List<Transaction>>
    with WalletTransactionsRef {
  _WalletTransactionsProviderElement(super.provider);

  @override
  String get refId => (origin as WalletTransactionsProvider).refId;
}

String _$recentTransactionsHash() =>
    r'5b097484967a35f166ae69cbbaa714f52b7edec0';

/// Recent transactions across all wallets/holdings (newest first).
///
/// Copied from [recentTransactions].
@ProviderFor(recentTransactions)
final recentTransactionsProvider =
    AutoDisposeFutureProvider<List<Transaction>>.internal(
      recentTransactions,
      name: r'recentTransactionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recentTransactionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentTransactionsRef = AutoDisposeFutureProviderRef<List<Transaction>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
