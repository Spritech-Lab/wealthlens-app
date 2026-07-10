/// Color tokens — dual light/dark palette.
///
/// Semantic and category colors that don't belong in [ColorScheme] are exposed
/// via the [SemanticColors] theme extension so widgets read them from the
/// active theme rather than hard-coding hex values.
library;

import 'package:flutter/material.dart';

/// Raw palette constants. Prefer reading colors via [SemanticColors] / the
/// active [ColorScheme]; use these only when assembling themes.
abstract final class AppPalette {
  // ── Light ──
  /// Light background.
  static const lightBackground = Color(0xFFFAFAF7);

  /// Light surface / card.
  static const lightSurface = Color(0xFFFFFFFF);

  /// Light primary text.
  static const lightTextPrimary = Color(0xFF1A1A18);

  /// Light secondary text.
  static const lightTextSecondary = Color(0xFF8A887E);

  /// Light success green.
  static const lightSuccess = Color(0xFF1D9E75);

  /// Light warning amber.
  static const lightWarning = Color(0xFF9A6410);

  /// Light info blue.
  static const lightInfo = Color(0xFF185FA5);

  // ── Dark (not inverted; tuned for dark surfaces) ──
  /// Dark background.
  static const darkBackground = Color(0xFF1A1A1C);

  /// Dark surface / card.
  static const darkSurface = Color(0xFF26262A);

  /// Dark primary text.
  static const darkTextPrimary = Color(0xFFEAEAEA);

  /// Dark secondary text.
  static const darkTextSecondary = Color(0xFF8E8C86);

  /// Dark success green.
  static const darkSuccess = Color(0xFF3DBA8E);

  /// Dark warning amber.
  static const darkWarning = Color(0xFFC9914A);

  /// Dark info blue.
  static const darkInfo = Color(0xFF5B9BD8);

  // ── Category colors (shared across light/dark) ──
  /// Mortgage purple.
  static const loanMortgage = Color(0xFF5B4FB5);

  /// Car-loan blue.
  static const loanCar = Color(0xFF2E6FA8);

  /// Personal-loan orange.
  static const loanPersonal = Color(0xFFB5701F);

  /// Student-loan green.
  static const loanStudent = Color(0xFF1D8A63);

  /// Card-revolving red.
  static const loanCardRevolving = Color(0xFFB23A3A);

  /// ETF green.
  static const etf = Color(0xFF0F6E56);

  /// Fund teal.
  static const fund = Color(0xFF0E8A8A);

  /// Crypto orange.
  static const crypto = Color(0xFFC2761A);

  /// Gold.
  static const gold = Color(0xFFA8841E);

  /// Forex teal-blue.
  static const forex = Color(0xFF1C7C9C);

  /// Overlay / temporary layer light blue.
  static const overlayTemp = Color(0xFF9FC8EF);
}

/// Semantic + category colors carried on the active theme.
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  /// Creates a [SemanticColors].
  const SemanticColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.textSecondary,
    required this.overlayTemp,
  });

  /// Light variant.
  factory SemanticColors.light() => const SemanticColors(
        success: AppPalette.lightSuccess,
        warning: AppPalette.lightWarning,
        info: AppPalette.lightInfo,
        textSecondary: AppPalette.lightTextSecondary,
        overlayTemp: AppPalette.overlayTemp,
      );

  /// Dark variant.
  factory SemanticColors.dark() => const SemanticColors(
        success: AppPalette.darkSuccess,
        warning: AppPalette.darkWarning,
        info: AppPalette.darkInfo,
        textSecondary: AppPalette.darkTextSecondary,
        overlayTemp: AppPalette.overlayTemp,
      );

  /// Positive / on-track.
  final Color success;

  /// Caution / below target.
  final Color warning;

  /// Informational.
  final Color info;

  /// Secondary text.
  final Color textSecondary;

  /// Overlay / temporary layer.
  final Color overlayTemp;

  @override
  SemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? textSecondary,
    Color? overlayTemp,
  }) =>
      SemanticColors(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        info: info ?? this.info,
        textSecondary: textSecondary ?? this.textSecondary,
        overlayTemp: overlayTemp ?? this.overlayTemp,
      );

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      overlayTemp: Color.lerp(overlayTemp, other.overlayTemp, t)!,
    );
  }
}
