/// Whether to show P&L (盈虧) figures across the app, persisted.
///
/// A mood/privacy switch: some users prefer not to see gains/losses when the
/// market is down. Default on.
library;

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'show_pnl_controller.g.dart';

/// Holds and persists the "show P&L" preference.
@Riverpod(keepAlive: true)
class ShowPnlController extends _$ShowPnlController {
  static const _key = 'show_pnl';
  static const _storage = FlutterSecureStorage();

  @override
  bool build() {
    unawaited(_hydrate());
    return true;
  }

  Future<void> _hydrate() async {
    final stored = await _storage.read(key: _key);
    if (stored == 'false') state = false;
  }

  /// Sets and persists whether P&L figures are shown.
  Future<void> set({required bool show}) async {
    state = show;
    await _storage.write(key: _key, value: show.toString());
  }
}
