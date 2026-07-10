/// FixedCost domain model — pure Dart, no Flutter imports.
library;

import 'package:meta/meta.dart';

/// Living expenses recorded as a single monthly lump sum.
///
/// WealthLens is not a bookkeeping app — living costs are captured as one
/// aggregate number, not itemized. This keeps the home screen focused on
/// goals rather than expense tracking.
@immutable
class FixedCost {
  /// Creates an immutable [FixedCost].
  const FixedCost({required this.livingExpense});

  /// Monthly living expense in integer cents (分).
  final int livingExpense;

  // ── Immutable helpers ────────────────────────────────────────────────────

  /// Returns a copy with [livingExpense] replaced.
  FixedCost copyWith({int? livingExpense}) {
    return FixedCost(livingExpense: livingExpense ?? this.livingExpense);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FixedCost && other.livingExpense == livingExpense;
  }

  @override
  int get hashCode => livingExpense.hashCode;
}
