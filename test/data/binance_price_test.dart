// BinanceCryptoPriceService — whitelist, USDT=1, parse, no-throw.
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:wealthlens/data/price/binance_crypto_price_service.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/holding.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  setUpAll(() => registerFallbackValue(Uri()));

  late _MockClient client;
  late BinanceCryptoPriceService svc;
  setUp(() {
    client = _MockClient();
    svc = BinanceCryptoPriceService(client);
  });

  Holding coin(String sym) => Holding(
        id: 'h',
        accountRef: 'a',
        kind: HoldingKind.crypto,
        symbol: sym,
        quantity: 1,
        avgCost: 0,
        lastPrice: 0,
        isCapitalGuaranteed: false,
        liquidity: 'high',
      );

  test('parses ticker price, queries <COIN>USDT', () async {
    when(() => client.get(any())).thenAnswer(
      (_) async =>
          http.Response('{"symbol":"BTCUSDT","price":"95000.50"}', 200),
    );
    final q = await svc.fetch(coin('BTC'));
    expect(q.error, isNull);
    expect(q.price, 95000.50);
    expect(q.source, 'Binance');
    final url = verify(() => client.get(captureAny())).captured.single as Uri;
    expect(url.toString(), contains('BTCUSDT'));
  });

  test('USDT is 1.0 without an API call', () async {
    final q = await svc.fetch(coin('USDT'));
    expect(q.price, 1.0);
    verifyNever(() => client.get(any()));
  });

  test('non-whitelist coin returns unsupported, no API call', () async {
    final q = await svc.fetch(coin('DOGE'));
    expect(q.error, 'unsupported');
    verifyNever(() => client.get(any()));
  });

  test('network failure returns error, no throw', () async {
    when(() => client.get(any())).thenThrow(Exception('network'));
    final q = await svc.fetch(coin('ETH'));
    expect(q.error, isNotNull);
    expect(q.price, isNull);
  });
}
