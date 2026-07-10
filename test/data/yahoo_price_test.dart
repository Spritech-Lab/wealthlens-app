// YahooStockPriceService — parse, http error, network fail (no throw).
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:wealthlens/data/price/yahoo_stock_price_service.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/holding.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  setUpAll(() => registerFallbackValue(Uri()));

  late _MockClient client;
  late YahooStockPriceService svc;
  setUp(() {
    client = _MockClient();
    svc = YahooStockPriceService(client);
  });

  Holding stock(String sym) => Holding(
        id: 'h',
        accountRef: 'a',
        kind: HoldingKind.etf,
        symbol: sym,
        quantity: 1,
        avgCost: 0,
        lastPrice: 0,
        isCapitalGuaranteed: false,
        liquidity: 'high',
      );

  test('parses regularMarketPrice + time, queries <symbol>.TW', () async {
    when(() => client.get(any())).thenAnswer(
      (_) async => http.Response(
        '{"chart":{"result":[{"meta":{"regularMarketPrice":155.5,'
        '"regularMarketTime":1719200000}}]}}',
        200,
      ),
    );
    final q = await svc.fetch(stock('0050'));
    expect(q.error, isNull);
    expect(q.price, 155.5);
    expect(q.source, 'Yahoo Finance');
    final captured = verify(() => client.get(captureAny())).captured.single;
    expect((captured as Uri).toString(), contains('0050.TW'));
  });

  test('non-200 returns http error, no throw', () async {
    when(() => client.get(any()))
        .thenAnswer((_) async => http.Response('nope', 404));
    final q = await svc.fetch(stock('0050'));
    expect(q.error, 'http 404');
    expect(q.price, isNull);
  });

  test('network failure returns error, no throw', () async {
    when(() => client.get(any())).thenThrow(Exception('network'));
    final q = await svc.fetch(stock('0050'));
    expect(q.error, isNotNull);
    expect(q.price, isNull);
  });
}
