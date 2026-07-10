/// Price-service abstraction — fetches a quote for a holding.
library;

import 'package:wealthlens/domain/models/holding.dart';

/// A fetched price quote. Any field may be null; [error] non-null means the
/// fetch failed (services never throw — failures surface here).
class PriceQuote {
  /// Creates a [PriceQuote].
  const PriceQuote({this.price, this.fetchedAt, this.source, this.error});

  /// Price / rate in the quote's natural unit (null on error / unsupported).
  final double? price;

  /// When the price was observed.
  final DateTime? fetchedAt;

  /// Human-facing source label (e.g. "Yahoo Finance", "Binance").
  final String? source;

  /// Error label when the fetch failed or the symbol is unsupported.
  final String? error;
}

/// Fetches a [PriceQuote] for a [Holding]. Implementations must not throw —
/// network / parse failures return a [PriceQuote] with [PriceQuote.error] set.
///
/// Multiple implementations (Yahoo stocks, Binance crypto, Yahoo FX) plus a
/// routing composite — an interface, not a single function.
// ignore: one_member_abstracts
abstract interface class PriceService {
  /// Fetches the latest quote for [holding].
  Future<PriceQuote> fetch(Holding holding);
}
