/// Amount-anchoring setting (完整 / 千 / 萬), persisted to secure storage.
library;

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wealthlens/app/format.dart';

part 'anchor_unit_controller.g.dart';

/// Holds the user-selected [AnchorUnit] for amount display.
///
/// Defaults to [AnchorUnit.full] (no anchoring). The active value is mirrored
/// into [defaultAnchorUnit] so plain `formatTwd` calls reflect the setting.
@Riverpod(keepAlive: true)
class AnchorUnitController extends _$AnchorUnitController {
  static const _key = 'anchor_unit';
  static const _storage = FlutterSecureStorage();

  @override
  AnchorUnit build() {
    unawaited(_hydrate());
    defaultAnchorUnit = AnchorUnit.full;
    return AnchorUnit.full;
  }

  Future<void> _hydrate() async {
    final stored = await _storage.read(key: _key);
    final unit = AnchorUnit.values.asNameMap()[stored];
    if (unit != null) {
      defaultAnchorUnit = unit;
      state = unit;
    }
  }

  /// Sets and persists [unit], updating the global display default.
  Future<void> set(AnchorUnit unit) async {
    defaultAnchorUnit = unit;
    state = unit;
    await _storage.write(key: _key, value: unit.name);
  }
}
