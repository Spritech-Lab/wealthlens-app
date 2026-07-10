/// Animation durations and curves.
library;

import 'package:flutter/animation.dart';

/// Motion timing tokens.
abstract final class AppDurations {
  /// Quick feedback (taps, toggles).
  static const fast = Duration(milliseconds: 200);

  /// Standard transitions.
  static const normal = Duration(milliseconds: 300);

  /// Larger surfaces.
  static const slow = Duration(milliseconds: 400);

  /// Default easing with a small overshoot for restrained bounce.
  static const Curve easeOutBack = Curves.easeOutBack;

  /// Plain ease for non-bouncy transitions.
  static const Curve standard = Curves.easeInOut;
}
