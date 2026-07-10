/// Home layout preference for 保障與目標 / 本月任務: cards vs progress list.
library;

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_layout_controller.g.dart';

/// How the home's goal & task sections are presented.
enum HomeLayout {
  /// 資訊卡 — compact cards (horizontal goal chips), the default.
  cards,

  /// 列表 — vertical rows with progress bars.
  list,
}

/// Holds and persists the home layout preference.
@Riverpod(keepAlive: true)
class HomeLayoutController extends _$HomeLayoutController {
  static const _key = 'home_layout';
  static const _storage = FlutterSecureStorage();

  @override
  HomeLayout build() {
    unawaited(_hydrate());
    return HomeLayout.cards;
  }

  Future<void> _hydrate() async {
    final stored = await _storage.read(key: _key);
    final layout = HomeLayout.values.asNameMap()[stored];
    if (layout != null) state = layout;
  }

  /// Sets and persists [layout].
  Future<void> set(HomeLayout layout) async {
    state = layout;
    await _storage.write(key: _key, value: layout.name);
  }
}
