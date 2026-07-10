/// Routes a holding to the right price source by its kind.
library;

import 'package:wealthlens/data/price/price_service.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/holding.dart';

/// Routes by [HoldingKind]: ETF → Yahoo, crypto → Binance (converted to TWD
/// via the live USD/TWD rate, falling back to a fixed rate), forex → Yahoo FX,
/// manual kinds (fund/gold/savings/timeDeposit) → an empty quote.
class CompositePriceService implements PriceService {
  /// Creates a [CompositePriceService].
  CompositePriceService({
    required this.yahoo,
    required this.binance,
    required this.fx,
    this.fallbackUsdTwd = 32.0,
  });

  /// TW stock / ETF source.
  final PriceService yahoo;

  /// Crypto source (prices in USDT).
  final PriceService binance;

  /// FX source (TWD per unit).
  final PriceService fx;

  /// USD/TWD rate used when the live FX fetch fails.
  final double fallbackUsdTwd;

  static const _usdProbe = Holding(
    id: '_usd',
    accountRef: '_',
    kind: HoldingKind.forex,
    symbol: 'USD',
    quantity: 1,
    avgCost: 0,
    lastPrice: 0,
    isCapitalGuaranteed: false,
    liquidity: 'high',
  );

  @override
  Future<PriceQuote> fetch(Holding holding) async {
    switch (holding.kind) {
      case HoldingKind.etf:
        return yahoo.fetch(holding);
      case HoldingKind.forex:
        return fx.fetch(holding);
      case HoldingKind.crypto:
        final usdt = await binance.fetch(holding);
        if (usdt.error != null || usdt.price == null) return usdt;
        final usd = await fx.fetch(_usdProbe);
        final rate = usd.price ?? fallbackUsdTwd;
        return PriceQuote(
          price: usdt.price! * rate,
          source: 'Binance',
          fetchedAt: usdt.fetchedAt,
        );
      case HoldingKind.fund:
      case HoldingKind.gold:
      case HoldingKind.savings:
      case HoldingKind.timeDeposit:
        // Manual kinds — no live price.
        return const PriceQuote();
    }
  }
}
