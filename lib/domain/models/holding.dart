/// Holding domain model — pure Dart, no Flutter imports.
library;

import 'package:meta/meta.dart';
import 'package:wealthlens/domain/models/enums.dart';

/// A financial holding — a position in any investable instrument.
///
/// Covers ETF, crypto, gold, time-deposits, forex, etc.
///
/// **Forex semantics** (`kind == HoldingKind.forex`):
/// - [symbol] = currency code (USD / JPY / EUR / CNY — whitelist only).
/// - [quantity] = amount in the foreign currency.
/// - [avgCost] = average buy rate in TWD per unit of foreign currency
///   (maintained by `CostBasisCalculator`).
/// - [lastPrice] = current exchange rate in TWD per unit of foreign currency.
/// - [unrealizedPnL] negative when [lastPrice] < [avgCost] (exchange loss).
@immutable
class Holding {
  /// Creates an immutable [Holding].
  const Holding({
    required this.id,
    required this.accountRef,
    required this.kind,
    required this.symbol,
    required this.quantity,
    required this.avgCost,
    required this.lastPrice,
    required this.isCapitalGuaranteed,
    required this.liquidity,
    this.lastPriceAt,
  });

  /// Unique identifier.
  final String id;

  /// The account this holding belongs to.
  final String accountRef;

  /// Kind of instrument.
  final HoldingKind kind;

  /// Ticker / currency code / symbol string.
  final String symbol;

  /// Number of units held (shares / coins / foreign-currency amount).
  final double quantity;

  /// Average cost per unit in TWD.
  ///
  /// For forex: average buy rate (TWD / foreign currency unit).
  /// Maintained by `CostBasisCalculator` — not stored from user input directly.
  final double avgCost;

  /// Latest known price per unit in TWD.
  ///
  /// For forex: current exchange rate (TWD / foreign currency unit).
  final double lastPrice;

  /// Timestamp of the last successful price fetch.
  ///
  /// `null` for manual-price categories (fund, gold, savings, timeDeposit).
  final DateTime? lastPriceAt;

  /// Whether the principal is guaranteed (e.g. bank deposit insurance).
  final bool isCapitalGuaranteed;

  /// Liquidity description (e.g. "high", "low", "medium").
  final String liquidity;

  // ── Derived values (getters, never stored) ──────────────────────────────

  /// Current market value in TWD = `quantity × lastPrice`.
  double get currentValue => quantity * lastPrice;

  /// Unrealized P&L in TWD = `quantity × (lastPrice − avgCost)`.
  ///
  /// Negative when [lastPrice] < [avgCost]
  /// (e.g. forex exchange-rate loss — 浮虧).
  double get unrealizedPnL => quantity * (lastPrice - avgCost);

  // ── Immutable helpers ────────────────────────────────────────────────────

  /// Returns a copy of this holding with the given fields replaced.
  Holding copyWith({
    String? id,
    String? accountRef,
    HoldingKind? kind,
    String? symbol,
    double? quantity,
    double? avgCost,
    double? lastPrice,
    bool? isCapitalGuaranteed,
    String? liquidity,
    Object? lastPriceAt = _sentinel,
  }) {
    return Holding(
      id: id ?? this.id,
      accountRef: accountRef ?? this.accountRef,
      kind: kind ?? this.kind,
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      avgCost: avgCost ?? this.avgCost,
      lastPrice: lastPrice ?? this.lastPrice,
      isCapitalGuaranteed: isCapitalGuaranteed ?? this.isCapitalGuaranteed,
      liquidity: liquidity ?? this.liquidity,
      lastPriceAt: lastPriceAt == _sentinel
          ? this.lastPriceAt
          : lastPriceAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Holding &&
        other.id == id &&
        other.accountRef == accountRef &&
        other.kind == kind &&
        other.symbol == symbol &&
        other.quantity == quantity &&
        other.avgCost == avgCost &&
        other.lastPrice == lastPrice &&
        other.lastPriceAt == lastPriceAt &&
        other.isCapitalGuaranteed == isCapitalGuaranteed &&
        other.liquidity == liquidity;
  }

  @override
  int get hashCode => Object.hash(
        id,
        accountRef,
        kind,
        symbol,
        quantity,
        avgCost,
        lastPrice,
        lastPriceAt,
        isCapitalGuaranteed,
        liquidity,
      );
}

// Sentinel value for nullable copyWith parameters.
const Object _sentinel = Object();
