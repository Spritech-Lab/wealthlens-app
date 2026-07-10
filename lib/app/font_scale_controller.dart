/// App-wide font-size preference (default text scale), persisted.
library;

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'font_scale_controller.g.dart';

/// User-selectable default font size, applied as a global text scaler.
enum FontScale {
  /// 1.0× — 小(舊基準,精簡).
  small,

  /// 1.15× — 標準(預設,較舒適的基準).
  standard,

  /// 1.3× — 大.
  large,

  /// 1.45× — 特大.
  xlarge;

  /// The linear text-scale factor. The baseline was lifted (標準 = 1.15) so the
  /// default is comfortably readable; 小 keeps the old compact size.
  double get factor => switch (this) {
        FontScale.small => 1,
        FontScale.standard => 1.15,
        FontScale.large => 1.3,
        FontScale.xlarge => 1.45,
      };
}

/// Holds and persists the app's default font scale.
@Riverpod(keepAlive: true)
class FontScaleController extends _$FontScaleController {
  static const _key = 'font_scale';
  static const _storage = FlutterSecureStorage();

  @override
  FontScale build() {
    unawaited(_hydrate());
    return FontScale.standard;
  }

  Future<void> _hydrate() async {
    final stored = await _storage.read(key: _key);
    final scale = FontScale.values.asNameMap()[stored];
    if (scale != null) state = scale;
  }

  /// Sets and persists [scale].
  Future<void> set(FontScale scale) async {
    state = scale;
    await _storage.write(key: _key, value: scale.name);
  }
}
