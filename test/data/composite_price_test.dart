// CompositePriceService — routing + crypto USDT→TWD + fallback + manual null.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wealthlens/data/price/composite_price_service.dart';
import 'package:wealthlens/data/price/price_service.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/holding.dart';

class _MockService extends Mock implements PriceService {}

void main() {
  setUpAll(() => registerFallbackValue(
        const Holding(
          id: 'f',
          accountRef: 'f',
          kind: HoldingKind.etf,
          symbol: 'F',
          quantity: 0,
          avgCost: 0,
          lastPrice: 0,
          isCapitalGuaranteed: false,
          liquidity: 'low',
        ),
      ));

  late _MockService yahoo;
  late _MockService binance;
  late _MockService fx;
  late CompositePriceService svc;
  setUp(() {
    yahoo = _MockService();
    binance = _MockService();
    fx = _MockService();
    svc = CompositePriceService(yahoo: yahoo, binance: binance, fx: fx);
  });

  Holding h(HoldingKind kind, String sym) => Holding(
        id: 'h',
        accountRef: 'a',
        kind: kind,
        symbol: sym,
        quantity: 1,
        avgCost: 0,
        lastPrice: 0,
        isCapitalGuaranteed: false,
        liquidity: 'high',
      );

  test('etf routes to Yahoo', () async {
    when(() => yahoo.fetch(any()))
        .thenAnswer((_) async => const PriceQuote(price: 155, source: 'Y'));
    final q = await svc.fetch(h(HoldingKind.etf, '0050'));
    expect(q.price, 155);
    verify(() => yahoo.fetch(any())).called(1);
    verifyNever(() => binance.fetch(any()));
  });

  test('forex routes to FX', () async {
    when(() => fx.fetch(any()))
        .thenAnswer((_) async => const PriceQuote(price: 32.4, source: 'Y'));
    final q = await svc.fetch(h(HoldingKind.forex, 'USD'));
    expect(q.price, 32.4);
  });

  test('crypto converts USDT price by live USD/TWD rate', () async {
    when(() => binance.fetch(any()))
        .thenAnswer((_) async => const PriceQuote(price: 100, source: 'B'));
    when(() => fx.fetch(any()))
        .thenAnswer((_) async => const PriceQuote(price: 32, source: 'Y'));
    final q = await svc.fetch(h(HoldingKind.crypto, 'BTC'));
    expect(q.price, 3200); // 100 USDT * 32
    expect(q.source, 'Binance');
  });

  test('crypto falls back to fixed rate when FX fails', () async {
    when(() => binance.fetch(any()))
        .thenAnswer((_) async => const PriceQuote(price: 100, source: 'B'));
    when(() => fx.fetch(any()))
        .thenAnswer((_) async => const PriceQuote(error: 'down'));
    final q = await svc.fetch(h(HoldingKind.crypto, 'BTC'));
    expect(q.price, 3200); // 100 * fallback 32.0
  });

  test('manual kinds return an empty quote (no fetch)', () async {
    final q = await svc.fetch(h(HoldingKind.gold, 'GOLD'));
    expect(q.price, isNull);
    expect(q.error, isNull);
    verifyNever(() => yahoo.fetch(any()));
    verifyNever(() => fx.fetch(any()));
  });
}
