/// Taiwan-stock prices via Yahoo Finance (client-side, no proxy).
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wealthlens/data/price/price_service.dart';
import 'package:wealthlens/domain/models/holding.dart';

/// Fetches TW stock / ETF prices from Yahoo Finance's chart endpoint.
class YahooStockPriceService implements PriceService {
  /// Creates a [YahooStockPriceService] over [_client].
  YahooStockPriceService(this._client);

  final http.Client _client;

  @override
  Future<PriceQuote> fetch(Holding holding) async {
    final url = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/'
      '${holding.symbol}.TW',
    );
    try {
      final res = await _client.get(url);
      if (res.statusCode != 200) {
        return PriceQuote(error: 'http ${res.statusCode}');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final chart = body['chart'] as Map<String, dynamic>;
      final result = (chart['result'] as List).first as Map<String, dynamic>;
      final meta = result['meta'] as Map<String, dynamic>;
      final price = (meta['regularMarketPrice'] as num).toDouble();
      final t = (meta['regularMarketTime'] as num).toInt();
      return PriceQuote(
        price: price,
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(t * 1000),
        source: 'Yahoo Finance',
      );
    } on Object catch (e) {
      return PriceQuote(error: e.toString());
    }
  }
}
