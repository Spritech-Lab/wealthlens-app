// FxRateService — parse, whitelist, no-throw.
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:wealthlens/data/price/fx_rate_service.dart';
import 'package:wealthlens/domain/models/enums.dart';
import 'package:wealthlens/domain/models/holding.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  setUpAll(() => registerFallbackValue(Uri()));

  late _MockClient client;
  late FxRateService svc;
  setUp(() {
    client = _MockClient();
    svc = FxRateService(client);
  });

  Holding fx(String sym) => Holding(
        id: 'h',
        accountRef: 'a',
        kind: HoldingKind.forex,
        symbol: sym,
        quantity: 1,
        avgCost: 0,
        lastPrice: 0,
        isCapitalGuaranteed: false,
        liquidity: 'high',
      );

  test('parses USDTWD=X rate', () async {
    when(() => client.get(any())).thenAnswer(
      (_) async => http.Response(
        '{"chart":{"result":[{"meta":{"regularMarketPrice":32.15,'
        '"regularMarketTime":1719200000}}]}}',
        200,
      ),
    );
    final q = await svc.fetch(fx('USD'));
    expect(q.error, isNull);
    expect(q.price, 32.15);
    expect(q.source, 'Yahoo Finance');
    final url = verify(() => client.get(captureAny())).captured.single as Uri;
    expect(url.toString(), contains('USDTWD=X'));
  });

  test('non-whitelist currency returns unsupported, no API call', () async {
    final q = await svc.fetch(fx('THB'));
    expect(q.error, 'unsupported');
    verifyNever(() => client.get(any()));
  });

  test('network failure returns error, no throw', () async {
    when(() => client.get(any())).thenThrow(Exception('network'));
    final q = await svc.fetch(fx('JPY'));
    expect(q.error, isNotNull);
    expect(q.price, isNull);
  });
}
