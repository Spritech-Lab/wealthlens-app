/// Typography tokens.
///
/// Numbers always use tabular figures so amounts and percentages align without
/// jitter. Platform fonts are left to the system default
/// (SF Pro / PingFang on iOS, Roboto / Noto Sans on Android).
library;

import 'package:flutter/material.dart';

/// Builds the app [TextTheme] for a light/dark text color.
abstract final class AppTypography {
  /// Tabular-figures feature applied to numeric styles.
  static const tabularFigures = [FontFeature.tabularFigures()];

  /// Returns a [TextTheme] tinted for [primary] text color.
  static TextTheme textTheme(Color primary) {
    final t = ThemeData.light().textTheme.apply(
          bodyColor: primary,
          displayColor: primary,
        );
    return t.copyWith(
      // Amount-bearing styles get tabular figures.
      displayMedium: t.displayMedium?.copyWith(fontFeatures: tabularFigures),
      headlineMedium: t.headlineMedium?.copyWith(fontFeatures: tabularFigures),
      titleLarge: t.titleLarge?.copyWith(fontFeatures: tabularFigures),
    );
  }

  /// A style for prominent monetary figures.
  static TextStyle amount(Color color) => TextStyle(
        color: color,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        fontFeatures: tabularFigures,
      );
}
