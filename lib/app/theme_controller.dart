/// Theme-mode state, persisted to secure storage.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_controller.g.dart';

/// Holds the active [ThemeMode], following the system by default and
/// persisting any manual override.
@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  static const _key = 'theme_mode';
  static const _storage = FlutterSecureStorage();

  @override
  ThemeMode build() {
    unawaited(_hydrate());
    return ThemeMode.system;
  }

  Future<void> _hydrate() async {
    final stored = await _storage.read(key: _key);
    final mode = ThemeMode.values.asNameMap()[stored];
    if (mode != null) state = mode;
  }

  /// Sets and persists [mode].
  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _storage.write(key: _key, value: mode.name);
  }

  /// Cycles light → dark → light (system collapses to light first).
  Future<void> toggle() =>
      set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
