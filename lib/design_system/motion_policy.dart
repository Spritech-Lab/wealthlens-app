/// Centralized reduce-motion policy.
///
/// Every animated widget routes through this so the app honors iOS Reduce
/// Motion / Android "remove animations" (MediaQuery.disableAnimations) in one
/// place.
library;

import 'package:flutter/material.dart';
import 'package:wealthlens/design_system/tokens/durations.dart';

/// Helpers for respecting the platform's reduce-motion setting.
abstract final class MotionPolicy {
  /// Whether animations should be suppressed for [context].
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Returns [duration], or [Duration.zero] when motion is reduced.
  static Duration duration(BuildContext context, Duration duration) =>
      reduceMotion(context) ? Duration.zero : duration;

  /// Standard animated-container duration honoring reduce-motion.
  static Duration normal(BuildContext context) =>
      duration(context, AppDurations.normal);

  /// Fast feedback duration honoring reduce-motion.
  static Duration fast(BuildContext context) =>
      duration(context, AppDurations.fast);
}
