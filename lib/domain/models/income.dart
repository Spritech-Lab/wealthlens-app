/// Income domain model — pure Dart, no Flutter imports.
library;

import 'package:meta/meta.dart';
import 'package:wealthlens/domain/models/enums.dart';

/// Represents a single income source (salary, freelance, etc.).
@immutable
class Income {
  /// Creates an immutable [Income].
  const Income({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    this.payday,
    this.quickEntryOnHome = false,
  });

  /// Unique identifier.
  final String id;

  /// User-visible income source name.
  final String name;

  /// Monthly income amount in integer cents (分).
  final int amount;

  /// Fixed or variable income type.
  final IncomeType type;

  /// Day of month on which income is received (1–31). Nullable.
  final int? payday;

  /// Whether a quick-entry button appears on the home screen.
  ///
  /// Default `false` — off by default for main users.
  /// Only enabled by users who opt in for dynamic/variable income flows.
  final bool quickEntryOnHome;

  // ── Immutable helpers ────────────────────────────────────────────────────

  /// Returns a copy of this income with the given fields replaced.
  Income copyWith({
    String? id,
    String? name,
    int? amount,
    IncomeType? type,
    Object? payday = _sentinel,
    bool? quickEntryOnHome,
  }) {
    return Income(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      payday: payday == _sentinel ? this.payday : payday as int?,
      quickEntryOnHome: quickEntryOnHome ?? this.quickEntryOnHome,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Income &&
        other.id == id &&
        other.name == name &&
        other.amount == amount &&
        other.type == type &&
        other.payday == payday &&
        other.quickEntryOnHome == quickEntryOnHome;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, amount, type, payday, quickEntryOnHome);
}

// Sentinel value for nullable copyWith parameters.
const Object _sentinel = Object();
