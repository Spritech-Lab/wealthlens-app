/// App theme assembly — light and dark [ThemeData] from the design tokens.
library;

import 'package:flutter/material.dart';
import 'package:wealthlens/design_system/tokens/colors.dart';
import 'package:wealthlens/design_system/tokens/typography.dart';

/// Builds the light and dark themes used by the app.
abstract final class AppTheme {
  /// Light theme.
  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: AppPalette.lightBackground,
        surface: AppPalette.lightSurface,
        textPrimary: AppPalette.lightTextPrimary,
        primary: AppPalette.lightInfo,
        semantic: SemanticColors.light(),
      );

  /// Dark theme.
  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: AppPalette.darkBackground,
        surface: AppPalette.darkSurface,
        textPrimary: AppPalette.darkTextPrimary,
        primary: AppPalette.darkInfo,
        semantic: SemanticColors.dark(),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color primary,
    required SemanticColors semantic,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      surface: surface,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: AppTypography.textTheme(textPrimary),
      extensions: [semantic],
    );
  }
}

/// Convenience access to the [SemanticColors] on the active theme.
extension SemanticColorsContext on BuildContext {
  /// The active semantic colors (success / warning / info / ...).
  SemanticColors get semantic =>
      Theme.of(this).extension<SemanticColors>() ?? SemanticColors.light();
}
