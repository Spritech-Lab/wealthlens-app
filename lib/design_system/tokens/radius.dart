/// Corner radius scale.
library;

import 'package:flutter/widgets.dart';

/// Corner radii for cards, chips and sheets.
abstract final class AppRadius {
  /// 8
  static const sm = 8.0;

  /// 12
  static const md = 12.0;

  /// 16
  static const lg = 16.0;

  /// 24
  static const xl = 24.0;

  /// Pill / fully rounded.
  static const pill = 999.0;

  /// [BorderRadius] for medium cards.
  static const cardMd = BorderRadius.all(Radius.circular(md));

  /// [BorderRadius] for large hero cards.
  static const cardLg = BorderRadius.all(Radius.circular(lg));
}
