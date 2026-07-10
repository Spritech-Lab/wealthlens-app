/// Foreign-exchange rates via Yahoo Finance — 4 whitelisted currencies.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wealthlens/data/price/price_service.dart';
import 'package:wealthlens/domain/models/holding.dart';

/// Fetches TWD exchange rates (TWD per 1 unit of the currency) from Yahoo
/// Finance's `<CCY>TWD=X` chart. Only the 4 whitelisted currencies are
/// supported.
class FxRateService implements PriceService {
  /// Creates an [FxRateService] over [_client].
  FxRateService(this._client);

  final http.Client _client;

  /// Supported currencies. Others return `unsupported`.
  static const fxWhitelist = {'USD', 'JPY', 'EUR', 'CNY'};

  @override
  Future<PriceQuote> fetch(Holding holding) async {
    final ccy = holding.symbol.toUpperCase();
    if (!fxWhitelist.contains(ccy)) {
      return const PriceQuote(error: 'unsupported');
    }
    final url = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/${ccy}TWD=X',
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
