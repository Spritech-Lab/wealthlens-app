/// HomeAlerts domain model — pure Dart, no Flutter imports.
library;

import 'package:meta/meta.dart';

/// Toggle switches for home-screen alert cards.
///
/// Alerts are app-internal only — WealthLens never sends system push
/// notifications. Each alert type can be independently toggled in Settings.
@immutable
class HomeAlerts {
  /// Creates an immutable [HomeAlerts].
  ///
  /// Defaults match the spec: `lowLevel = false`, `payday = true`,
  /// `goalDueSoon = true`.
  const HomeAlerts({
    this.lowLevel = false,
    this.payday = true,
    this.goalDueSoon = true,
  });

  /// Show "balance is running low" warning card. Default off.
  final bool lowLevel;

  /// Show "payday is near" reminder card. Default on.
  final bool payday;

  /// Show "goal deadline is approaching" reminder card. Default on.
  final bool goalDueSoon;

  // ── Immutable helpers ────────────────────────────────────────────────────

  /// Returns a copy of this [HomeAlerts] with the given fields replaced.
  HomeAlerts copyWith({
    bool? lowLevel,
    bool? payday,
    bool? goalDueSoon,
  }) {
    return HomeAlerts(
      lowLevel: lowLevel ?? this.lowLevel,
      payday: payday ?? this.payday,
      goalDueSoon: goalDueSoon ?? this.goalDueSoon,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomeAlerts &&
        other.lowLevel == lowLevel &&
        other.payday == payday &&
        other.goalDueSoon == goalDueSoon;
  }

  @override
  int get hashCode => Object.hash(lowLevel, payday, goalDueSoon);
}
