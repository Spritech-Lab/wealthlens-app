/// Crypto prices via Binance public API — 5 whitelisted coins only.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wealthlens/data/price/price_service.dart';
import 'package:wealthlens/domain/models/holding.dart';

/// Fetches crypto prices (in USDT) from Binance. Only the 5 whitelisted coins
/// are supported; anything else returns `unsupported`.
class BinanceCryptoPriceService implements PriceService {
  /// Creates a [BinanceCryptoPriceService] over [_client].
  BinanceCryptoPriceService(this._client);

  final http.Client _client;

  /// Supported coins. Others return `unsupported`.
  static const whitelist = {'BTC', 'ETH', 'USDT', 'BNB', 'SOL'};

  @override
  Future<PriceQuote> fetch(Holding holding) async {
    final coin = holding.symbol.toUpperCase();
    if (!whitelist.contains(coin)) {
      return const PriceQuote(error: 'unsupported');
    }
    // USDT is the quote currency — price is 1.0, no API call.
    if (coin == 'USDT') return const PriceQuote(price: 1, source: 'Binance');

    final url = Uri.parse(
      'https://api.binance.com/api/v3/ticker/price?symbol=${coin}USDT',
    );
    try {
      final res = await _client.get(url);
      if (res.statusCode != 200) {
        return PriceQuote(error: 'http ${res.statusCode}');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final price = double.parse(body['price'] as String);
      return PriceQuote(price: price, source: 'Binance');
    } on Object catch (e) {
      return PriceQuote(error: e.toString());
    }
  }
}
